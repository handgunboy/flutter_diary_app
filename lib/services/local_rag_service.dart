import 'dart:math';
import 'dart:developer' as developer;
import '../models/diary_entry.dart';
import 'storage_service.dart';
import 'theme_service.dart';

/// 本地 BM25 RAG 服务 - 完全离线，无需远程 API
///
/// 功能：
/// 1. 基于 BM25 的关键词匹配（比 TF-IDF 更准确）
/// 2. 智能意图识别 - 只对需要查询日记的问题启用 RAG
/// 3. 完全本地运行，保护隐私
class LocalRagService {
  static final LocalRagService _instance = LocalRagService._internal();
  factory LocalRagService() => _instance;
  LocalRagService._internal();

  final StorageService _storageService = StorageService();
  final ThemeService _themeService = ThemeService();

  // BM25 参数
  static const double _k1 = 1.5; // 词频饱和度参数
  static const double _b = 0.75; // 文档长度归一化参数

  // 停用词列表
  static final Set<String> _stopWords = {
    '的', '了', '在', '是', '我', '有', '和', '就', '不', '人', '都', '一', '一个', '上', '也', '很', '到', '说', '要', '去', '你', '会', '着', '没有', '看', '好', '自己', '这', '那', '之', '与', '及', '等', '或', '但', '而', '如果', '因为', '所以', '虽然', '然而',
    'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might', 'must', 'shall', 'can', 'need', 'dare', 'ought', 'used', 'to', 'of', 'in', 'for', 'on', 'with', 'at', 'by', 'from', 'as', 'into', 'through', 'during', 'before', 'after', 'above', 'below', 'between', 'under', 'and', 'but', 'or', 'yet', 'so', 'if', 'because', 'although', 'though', 'while', 'where', 'when', 'that', 'which', 'who', 'whom', 'whose', 'what', 'whatever', 'this', 'these', 'those', 'i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves', 'you', 'your', 'yours', 'yourself', 'yourselves', 'he', 'him', 'his', 'himself', 'she', 'her', 'hers', 'herself', 'it', 'its', 'itself', 'they', 'them', 'their', 'theirs', 'themselves',
  };

  // 需要查询日记的关键词
  static final Set<String> _diaryQueryKeywords = {
    // 日记相关
    '日记', '记录', '写过', '记得', '那天', '当时', '以前', '之前', '上次', '曾经',
    // 时间相关
    '昨天', '前天', '上周', '上个月', '去年', '最近', '这段时间', '这些天', '这几天',
    // 内容相关
    '吃了', '吃了什么', '早餐', '午餐', '晚餐', '心情', '感觉', '天气', '做了什么',
    '去哪', '去哪里', '去了', '见过', '遇到', '发生', '事情', '活动', '经历',
    // 情绪相关
    '开心', '难过', '生气', '焦虑', '压力大', '累', '高兴', '快乐', '伤心', '郁闷',
    // 查询动词
    '查', '查找', '搜索', '找找', '有没有', '是否', '帮我找', '帮我查', '帮我看看',
    // 统计相关
    '多少', '几次', '频率', '经常', '总是', '通常', '习惯',
  };

  // 明确不需要查日记的关键词（闲聊、通用问题）
  static final Set<String> _generalChatKeywords = {
    '你好', '您好', '嗨', '哈喽', 'hello', 'hi',
    '谢谢', '感谢', '不客气', '再见', '拜拜', 'goodbye',
    '今天几号', '现在几点', '今天星期几', '现在时间', '当前时间',
    '你是谁', '你叫什么', '你能做什么', '介绍一下', '介绍一下自己',
    '天气怎么样', '会下雨吗', '温度多少', // 这些应该查实时天气，不是日记
    '讲个笑话', '说个故事', '推荐', '建议', '怎么办', '怎么做',
    '为什么', '是什么', '什么意思', '怎么理解',
  };

