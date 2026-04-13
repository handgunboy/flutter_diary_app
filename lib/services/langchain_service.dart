import 'dart:convert';
import 'dart:developer' as developer;
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'theme_service.dart';
import 'storage_service.dart';
import 'persistent_vector_store.dart';
import '../models/diary_entry.dart';

/// LangChain 服务 - 提供增强的 AI 功能
/// 
/// 功能：
/// 1. 对话记忆 - 维护长期对话上下文
/// 2. RAG 检索 - 基于日记内容的语义搜索
/// 3. 智能分析 - 自动分析日记趋势和洞察
class LangChainService {
  static final LangChainService _instance = LangChainService._internal();
  factory LangChainService() => _instance;
  LangChainService._internal();

  final ThemeService _themeService = ThemeService();
  final StorageService _storageService = StorageService();

  // LLM 实例
  ChatOpenAI? _llm;
  
  // 对话记忆存储（按会话 ID）
  final Map<String, ConversationBufferMemory> _memories = {};
  
  // 向量存储（用于 RAG）
  PersistentVectorStore? _vectorStore;
  
  // 最后更新的日记日期（用于增量更新向量库）
  DateTime? _lastVectorUpdate;

  /// 初始化或重新初始化 LLM
  void _initLLM() {
    if (!_themeService.hasAiConfig) {
      _llm = null;
      return;
    }

    final apiKey = _themeService.aiApiKey;
    final baseUrl = _themeService.aiApiUrl;
    
    // 检测是否为 DeepSeek
    final isDeepSeek = baseUrl.contains('deepseek');
    final modelName = isDeepSeek ? 'deepseek-chat' : 'gpt-3.5-turbo';
    
    // 处理 base URL
    String finalBaseUrl = baseUrl;
    if (baseUrl.endsWith('/v1/chat/completions')) {
      finalBaseUrl = baseUrl.replaceAll('/v1/chat/completions', '');
    } else if (baseUrl.endsWith('/')) {
      finalBaseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    _llm = ChatOpenAI(
      apiKey: apiKey,
      baseUrl: '$finalBaseUrl/v1',
      defaultOptions: ChatOpenAIOptions(
        model: modelName,
        temperature: 0.7,
      ),
    );

    developer.log('🤖 LangChain LLM 初始化完成: $modelName', name: 'LangChainService');
  }

  /// 获取或创建对话记忆
  ConversationBufferMemory _getOrCreateMemory(String sessionId) {
    if (!_memories.containsKey(sessionId)) {
      _memories[sessionId] = ConversationBufferMemory(
        returnMessages: true,
        memoryKey: 'history',
        inputKey: 'input',
        outputKey: 'output',
      );
    }
    return _memories[sessionId]!;
  }

  /// 清除指定会话的记忆
  void clearMemory(String sessionId) {
    _memories.remove(sessionId);
    developer.log('🧹 清除会话记忆: $sessionId', name: 'LangChainService');
  }

  /// 清除所有记忆
  void clearAllMemories() {
    _memories.clear();
    developer.log('🧹 清除所有会话记忆', name: 'LangChainService');
  }

  /// 流式聊天（带记忆功能）
  Stream<String> chatWithMemory({
    required String sessionId,
    required String message,
    String? systemPrompt,
  }) async* {
    if (!_themeService.hasAiConfig) {
      throw Exception('请先配置 AI API');
    }

    // 确保 LLM 已初始化
    if (_llm == null) {
      _initLLM();
    }
    
    if (_llm == null) {
      throw Exception('LLM 初始化失败');
    }

    final memory = _getOrCreateMemory(sessionId);
    
    // 构建提示模板
    final promptTemplate = ChatPromptTemplate.fromTemplates([
      if (systemPrompt != null)
        (ChatMessageType.system, systemPrompt),
      (ChatMessageType.human, '{input}'),
    ]);

    // 创建 Chain
    final chain = LLMChain(
      llm: _llm!,
      prompt: promptTemplate,
      memory: memory,
      outputKey: 'output',
    );

    developer.log('💬 开始流式聊天 - Session: $sessionId', name: 'LangChainService');

    // 执行并流式输出
    final stream = chain.stream({
      'input': message,
    });

    String fullResponse = '';
    await for (final chunk in stream) {
      final text = chunk['output']?.toString() ?? '';
      fullResponse += text;
      yield text;
    }

    developer.log('✅ 聊天完成 - 响应长度: ${fullResponse.length}', name: 'LangChainService');
  }

  /// 初始化向量存储（用于 RAG）
  Future<void> initVectorStore() async {
    if (_vectorStore != null && _vectorStore!.isInitialized) return;

    // 使用持久化向量存储
    _vectorStore = PersistentVectorStore();
    await _vectorStore!.initialize(_createEmbeddings());

    developer.log('📚 持久化向量存储初始化完成', name: 'LangChainService');
  }

  /// 创建嵌入模型
  Embeddings _createEmbeddings() {
    if (!_themeService.hasAiConfig) {
      throw Exception('请先配置 AI API');
    }

    final apiKey = _themeService.aiApiKey;
    final baseUrl = _themeService.aiApiUrl;
    
    // 处理 base URL
    String finalBaseUrl = baseUrl;
    if (baseUrl.endsWith('/v1/chat/completions')) {
      finalBaseUrl = baseUrl.replaceAll('/v1/chat/completions', '');
    } else if (baseUrl.endsWith('/')) {
      finalBaseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    return OpenAIEmbeddings(
      apiKey: apiKey,
      baseUrl: '$finalBaseUrl/v1',
    );
  }

  /// 同步日记到向量存储
  Future<void> syncDiariesToVectorStore() async {
    if (!_themeService.aiDataAccess) {
      developer.log('⚠️ 用户未授权 AI 访问日记数据', name: 'LangChainService');
      return;
    }

    await initVectorStore();

    final entries = await _storageService.getAllEntries();
    
    // 筛选新增或更新的日记
    final newEntries = entries.where((entry) {
      if (_lastVectorUpdate == null) return true;
      return entry.date.isAfter(_lastVectorUpdate!);
    }).toList();

    if (newEntries.isEmpty) {
      developer.log('📚 没有新的日记需要同步', name: 'LangChainService');
      return;
    }

    // 转换为文档并添加到向量存储
    final documents = newEntries.map((entry) {
      final content = _formatEntryForEmbedding(entry);
      return Document(
        id: entry.date.toIso8601String(),
        pageContent: content,
        metadata: {
          'date': entry.date.toIso8601String(),
          'mood': entry.mood,
          'weather': entry.weather,
          'hasImage': entry.images.isNotEmpty,
        },
      );
    }).toList();

    await _vectorStore!.addDocuments(documents: documents);
    _lastVectorUpdate = DateTime.now();

    developer.log('📚 同步了 ${documents.length} 篇日记到向量存储', name: 'LangChainService');
  }

  /// 格式化日记条目用于嵌入
  String _formatEntryForEmbedding(DiaryEntry entry) {
    final buffer = StringBuffer();
    buffer.writeln('日期: ${entry.date.toString().split(' ')[0]}');
    if (entry.mood != null) buffer.writeln('心情: ${entry.mood}');
    if (entry.weather != null) buffer.writeln('天气: ${entry.weather}');
    if (entry.breakfast != null) buffer.writeln('早餐: ${entry.breakfast}');
    if (entry.lunch != null) buffer.writeln('午餐: ${entry.lunch}');
    if (entry.dinner != null) buffer.writeln('晚餐: ${entry.dinner}');
    if (entry.content.isNotEmpty) {
      buffer.writeln('内容: ${entry.content}');
    }
    return buffer.toString();
  }

  /// 基于日记内容的 RAG 问答
  Stream<String> chatWithRAG({
    required String sessionId,
    required String message,
    int topK = 3,
  }) async* {
    if (!_themeService.hasAiConfig) {
      throw Exception('请先配置 AI API');
    }

    if (!_themeService.aiDataAccess) {
      yield '抱歉，您未授权 AI 访问日记数据。请在设置中开启权限。';
      return;
    }

    // 确保 LLM 和向量存储已初始化
    if (_llm == null) {
      _initLLM();
    }
    await syncDiariesToVectorStore();

    if (_vectorStore == null || _llm == null) {
      throw Exception('RAG 初始化失败');
    }

    // 检索相关日记（使用持久化存储的相似度搜索）
    final docs = await _vectorStore!.similaritySearch(query: message, k: topK);
    final context = docs.map((d) => d.pageContent).join('\n---\n');

    // 构建记忆
    final memory = _getOrCreateMemory(sessionId);
    final memoryData = await memory.loadMemoryVariables();
    final history = memoryData['history'] as List<ChatMessage>? ?? [];

    // 构建提示
    final prompt = '''你是"小坡"，一款日记应用中的智能 AI 助手。

基于以下检索到的日记内容，回答用户的问题。如果检索内容不足以回答问题，请诚实告知。

检索到的日记内容：
$context

${history.isNotEmpty ? '对话历史：\n${_formatHistory(history)}\n' : ''}
用户问题：$message

请基于以上日记内容回答用户问题。回复要简洁友好，适当使用 emoji。''';

    developer.log('🔍 RAG 问答 - Query: $message', name: 'LangChainService');

    // 流式调用 LLM
    final stream = _llm!.stream(PromptValue.string(prompt));
    
    String fullResponse = '';
    await for (final chunk in stream) {
      final text = chunk.output.content;
      fullResponse += text;
      yield text;
    }

    // 保存到记忆
    await memory.saveContext(
      inputValues: {'input': message},
      outputValues: {'output': fullResponse},
    );
  }

  /// 格式化对话历史
  String _formatHistory(List<ChatMessage> messages) {
    return messages.map((msg) {
      final role = msg is HumanChatMessage ? '用户' : 'AI';
      return '$role: [消息内容]';
    }).join('\n');
  }

  /// 智能分析日记数据
  Future<Map<String, dynamic>> analyzeDiaries({
    int days = 30,
  }) async {
    if (!_themeService.hasAiConfig) {
      throw Exception('请先配置 AI API');
    }

    if (!_themeService.aiDataAccess) {
      return {'error': '用户未授权 AI 访问日记数据'};
    }

    if (_llm == null) {
      _initLLM();
    }

    // 获取指定时间范围的日记
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final entries = await _storageService.getAllEntries();
    
    final filteredEntries = entries.where((entry) {
      return entry.date.isAfter(startDate) || entry.date.isAtSameMomentAs(startDate);
    }).toList();

    if (filteredEntries.isEmpty) {
      return {'error': '最近 $days 天暂无日记记录'};
    }

    // 格式化日记数据
    final diariesText = filteredEntries.map((entry) {
      return _formatEntryForEmbedding(entry);
    }).join('\n---\n');

    // 构建分析提示
    final analysisPrompt = '''请分析以下最近 $days 天的日记数据，提供：

1. 情绪趋势分析（情绪波动情况、主导情绪）
2. 生活规律分析（作息、饮食等）
3. 关键事件提取（重要或有意义的事件）
4. 个性化建议（基于日记内容的积极建议）

日记数据：
$diariesText

请以 JSON 格式返回分析结果，格式如下：
{
  "moodTrend": "情绪趋势分析...",
  "lifePattern": "生活规律分析...",
  "keyEvents": ["事件1", "事件2", ...],
  "suggestions": ["建议1", "建议2", ...]
}''';

    developer.log('📊 开始分析 ${filteredEntries.length} 篇日记', name: 'LangChainService');

    try {
      final response = await _llm!.invoke(PromptValue.string(analysisPrompt));
      final content = response.output.content;

      // 解析 JSON 响应
      try {
        final jsonStr = content.replaceAll(RegExp(r'```json\s*|\s*```'), '');
        final result = jsonDecode(jsonStr);
        developer.log('✅ 日记分析完成', name: 'LangChainService');
        return result;
      } catch (e) {
        developer.log('⚠️ JSON 解析失败，返回原始文本', name: 'LangChainService');
        return {'rawAnalysis': content};
      }
    } catch (e) {
      developer.log('❌ 分析失败: $e', name: 'LangChainService');
      return {'error': '分析失败: $e'};
    }
  }

  /// 生成周报/月报
  Future<String> generateReport({
    required int days,
    String type = '周报',
  }) async {
    if (!_themeService.hasAiConfig) {
      throw Exception('请先配置 AI API');
    }

    if (!_themeService.aiDataAccess) {
      return '抱歉，您未授权 AI 访问日记数据。请在设置中开启权限。';
    }

    if (_llm == null) {
      _initLLM();
    }

    // 获取日记数据
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final entries = await _storageService.getAllEntries();
    
    final filteredEntries = entries.where((entry) {
      return entry.date.isAfter(startDate) || entry.date.isAtSameMomentAs(startDate);
    }).toList();

    if (filteredEntries.isEmpty) {
      return '最近 $days 天暂无日记记录，无法生成$type。';
    }

    // 格式化日记
    final diariesText = filteredEntries.map((entry) {
      return _formatEntryForEmbedding(entry);
    }).join('\n---\n');

    final reportPrompt = '''请基于以下日记内容生成一份温暖的$type回顾。

日记内容：
$diariesText

请生成一份结构化的$type，包含：
1. 📊 本周/月概览（日记天数、情绪总体情况）
2. 😊 情绪亮点（积极情绪的记录）
3. 🍽️ 饮食记录（有趣的饮食内容）
4. 💡 成长与感悟
5. 🌟 下周/月寄语

请用温暖、鼓励的语气书写，适当使用 emoji，让用户感受到被关心和理解。''';

    developer.log('📝 生成$type - ${filteredEntries.length} 篇日记', name: 'LangChainService');

    try {
      final response = await _llm!.invoke(PromptValue.string(reportPrompt));
      return response.output.content;
    } catch (e) {
      developer.log('❌ 生成报告失败: $e', name: 'LangChainService');
      return '生成$type失败: $e';
    }
  }

  /// 检查是否已配置
  bool get isConfigured => _themeService.hasAiConfig;

  /// 检查是否可以访问数据
  bool get canAccessData => _themeService.aiDataAccess;
}
