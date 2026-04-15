import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';

import 'theme_service.dart';
import 'storage_service.dart';
import 'diary_query_service.dart';
import 'local_rag_service.dart';
import '../models/diary_entry.dart';

/// LangChain 服务 - 提供增强的 AI 功能
///
/// 功能：
/// 1. 对话记忆 - 维护长期对话上下文
/// 2. RAG 检索 - 基于 BM25 的本地关键词搜索（完全离线）
/// 3. 智能分析 - 自动分析日记趋势和洞察
/// 4. Function Calling - 使用 LangChain ToolsAgent
class LangChainService {
  static final LangChainService _instance = LangChainService._internal();
  factory LangChainService() => _instance;
  LangChainService._internal();

  final ThemeService _themeService = ThemeService();
  final StorageService _storageService = StorageService();
  final DiaryQueryService _diaryQueryService = DiaryQueryService(StorageService());
  final LocalRagService _localRagService = LocalRagService();

  // LLM 实例
  ChatOpenAI? _llm;

  // Agent 缓存（按会话 ID）
  final Map<String, (ToolsAgent, AgentExecutor)> _agents = {};

  /// 初始化或重新初始化 LLM
  Future<bool> _initLLM() async {
    if (!_themeService.hasAiConfig) {
      _llm = null;
      return false;
    }

    final apiKey = _themeService.aiApiKey;
    final baseUrl = _themeService.aiApiUrl;

    // 确保 ThemeService 已完成初始化
    await _themeService.ensureInitialized();

    if (apiKey.isEmpty || baseUrl.isEmpty) {
      _llm = null;
      return false;
    }

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

    try {
      _llm = ChatOpenAI(
        apiKey: apiKey,
        baseUrl: '$finalBaseUrl/v1',
        defaultOptions: ChatOpenAIOptions(
          model: modelName,
          temperature: 0.7,
        ),
      );

      developer.log('🤖 LangChain LLM 初始化完成: $modelName', name: 'LangChainService');
      return true;
    } catch (e) {
      developer.log('❌ LLM 初始化失败: $e', name: 'LangChainService');
      _llm = null;
      return false;
    }
  }