  /// 判断是否需要查询日记
  /// 返回 true 表示需要使用 RAG 查询日记
  bool shouldQueryDiary(String query) {
    final lowerQuery = query.toLowerCase();

    // 1. 先检查是否是明确的闲聊问题
    for (final keyword in _generalChatKeywords) {
      if (lowerQuery.contains(keyword)) {
        developer.log('🚫 识别为通用问题，跳过 RAG: $query', name: 'LocalRagService');
        return false;
      }
    }

    // 2. 检查是否包含日记查询关键词
    for (final keyword in _diaryQueryKeywords) {
      if (lowerQuery.contains(keyword)) {
        developer.log('✅ 识别为日记查询，启用 RAG: $query', name: 'LocalRagService');
        return true;
      }
    }

    // 3. 检查是否包含日期/时间相关词汇（可能是查询特定日期的日记）
    final datePatterns = [
      RegExp(r'\d{4}年'), // 2024年
      RegExp(r'\d{1,2}月\d{1,2}日'), // 3月15日
      RegExp(r'\d{1,2}月'), // 3月
      RegExp(r'星期[一二三四五六日]'), // 星期一
    ];
    for (final pattern in datePatterns) {
      if (pattern.hasMatch(query)) {
        developer.log('✅ 识别为日期查询，启用 RAG: $query', name: 'LocalRagService');
        return true;
      }
    }

    // 4. 默认不使用 RAG（保守策略）
    developer.log('🚫 未识别为日记查询，跳过 RAG: $query', name: 'LocalRagService');
    return false;
  }

  /// 基于 BM25 的相似度搜索
  Future<List<DiaryEntry>> searchRelevantDiaries(
    String query, {
    int topK = 3,
  }) async {
    if (!_themeService.aiDataAccess) {
      developer.log('⚠️ 用户未授权 AI 访问日记数据', name: 'LocalRagService');
      return [];
    }

    final entries = await _storageService.getAllEntries();
    if (entries.isEmpty) return [];

    // 分词
    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) return [];

    // 计算平均文档长度
    final avgDocLength = _calculateAvgDocLength(entries);

    // 计算 IDF
    final idf = _calculateIdf(entries, queryTokens);

    // 计算每个日记的 BM25 分数
    final List<(DiaryEntry, double)> scoredEntries = [];

    for (final entry in entries) {
      final score = _calculateBM25Score(entry, queryTokens, idf, avgDocLength);
      if (score > 0) {
        scoredEntries.add((entry, score));
      }
    }

    // 按分数降序排序
    scoredEntries.sort((a, b) => b.$2.compareTo(a.$2));

    developer.log(
      '🔍 BM25 搜索: "$query" 找到 ${scoredEntries.length} 条相关日记',
      name: 'LocalRagService',
    );

