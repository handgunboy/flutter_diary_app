import 'package:intl/intl.dart';
import 'storage_service.dart';

class DiaryQueryService {
  final StorageService _storageService;

  DiaryQueryService(this._storageService);

  /// 获取当前月的日记数据
  Future<String> getCurrentMonthDiaries() async {
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

  /// 按日期范围获取日记
  Future<String> getDiariesByDateRange(DateTime start, DateTime end) async {
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

  /// 按心情筛选日记
  Future<String> getDiariesByMood(String mood) async {
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

  /// 按关键词搜索日记
  Future<String> searchDiaries(String keyword) async {
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

  /// 获取心情统计
  Future<String> getMoodStats(int days) async {
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

  /// 获取饮食统计
  Future<String> getDietStats(int days) async {
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

  /// 获取"去年今天"的日记
  Future<String> getDiaryOnSameDayLastYear() async {
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

  /// 获取最近 N 天的日记
  Future<String> getRecentDiaries(int days) async {
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