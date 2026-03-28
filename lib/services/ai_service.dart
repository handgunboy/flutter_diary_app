import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'theme_service.dart';
import 'storage_service.dart';
import '../models/diary_entry.dart';

class AiService {
  final ThemeService _themeService = ThemeService();
  final StorageService _storageService = StorageService();

  Future<Map<String, dynamic>?> parseDiary(String summary) async {
    if (!_themeService.hasAiConfig) {
      throw Exception('请先配置 AI API');
    }

    final url = _themeService.aiApiUrl;
    final apiKey = _themeService.aiApiKey;

    final prompt = '''
请将以下日记总结解析成结构化数据，以JSON格式返回：

日记总结：$summary

请解析出以下字段（如果总结中没有提到某个字段，该字段返回null）：
- breakfast: 早餐内容
- lunch: 午餐内容  
- dinner: 晚餐内容
- snacks: 零食/其他
- mood: 心情（如：开心、平静、焦虑等）
- weather: 天气（如：晴天、多云、下雨等）
- content: 日记详细内容（将总结扩展成完整日记）

只返回JSON，不要返回其他文字说明。格式示例：
{
  "breakfast": "豆浆、油条",
  "lunch": "红烧肉、米饭",
  "dinner": "蔬菜沙拉",
  "snacks": null,
  "mood": "开心",
  "weather": "晴天",
  "content": "今天天气很好..."
}
''';

    try {
      // 自动补全 URL（如果用户只输入了基础 URL）
      String finalUrl = url;
      if (!url.endsWith('/v1/chat/completions')) {
        if (url.endsWith('/')) {
          finalUrl = '${url}v1/chat/completions';
        } else {
          finalUrl = '$url/v1/chat/completions';
        }
      }

      // 检测是否为 DeepSeek API
      final isDeepSeek = url.contains('deepseek');
      final model = isDeepSeek ? 'deepseek-chat' : 'gpt-3.5-turbo';

      final response = await http.post(
        Uri.parse(finalUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // 解析 JSON 响应
        try {
          final result = jsonDecode(content);
          return result;
        } catch (e) {
          // 如果返回的不是纯 JSON，尝试提取 JSON 部分
          final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
          if (jsonMatch != null) {
            return jsonDecode(jsonMatch.group(0)!);
          }
          throw Exception('AI 返回格式错误');
        }
      } else {
        throw Exception('API 请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('AI 解析失败: $e');
    }
  }

  // 流式聊天方法
  Stream<String> chatStream(List<Map<String, String>> messages) async* {
    if (!_themeService.hasAiConfig) {
      throw Exception('请先配置 AI API');
    }

    final url = _themeService.aiApiUrl;
    final apiKey = _themeService.aiApiKey;

    try {
      // 自动补全 URL
      String finalUrl = url;
      if (!url.endsWith('/v1/chat/completions')) {
        if (url.endsWith('/')) {
          finalUrl = '${url}v1/chat/completions';
        } else {
          finalUrl = '$url/v1/chat/completions';
        }
      }

      // 检测是否为 DeepSeek API
      final isDeepSeek = url.contains('deepseek');
      final model = isDeepSeek ? 'deepseek-chat' : 'gpt-3.5-turbo';

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

      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          // 解析 SSE 格式的数据
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (data == '[DONE]') {
                return;
              }
              try {
                final jsonData = jsonDecode(data);
                final content = jsonData['choices']?[0]?['delta']?['content'];
                if (content != null) {
                  yield content;
                }
              } catch (e) {
                // 忽略解析错误
              }
            }
          }
        }
      } else {
        throw Exception('API 请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('AI 聊天失败: $e');
    }
  }

  // 检查是否已配置 AI
  bool get isConfigured => _themeService.hasAiConfig;

  // 检查是否允许 AI 访问数据
  bool get canAccessData => _themeService.aiDataAccess;

  // 获取当前月的日记数据（用于 AI 分析）
  Future<String> getCurrentMonthDiaries() async {
    if (!canAccessData) {
      return '用户未授权 AI 访问日记数据';
    }

    try {
      final now = DateTime.now();
      final entries = await _storageService.getAllEntries();
      
      // 筛选当前月的日记
      final monthEntries = entries.where((entry) {
        return entry.date.year == now.year && entry.date.month == now.month;
      }).toList();

      // 按日期排序
      monthEntries.sort((a, b) => a.date.compareTo(b.date));

      if (monthEntries.isEmpty) {
        return '本月暂无日记记录';
      }

      // 格式化日记数据
      final buffer = StringBuffer();
      buffer.writeln('本月日记概览（${now.year}年${now.month}月）：');
      buffer.writeln('共 ${monthEntries.length} 篇日记');
      buffer.writeln('');

      for (final entry in monthEntries) {
        buffer.writeln('--- ${DateFormat('MM月dd日').format(entry.date)} ---');
        if (entry.mood != null) buffer.writeln('心情：${entry.mood}');
        if (entry.weather != null) buffer.writeln('天气：${entry.weather}');
        if (entry.breakfast != null) buffer.writeln('早餐：${entry.breakfast}');
        if (entry.lunch != null) buffer.writeln('午餐：${entry.lunch}');
        if (entry.dinner != null) buffer.writeln('晚餐：${entry.dinner}');
        if (entry.content.isNotEmpty) {
          buffer.writeln('内容：${entry.content.substring(0, entry.content.length > 100 ? 100 : entry.content.length)}${entry.content.length > 100 ? '...' : ''}');
        }
        buffer.writeln('');
      }

      return buffer.toString();
    } catch (e) {
      return '读取日记数据失败：$e';
    }
  }

  // 按日期范围获取日记
  Future<String> getDiariesByDateRange(DateTime start, DateTime end) async {
    if (!canAccessData) {
      return '用户未授权 AI 访问日记数据';
    }

    try {
      final entries = await _storageService.getAllEntries();
      
      // 筛选日期范围内的日记
      final filteredEntries = entries.where((entry) {
        final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
        final startDate = DateTime(start.year, start.month, start.day);
        final endDate = DateTime(end.year, end.month, end.day);
        return !entryDate.isBefore(startDate) && !entryDate.isAfter(endDate);
      }).toList();

      // 按日期排序
      filteredEntries.sort((a, b) => a.date.compareTo(b.date));

      if (filteredEntries.isEmpty) {
        return '${DateFormat('MM月dd日').format(start)} 至 ${DateFormat('MM月dd日').format(end)} 暂无日记记录';
      }

      // 格式化日记数据
      final buffer = StringBuffer();
      buffer.writeln('${DateFormat('MM月dd日').format(start)} 至 ${DateFormat('MM月dd日').format(end)} 的日记：');
      buffer.writeln('共 ${filteredEntries.length} 篇日记');
      buffer.writeln('');

      for (final entry in filteredEntries) {
        buffer.writeln('--- ${DateFormat('MM月dd日').format(entry.date)} ---');
        if (entry.mood != null) buffer.writeln('心情：${entry.mood}');
        if (entry.weather != null) buffer.writeln('天气：${entry.weather}');
        if (entry.content.isNotEmpty) {
          buffer.writeln('内容：${entry.content.substring(0, entry.content.length > 100 ? 100 : entry.content.length)}${entry.content.length > 100 ? '...' : ''}');
        }
        buffer.writeln('');
      }

      return buffer.toString();
    } catch (e) {
      return '读取日记数据失败：$e';
    }
  }

  // 按心情筛选日记
  Future<String> getDiariesByMood(String mood) async {
    if (!canAccessData) {
      return '用户未授权 AI 访问日记数据';
    }

    try {
      final entries = await _storageService.getAllEntries();
      
      // 筛选指定心情的日记
      final filteredEntries = entries.where((entry) {
        return entry.mood?.toLowerCase().contains(mood.toLowerCase()) ?? false;
      }).toList();

      // 按日期排序（最新的在前）
      filteredEntries.sort((a, b) => b.date.compareTo(a.date));

      if (filteredEntries.isEmpty) {
        return '没有找到心情为"$mood"的日记记录';
      }

      // 格式化日记数据
      final buffer = StringBuffer();
      buffer.writeln('心情为"$mood"的日记：');
      buffer.writeln('共 ${filteredEntries.length} 篇');
      buffer.writeln('');

      for (final entry in filteredEntries.take(10)) {
        buffer.writeln('--- ${DateFormat('yyyy年MM月dd日').format(entry.date)} ---');
        if (entry.weather != null) buffer.writeln('天气：${entry.weather}');
        if (entry.content.isNotEmpty) {
          buffer.writeln('内容：${entry.content.substring(0, entry.content.length > 80 ? 80 : entry.content.length)}${entry.content.length > 80 ? '...' : ''}');
        }
        buffer.writeln('');
      }

      if (filteredEntries.length > 10) {
        buffer.writeln('... 还有 ${filteredEntries.length - 10} 篇日记');
      }

      return buffer.toString();
    } catch (e) {
      return '读取日记数据失败：$e';
    }
  }

  // 按关键词搜索日记
  Future<String> searchDiaries(String keyword) async {
    if (!canAccessData) {
      return '用户未授权 AI 访问日记数据';
    }

    try {
      final entries = await _storageService.getAllEntries();
      
      // 搜索包含关键词的日记
      final filteredEntries = entries.where((entry) {
        final searchText = '${entry.title} ${entry.content} ${entry.mood ?? ''} ${entry.weather ?? ''} ${entry.breakfast ?? ''} ${entry.lunch ?? ''} ${entry.dinner ?? ''}';
        return searchText.toLowerCase().contains(keyword.toLowerCase());
      }).toList();

      // 按日期排序（最新的在前）
      filteredEntries.sort((a, b) => b.date.compareTo(a.date));

      if (filteredEntries.isEmpty) {
        return '没有找到包含"$keyword"的日记记录';
      }

      // 格式化日记数据
      final buffer = StringBuffer();
      buffer.writeln('包含"$keyword"的日记：');
      buffer.writeln('共 ${filteredEntries.length} 篇');
      buffer.writeln('');

      for (final entry in filteredEntries.take(10)) {
        buffer.writeln('--- ${DateFormat('yyyy年MM月dd日').format(entry.date)} ---');
        if (entry.mood != null) buffer.writeln('心情：${entry.mood}');
        if (entry.content.isNotEmpty) {
          buffer.writeln('内容：${entry.content.substring(0, entry.content.length > 80 ? 80 : entry.content.length)}${entry.content.length > 80 ? '...' : ''}');
        }
        buffer.writeln('');
      }

      if (filteredEntries.length > 10) {
        buffer.writeln('... 还有 ${filteredEntries.length - 10} 篇日记');
      }

      return buffer.toString();
    } catch (e) {
      return '搜索日记失败：$e';
    }
  }

  // 获取心情统计
  Future<String> getMoodStats(int days) async {
    if (!canAccessData) {
      return '用户未授权 AI 访问日记数据';
    }

    try {
      final entries = await _storageService.getAllEntries();
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      
      // 筛选日期范围内的日记
      final filteredEntries = entries.where((entry) {
        return entry.date.isAfter(startDate) || entry.date.isAtSameMomentAs(startDate);
      }).toList();

      if (filteredEntries.isEmpty) {
        return '最近 $days 天暂无日记记录';
      }

      // 统计心情分布
      final moodCounts = <String, int>{};
      for (final entry in filteredEntries) {
        if (entry.mood != null) {
          moodCounts[entry.mood!] = (moodCounts[entry.mood!] ?? 0) + 1;
        }
      }

      // 格式化统计结果
      final buffer = StringBuffer();
      buffer.writeln('最近 $days 天的心情统计：');
      buffer.writeln('共记录 ${filteredEntries.length} 篇日记');
      buffer.writeln('');

      if (moodCounts.isNotEmpty) {
        buffer.writeln('心情分布：');
        final sortedMoods = moodCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        for (final entry in sortedMoods) {
          final percentage = (entry.value / filteredEntries.length * 100).toStringAsFixed(1);
          buffer.writeln('  ${entry.key}：${entry.value} 天 ($percentage%)');
        }
      } else {
        buffer.writeln('暂无心情记录');
      }

      return buffer.toString();
    } catch (e) {
      return '统计心情失败：$e';
    }
  }

  // 获取饮食统计
  Future<String> getDietStats(int days) async {
    if (!canAccessData) {
      return '用户未授权 AI 访问日记数据';
    }

    try {
      final entries = await _storageService.getAllEntries();
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      
      // 筛选日期范围内的日记
      final filteredEntries = entries.where((entry) {
        return entry.date.isAfter(startDate) || entry.date.isAtSameMomentAs(startDate);
      }).toList();

      if (filteredEntries.isEmpty) {
        return '最近 $days 天暂无日记记录';
      }

      // 统计饮食记录
      int breakfastCount = 0;
      int lunchCount = 0;
      int dinnerCount = 0;
      int snacksCount = 0;

      for (final entry in filteredEntries) {
        if (entry.breakfast != null && entry.breakfast!.isNotEmpty) breakfastCount++;
        if (entry.lunch != null && entry.lunch!.isNotEmpty) lunchCount++;
        if (entry.dinner != null && entry.dinner!.isNotEmpty) dinnerCount++;
        if (entry.snacks != null && entry.snacks!.isNotEmpty) snacksCount++;
      }

      // 格式化统计结果
      final buffer = StringBuffer();
      buffer.writeln('最近 $days 天的饮食统计：');
      buffer.writeln('共记录 ${filteredEntries.length} 篇日记');
      buffer.writeln('');
      buffer.writeln('饮食记录情况：');
      buffer.writeln('  早餐：$breakfastCount 天');
      buffer.writeln('  午餐：$lunchCount 天');
      buffer.writeln('  晚餐：$dinnerCount 天');
      buffer.writeln('  零食/其他：$snacksCount 天');

      return buffer.toString();
    } catch (e) {
      return '统计饮食失败：$e';
    }
  }

  // 获取"去年今天"的日记
  Future<String> getDiaryOnSameDayLastYear() async {
    if (!canAccessData) {
      return '用户未授权 AI 访问日记数据';
    }

    try {
      final now = DateTime.now();
      final lastYear = DateTime(now.year - 1, now.month, now.day);
      
      final entries = await _storageService.getAllEntries();
      
      // 查找去年今天的日记
      final entry = entries.firstWhere(
        (e) => e.date.year == lastYear.year && e.date.month == lastYear.month && e.date.day == lastYear.day,
        orElse: () => throw Exception('未找到'),
      );

      // 格式化日记数据
      final buffer = StringBuffer();
      buffer.writeln('📅 去年今天（${DateFormat('yyyy年MM月dd日').format(lastYear)}）的日记：');
      buffer.writeln('');
      if (entry.mood != null) buffer.writeln('心情：${entry.mood}');
      if (entry.weather != null) buffer.writeln('天气：${entry.weather}');
      if (entry.breakfast != null) buffer.writeln('早餐：${entry.breakfast}');
      if (entry.lunch != null) buffer.writeln('午餐：${entry.lunch}');
      if (entry.dinner != null) buffer.writeln('晚餐：${entry.dinner}');
      if (entry.content.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('内容：');
        buffer.writeln(entry.content);
      }

      return buffer.toString();
    } catch (e) {
      final now = DateTime.now();
      final lastYear = DateTime(now.year - 1, now.month, now.day);
      return '去年今天（${DateFormat('yyyy年MM月dd日').format(lastYear)}）没有日记记录';
    }
  }

  // 获取最近 N 天的日记
  Future<String> getRecentDiaries(int days) async {
    if (!canAccessData) {
      return '用户未授权 AI 访问日记数据';
    }

    try {
      final entries = await _storageService.getAllEntries();
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      
      // 筛选最近 N 天的日记
      final filteredEntries = entries.where((entry) {
        return entry.date.isAfter(startDate) || entry.date.isAtSameMomentAs(startDate);
      }).toList();

      // 按日期排序（最新的在前）
      filteredEntries.sort((a, b) => b.date.compareTo(a.date));

      if (filteredEntries.isEmpty) {
        return '最近 $days 天暂无日记记录';
      }

      // 格式化日记数据
      final buffer = StringBuffer();
      buffer.writeln('最近 $days 天的日记：');
      buffer.writeln('共 ${filteredEntries.length} 篇');
      buffer.writeln('');

      for (final entry in filteredEntries) {
        buffer.writeln('--- ${DateFormat('MM月dd日').format(entry.date)} ---');
        if (entry.mood != null) buffer.writeln('心情：${entry.mood}');
        if (entry.weather != null) buffer.writeln('天气：${entry.weather}');
        if (entry.content.isNotEmpty) {
          buffer.writeln('内容：${entry.content.substring(0, entry.content.length > 100 ? 100 : entry.content.length)}${entry.content.length > 100 ? '...' : ''}');
        }
        buffer.writeln('');
      }

      return buffer.toString();
    } catch (e) {
      return '读取日记数据失败：$e';
    }
  }
}