    return scoredEntries.take(topK).map((e) => e.$1).toList();
  }

  /// 计算平均文档长度
  double _calculateAvgDocLength(List<DiaryEntry> entries) {
    if (entries.isEmpty) return 0;
    int totalLength = 0;
    for (final entry in entries) {
      totalLength += _extractEntryText(entry).length;
    }
    return totalLength / entries.length;
  }

  /// 分词 - 支持中英文
  List<String> _tokenize(String text) {
    final tokens = <String>[];

    // 提取中文词语（2-4 个字）
    for (int i = 0; i < text.length - 1; i++) {
      for (int len = 2; len <= 4 && i + len <= text.length; len++) {
        final word = text.substring(i, i + len);
        if (_isChineseWord(word)) {
          tokens.add(word);
        }
      }
    }

    // 提取英文单词
    final englishWords = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2 && !_stopWords.contains(w));
    tokens.addAll(englishWords);

    // 添加单字（中文）
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (_isChinese(char) && !_stopWords.contains(char)) {
        tokens.add(char);
      }
    }

    return tokens.where((t) => !_stopWords.contains(t)).toList();
  }

  /// 判断是否为中文
  bool _isChinese(String char) {
    return RegExp(r'[\u4e00-\u9fa5]').hasMatch(char);
  }

  /// 判断是否为中文字词
  bool _isChineseWord(String word) {
    return word.runes.every((r) {
      final char = String.fromCharCode(r);
      return _isChinese(char);
    });
  }

  /// 计算 IDF（逆文档频率）
  Map<String, double> _calculateIdf(
    List<DiaryEntry> entries,
    List<String> queryTokens,
  ) {
    final idf = <String, double>{};
    final n = entries.length;

    for (final token in queryTokens.toSet()) {
      // 统计包含该词的日记数量
      int df = 0;
      for (final entry in entries) {
        final entryText = _extractEntryText(entry);
        final entryTokens = _tokenize(entryText);
        if (entryTokens.contains(token)) {
          df++;
        }
      }

      // BM25 的 IDF 公式：log((N - DF + 0.5) / (DF + 0.5) + 1)
      idf[token] = log((n - df + 0.5) / (df + 0.5) + 1);
    }

    return idf;
  }

  /// 提取日记文本内容（包含所有可检索字段）
  String _extractEntryText(DiaryEntry entry) {
    final buffer = StringBuffer();
    buffer.write(entry.content);
    if (entry.title.isNotEmpty) buffer.write(' ${entry.title}');
    if (entry.mood != null) buffer.write(' ${entry.mood}');
    if (entry.weather != null) buffer.write(' ${entry.weather}');
    if (entry.weight != null) buffer.write(' ${entry.weight}');
    if (entry.breakfast != null) buffer.write(' ${entry.breakfast}');
    if (entry.lunch != null) buffer.write(' ${entry.lunch}');
    if (entry.dinner != null) buffer.write(' ${entry.dinner}');
    if (entry.snacks != null) buffer.write(' ${entry.snacks}');
    return buffer.toString();
  }

  /// 计算 BM25 分数
  double _calculateBM25Score(
    DiaryEntry entry,
    List<String> queryTokens,
    Map<String, double> idf,
    double avgDocLength,
  ) {
    final entryText = _extractEntryText(entry);
    final entryTokens = _tokenize(entryText);

    if (entryTokens.isEmpty) return 0;

    double score = 0;
    final docLength = entryText.length;

    // 统计词频
    final tokenCounts = <String, int>{};
    for (final token in entryTokens) {
      tokenCounts[token] = (tokenCounts[token] ?? 0) + 1;
    }

    // 计算 BM25
    for (final token in queryTokens.toSet()) {
      final tf = tokenCounts[token] ?? 0;
      if (tf == 0) continue;

      final idfValue = idf[token] ?? 0;

      // BM25 公式：IDF * (TF * (k1 + 1)) / (TF + k1 * (1 - b + b * (docLength / avgDocLength)))
      final tfComponent = (tf * (_k1 + 1)) /
          (tf + _k1 * (1 - _b + _b * (docLength / avgDocLength)));

      score += idfValue * tfComponent;
    }

    // 加权：心情和天气匹配加分
    final queryLower = queryTokens.join(' ').toLowerCase();
    if (entry.mood != null &&
        queryLower.contains(entry.mood!.toLowerCase())) {
      score *= 1.2;
    }
    if (entry.weather != null &&
        queryLower.contains(entry.weather!.toLowerCase())) {
      score *= 1.1;
    }

    return score;
  }

  /// 生成 RAG 上下文
  /// 如果不需要查询日记，返回空字符串
  Future<String> generateRagContext(String query, {int topK = 3}) async {
    // 先判断是否需要查询日记
    if (!shouldQueryDiary(query)) {
      return '';
    }

    final entries = await searchRelevantDiaries(query, topK: topK);

    if (entries.isEmpty) {
      return '没有找到相关的日记记录。';
    }

    final buffer = StringBuffer();
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.writeln('【日记 ${i + 1}】${entry.date.toString().split(' ')[0]}');
      if (entry.title.isNotEmpty) buffer.writeln('标题: ${entry.title}');
      if (entry.mood != null) buffer.writeln('心情: ${entry.mood}');
      if (entry.weather != null) buffer.writeln('天气: ${entry.weather}');
      if (entry.weight != null) buffer.writeln('体重: ${entry.weight}');
      if (entry.breakfast != null) buffer.writeln('早餐: ${entry.breakfast}');
      if (entry.lunch != null) buffer.writeln('午餐: ${entry.lunch}');
      if (entry.dinner != null) buffer.writeln('晚餐: ${entry.dinner}');
      if (entry.snacks != null) buffer.writeln('零食: ${entry.snacks}');
      if (entry.content.isNotEmpty) buffer.writeln('内容: ${entry.content}');
      buffer.writeln();
    }

    return buffer.toString();
  }
}