  /// 创建日记查询工具
  List<Tool> _createDiaryTools() {
    return [
      // 获取当前月份日记
      Tool.fromFunction(
        name: 'getCurrentMonthDiaries',
        description: '获取当前月份的所有日记记录',
        inputJsonSchema: {'type': 'object', 'properties': {}},
        func: (_) async => await _diaryQueryService.getCurrentMonthDiaries(),
      ),
      // 获取最近 N 天日记
      Tool.fromFunction(
        name: 'getRecentDiaries',
        description: '获取最近N天的日记记录',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'days': {'type': 'integer', 'description': '要获取最近多少天的日记'},
          },
          'required': ['days'],
        },
        func: (input) async {
          final inputMap = input as Map<String, dynamic>;
          final days = (inputMap['days'] as num?)?.toInt() ?? 7;
          return await _diaryQueryService.getRecentDiaries(days);
        },
      ),
      // 按日期范围查询
      Tool.fromFunction(
        name: 'getDiariesByDateRange',
        description: '获取指定日期范围内的日记记录，日期格式为yyyy-MM-dd',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'startDate': {'type': 'string', 'description': '开始日期，格式yyyy-MM-dd'},
            'endDate': {'type': 'string', 'description': '结束日期，格式yyyy-MM-dd'},
          },
          'required': ['startDate', 'endDate'],
        },
        func: (input) async {
          final inputMap = input as Map<String, dynamic>;
          final startDate = DateTime.parse(inputMap['startDate'] as String);
          final endDate = DateTime.parse(inputMap['endDate'] as String);
          return await _diaryQueryService.getDiariesByDateRange(startDate, endDate);
        },
      ),
      // 按心情筛选
      Tool.fromFunction(
        name: 'getDiariesByMood',
        description: '按心情筛选日记记录',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'mood': {'type': 'string', 'description': '要筛选的心情，如"开心"、"难过"'},
          },
          'required': ['mood'],
        },
        func: (input) async {
          final inputMap = input as Map<String, dynamic>;
          final mood = inputMap['mood'] as String? ?? '';
          return await _diaryQueryService.getDiariesByMood(mood);
        },
      ),
      // 关键词搜索
      Tool.fromFunction(
        name: 'searchDiaries',
        description: '按关键词搜索日记内容',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'keyword': {'type': 'string', 'description': '要搜索的关键词'},
          },
          'required': ['keyword'],
        },
        func: (input) async {
          final inputMap = input as Map<String, dynamic>;
          final keyword = inputMap['keyword'] as String? ?? '';
          return await _diaryQueryService.searchDiaries(keyword);
        },
      ),
      // 心情统计
      Tool.fromFunction(
        name: 'getMoodStats',
        description: '统计最近N天的心情分布',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'days': {'type': 'integer', 'description': '要统计最近多少天'},
          },
          'required': ['days'],
        },
        func: (input) async {
          final inputMap = input as Map<String, dynamic>;
          final days = (inputMap['days'] as num?)?.toInt() ?? 7;
          return await _diaryQueryService.getMoodStats(days);
        },
      ),
      // 饮食统计
      Tool.fromFunction(
        name: 'getDietStats',
        description: '统计最近N天的饮食记录',
        inputJsonSchema: {
          'type': 'object',
          'properties': {
            'days': {'type': 'integer', 'description': '要统计最近多少天'},
          },
          'required': ['days'],
        },
        func: (input) async {
          final inputMap = input as Map<String, dynamic>;
          final days = (inputMap['days'] as num?)?.toInt() ?? 7;
          return await _diaryQueryService.getDietStats(days);
        },
      ),
      // 去年今天
      Tool.fromFunction(
        name: 'getDiaryOnSameDayLastYear',
        description: '获取去年今天的日记记录',
        inputJsonSchema: {'type': 'object', 'properties': {}},
        func: (_) async => await _diaryQueryService.getDiaryOnSameDayLastYear(),
      ),
    ];
  }

  /// 获取系统提示词模板
  SystemChatMessagePromptTemplate _getSystemPromptTemplate(String context) {
    final prompt = '''你是"小坡"，一款日记应用中的智能 AI 助手。

当前时间：${DateTime.now().toString().split('.')[0]}

你有以下能力：
1. 回答用户的日常问题（时间、天气、建议等）
2. 查询用户的日记数据（通过提供的工具函数）
3. 基于日记内容回答相关问题

${context.isNotEmpty && context != '没有找到相关的日记记录。' ? '以下是通过本地检索找到的日记内容，你可以参考：\n$context\n' : ''}

当用户询问日记相关内容时，请使用工具函数精确查询。''';

    return SystemChatMessagePromptTemplate.fromTemplate(prompt);
  }

  /// 获取或创建 Agent
  (ToolsAgent, AgentExecutor) _getOrCreateAgent(String sessionId) {
    if (_llm == null) {
      throw Exception('LLM 未初始化，请检查 AI API 配置');
    }

    if (!_agents.containsKey(sessionId)) {
      // 使用 WindowMemory 限制保留最近 15 轮对话
      final memory = ConversationBufferWindowMemory(
        returnMessages: true,
        memoryKey: 'history',
        k: 15,
      );

      final tools = _createDiaryTools();

      final agent = ToolsAgent.fromLLMAndTools(
        llm: _llm!,
        tools: tools,
        memory: memory,
        systemChatMessage: _getSystemPromptTemplate(''),
      );

      final executor = AgentExecutor(agent: agent);

      _agents[sessionId] = (agent, executor);
    }
    return _agents[sessionId]!;
  }

  /// 清除指定会话的 Agent
  void clearMemory(String sessionId) {
    _agents.remove(sessionId);
    developer.log('🧹 清除会话 Agent: $sessionId', name: 'LangChainService');
  }

  /// 清除所有 Agent
  void clearAllMemories() {
    _agents.clear();
    developer.log('🧹 清除所有会话 Agent', name: 'LangChainService');
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

    if (_llm == null) {
      final success = await _initLLM();
      if (!success) {
        throw Exception('LLM 初始化失败，请检查 AI API 配置');
      }
    }

    // 使用 Agent 进行聊天
    final (_, executor) = _getOrCreateAgent(sessionId);

    developer.log('💬 开始 Agent 流式聊天 - Session: $sessionId', name: 'LangChainService');

    // 使用 stream 方法进行流式输出
    final stream = executor.stream({
      'input': message,
    });

    String fullResponse = '';
    await for (final chunk in stream) {
      final output = chunk['output']?.toString() ?? '';
      fullResponse += output;
      yield output;
    }

    developer.log('✅ 聊天完成 - 响应长度: ${fullResponse.length}', name: 'LangChainService');
  }

  /// 基于日记内容的 RAG 问答（使用 Function Calling + 流式输出）
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

    // 使用本地 RAG 检索相关内容
    final context = await _localRagService.generateRagContext(message, topK: topK);

    // 获取当前时间
    final now = DateTime.now();
    final currentTimeStr = DateFormat('yyyy年MM月dd日 HH:mm').format(now);

    // 构建系统提示词
    String systemPrompt = '''你是"小坡"，一款日记应用中的智能 AI 助手。
当前时间：$currentTimeStr

${context.isNotEmpty && context != '没有找到相关的日记记录。' ? '以下是通过本地检索找到的日记内容，你可以参考：\n$context\n' : ''}

## 你的职责
你是一个温暖的日记伙伴，帮助用户记录、回顾和分析他们的日常生活。

## 你能做什么
1. **日记查询**：通过工具查询用户的日记数据
2. **日记分析**：帮用户总结日记内容
3. **写作陪伴**：提供写作灵感
4. **心情倾听**：给予温暖的回应

## 你不能做什么（重要）
- 你**不是**百科全书，不是搜索引擎
- 如果用户问了与日记、心情、日常生活记录**无关**的问题，请**委婉地表示不擅长**，例如："这个问题超出了我的能力范围呢，我主要是陪你记录生活的小伙伴～"
- **不要主动报时**，除非用户明确问了"现在几点"、"今天星期几"等问题
- **回复要简短**，一般 1-3 句话即可

## 你可以使用的查询工具
- **getCurrentMonthDiaries**：获取当前月份的日记
- **getRecentDiaries**：获取最近N天的日记（参数：days）
- **getDiariesByDateRange**：获取指定日期范围的日记（参数：startDate, endDate，格式yyyy-MM-dd）
- **getDiariesByMood**：按心情筛选日记（参数：mood）
- **searchDiaries**：按关键词搜索日记（参数：keyword）
- **getMoodStats**：统计最近N天的心情分布（参数：days）
- **getDietStats**：统计最近N天的饮食记录（参数：days）
- **getDiaryOnSameDayLastYear**：获取去年今天的日记

## 工具调用规则
- 用户问日记相关内容时，自动调用合适的工具
- 日期格式必须是 yyyy-MM-dd

## 你的性格
- 友好、温暖、像朋友一样
- 回复简短自然，像聊天一样
- 适当用 emoji，不要过度

现在，开始帮助用户吧！''';

    developer.log('🔍 RAG 流式问答 - Query: $message', name: 'LangChainService');

    // 使用真正的 SSE 流式 Function Calling
    final tools = _createToolsForRAG();
    final messageHistory = [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': message},
    ];

    yield* _chatStreamWithFunctions(messageHistory, tools);
  }

  /// 为 RAG 创建工具列表
  List<Map<String, dynamic>> _createToolsForRAG() {
    return [
      {'type': 'function', 'function': {'name': 'getCurrentMonthDiaries', 'description': '获取当前月份的所有日记记录', 'parameters': {'type': 'object', 'properties': {}}}},
      {'type': 'function', 'function': {'name': 'getRecentDiaries', 'description': '获取最近N天的日记记录', 'parameters': {'type': 'object', 'properties': {'days': {'type': 'integer', 'description': '要获取最近多少天的日记'}}, 'required': ['days']}}},
      {'type': 'function', 'function': {'name': 'getDiariesByDateRange', 'description': '获取指定日期范围内的日记记录', 'parameters': {'type': 'object', 'properties': {'startDate': {'type': 'string', 'description': '开始日期，格式yyyy-MM-dd'}, 'endDate': {'type': 'string', 'description': '结束日期，格式yyyy-MM-dd'}}, 'required': ['startDate', 'endDate']}}},
      {'type': 'function', 'function': {'name': 'getDiariesByMood', 'description': '按心情筛选日记记录', 'parameters': {'type': 'object', 'properties': {'mood': {'type': 'string', 'description': '要筛选的心情'}}, 'required': ['mood']}}},
      {'type': 'function', 'function': {'name': 'searchDiaries', 'description': '按关键词搜索日记内容', 'parameters': {'type': 'object', 'properties': {'keyword': {'type': 'string', 'description': '要搜索的关键词'}}, 'required': ['keyword']}}},
      {'type': 'function', 'function': {'name': 'getMoodStats', 'description': '统计最近N天的心情分布', 'parameters': {'type': 'object', 'properties': {'days': {'type': 'integer', 'description': '要统计最近多少天'}}, 'required': ['days']}}},
      {'type': 'function', 'function': {'name': 'getDietStats', 'description': '统计最近N天的饮食记录', 'parameters': {'type': 'object', 'properties': {'days': {'type': 'integer', 'description': '要统计最近多少天'}}, 'required': ['days']}}},
      {'type': 'function', 'function': {'name': 'getDiaryOnSameDayLastYear', 'description': '获取去年今天的日记记录', 'parameters': {'type': 'object', 'properties': {}}}},
    ];
  }

  int _asInt(dynamic value, {int fallback = 7}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Map<String, dynamic>? _tryParseToolArguments(String rawArguments) {
    final trimmed = rawArguments.trim();
    if (trimmed.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
    return null;
  }

  /// 流式 Function Calling 实现（真正的 SSE 流）
  Stream<String> _chatStreamWithFunctions(
    List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>> tools,
  ) async* {
    final apiKey = _themeService.aiApiKey;
    final url = _themeService.aiApiUrl;
    String finalUrl = url;
    if (!url.endsWith('/v1/chat/completions')) {
      finalUrl = url.endsWith('/') ? '${url}v1/chat/completions' : '$url/v1/chat/completions';
    }
    final isDeepSeek = url.contains('deepseek');
    final model = isDeepSeek ? 'deepseek-chat' : 'gpt-3.5-turbo';

    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse(finalUrl));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'Accept': 'text/event-stream',
      });
      request.body = jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.7,
        'stream': true,
        'tools': tools,
        'tool_choice': 'auto',
      });

      final response = await client.send(request);
      if (response.statusCode == 200) {
        StringBuffer buffer = StringBuffer();
        String? functionName;
        Map<String, dynamic>? functionArguments;
        final StringBuffer functionArgumentsBuffer = StringBuffer();
        bool isCollectingFunction = false;

        await for (final chunk in response.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data == '[DONE]') {
                if (functionName != null && functionArguments == null) {
                  try {
                    functionArguments = _tryParseToolArguments(functionArgumentsBuffer.toString());
                  } catch (_) {
                    yield '\n查询数据时出错: 工具参数解析失败';
                    return;
                  }
                }
                if (functionName != null && functionArguments != null) {
                  yield '\n\n[正在查询数据...]\n';
                  try {
                    final result = await _executeFunction(functionName, functionArguments);
                    final functionMessages = [...messages];
                    final toolCallId = 'call_${DateTime.now().millisecondsSinceEpoch}';
                    functionMessages.add({
                      'role': 'assistant',
                      'content': '',  // 使用空字符串替代 null，兼容更多 API
                      'tool_calls': [{
                        'id': toolCallId,
                        'type': 'function',
                        'function': {'name': functionName, 'arguments': jsonEncode(functionArguments)},
                      }],
                    });
                    functionMessages.add({
                      'role': 'tool',
                      'tool_call_id': toolCallId,
                      'content': result,
                    });
                    yield* _continueChatStream(functionMessages);
                  } catch (e) {
                    yield '\n查询数据时出错: $e';
                  }
                }
                return;
              }
              try {
                final jsonData = jsonDecode(data);
                final delta = jsonData['choices']?[0]?['delta'];
                final toolCalls = delta?['tool_calls'];
                if (toolCalls != null && toolCalls is List && toolCalls.isNotEmpty) {
                  isCollectingFunction = true;
                  final toolCall = toolCalls[0];
                  if (toolCall['function'] != null) {
                    functionName = toolCall['function']['name'] ?? functionName;
                    final args = toolCall['function']['arguments'];
                    if (args != null && args is String && args.isNotEmpty) {
                      functionArgumentsBuffer.write(args);
                      try {
                        final parsed = _tryParseToolArguments(functionArgumentsBuffer.toString());
                        if (parsed != null) functionArguments = parsed;
                      } catch (_) {}
                    }
                  }
                }
                final content = delta?['content'];
                if (content != null && !isCollectingFunction) {
                  buffer.write(content);
                  yield content;
                }
              } catch (_) {}
            }
          }
        }
      } else {
        throw Exception('API 请求失败: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }

  /// 继续聊天（带函数结果）- 流式
  Stream<String> _continueChatStream(List<Map<String, dynamic>> messages) async* {
    final apiKey = _themeService.aiApiKey;
    final url = _themeService.aiApiUrl;
    String finalUrl = url;
    if (!url.endsWith('/v1/chat/completions')) {
      finalUrl = url.endsWith('/') ? '${url}v1/chat/completions' : '$url/v1/chat/completions';
    }
    final isDeepSeek = url.contains('deepseek');
    final model = isDeepSeek ? 'deepseek-chat' : 'gpt-3.5-turbo';

    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse(finalUrl));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'Accept': 'text/event-stream',
      });
      request.body = jsonEncode({
        'model': model,
        'messages': messages,
        'temperature': 0.7,
        'stream': true,
      });

      final response = await client.send(request);
      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data == '[DONE]') return;
              try {
                final jsonData = jsonDecode(data);
                final content = jsonData['choices']?[0]?['delta']?['content'];
                if (content != null) yield content;
              } catch (_) {}
            }
          }
        }
      }
    } finally {
      client.close();
    }
  }

  /// 执行函数调用
  Future<String> _executeFunction(String functionName, Map<String, dynamic> arguments) async {
    developer.log('🎯 执行函数: $functionName, 参数: $arguments', name: 'LangChainService');
    try {
      switch (functionName) {
        case 'getCurrentMonthDiaries': return await _diaryQueryService.getCurrentMonthDiaries();
        case 'getRecentDiaries': return await _diaryQueryService.getRecentDiaries(_asInt(arguments['days']));
        case 'getDiariesByDateRange':
          return await _diaryQueryService.getDiariesByDateRange(
            DateTime.parse(arguments['startDate'] as String),
            DateTime.parse(arguments['endDate'] as String),
          );
        case 'getDiariesByMood': return await _diaryQueryService.getDiariesByMood(arguments['mood'] as String? ?? '');
        case 'searchDiaries': return await _diaryQueryService.searchDiaries(arguments['keyword'] as String? ?? '');
        case 'getMoodStats': return await _diaryQueryService.getMoodStats(_asInt(arguments['days']));
        case 'getDietStats': return await _diaryQueryService.getDietStats(_asInt(arguments['days']));
        case 'getDiaryOnSameDayLastYear': return await _diaryQueryService.getDiaryOnSameDayLastYear();
        default: throw Exception('未知的函数: $functionName');
      }
    } catch (e) {
      return '查询失败: $e';
    }
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
      final success = await _initLLM();
      if (!success) {
        return {'error': 'LLM 初始化失败，请检查 AI API 配置'};
      }
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
      final success = await _initLLM();
      if (!success) {
        return 'LLM 初始化失败，请检查 AI API 配置';
      }
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