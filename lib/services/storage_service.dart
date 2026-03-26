import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary_entry.dart';
import '../models/favorite_item.dart';

class StorageService {
  static const String _diaryKey = 'diary_entries';
  static const String _initializedKey = 'diary_initialized';
  static const String _favoritesKey = 'favorite_items';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  Future<List<DiaryEntry>> getAllEntries() async {
    final prefs = await _prefs;
    final String? jsonString = prefs.getString(_diaryKey);

    if (jsonString == null) {
      // 首次使用，初始化测试数据
      await _initSampleData();
      return getAllEntries();
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => DiaryEntry.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _initSampleData() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 测试数据：今天、前几天、前两年的今天
    final sampleEntries = [
      // 今天的日记
      DiaryEntry(
        id: 'sample_today_1',
        date: today,
        title: '美好的一天',
        content: '今天是充实的一天，早上喝了杯咖啡，工作效率很高。下午去公园散步，看到了美丽的夕阳。心情很好！',
        breakfast: '豆浆、油条',
        lunch: '红烧肉、米饭',
        dinner: '蔬菜沙拉',
        snacks: '奶茶',
        mood: '开心',
        weather: '晴天',
        createdAt: today,
        updatedAt: today,
      ),
      DiaryEntry(
        id: 'sample_today_2',
        date: today,
        title: '工作感悟',
        content: '今天完成了一个重要的项目，感觉很有成就感。团队合作很顺利，大家都很给力。',
        breakfast: '牛奶、面包',
        lunch: '牛肉面',
        dinner: '寿司',
        mood: '幸福',
        weather: '多云',
        createdAt: today.add(const Duration(hours: -2)),
        updatedAt: today.add(const Duration(hours: -2)),
      ),

      // 前一天的日记
      DiaryEntry(
        id: 'sample_yesterday',
        date: today.subtract(const Duration(days: 1)),
        title: '昨天的回忆',
        content: '昨天和朋友聚餐，聊了很多有趣的话题。晚上回家看了部电影，很放松。',
        breakfast: '粥、咸菜',
        lunch: '火锅',
        dinner: '烧烤',
        snacks: '薯片',
        mood: '平静',
        weather: '阴天',
        createdAt: today.subtract(const Duration(days: 1)),
        updatedAt: today.subtract(const Duration(days: 1)),
      ),

      // 前两天的日记
      DiaryEntry(
        id: 'sample_2days_ago',
        date: today.subtract(const Duration(days: 2)),
        title: '周末时光',
        content: '周末去爬山了，虽然有点累但是风景很美。山顶的空气很清新，心情也变好了。',
        breakfast: '鸡蛋、牛奶',
        lunch: '三明治',
        dinner: '火锅',
        mood: '疲惫',
        weather: '晴天',
        createdAt: today.subtract(const Duration(days: 2)),
        updatedAt: today.subtract(const Duration(days: 2)),
      ),

      // 前三天的日记
      DiaryEntry(
        id: 'sample_3days_ago',
        date: today.subtract(const Duration(days: 3)),
        title: ' rainy day',
        content: '今天下雨了，在家看书听音乐。这样的天气很适合宅在家里，泡一杯热茶。',
        breakfast: '燕麦粥',
        lunch: '泡面',
        dinner: '外卖',
        snacks: '巧克力',
        mood: '平静',
        weather: '下雨',
        createdAt: today.subtract(const Duration(days: 3)),
        updatedAt: today.subtract(const Duration(days: 3)),
      ),

      // 前四年的今天
      DiaryEntry(
        id: 'sample_1year_ago',
        date: DateTime(today.year - 1, today.month, today.day),
        title: '一年前的今天',
        content: '一年前的今天，我在准备一个重要考试。每天都在努力学习，虽然辛苦但是值得。',
        breakfast: '包子、豆浆',
        lunch: '快餐',
        dinner: '家常菜',
        mood: '焦虑',
        weather: '多云',
        createdAt: DateTime(today.year - 1, today.month, today.day),
        updatedAt: DateTime(today.year - 1, today.month, today.day),
      ),

      // 前两年的今天
      DiaryEntry(
        id: 'sample_2years_ago',
        date: DateTime(today.year - 2, today.month, today.day),
        title: '两年前的回忆',
        content: '两年前的今天，第一次去海边旅行。海风吹在脸上，海浪拍打着沙滩，那种感觉至今难忘。',
        breakfast: '酒店早餐',
        lunch: '海鲜大餐',
        dinner: '烧烤',
        snacks: '椰子汁',
        mood: '开心',
        weather: '晴天',
        createdAt: DateTime(today.year - 2, today.month, today.day),
        updatedAt: DateTime(today.year - 2, today.month, today.day),
      ),

      // 前三年的今天
      DiaryEntry(
        id: 'sample_3years_ago',
        date: DateTime(today.year - 3, today.month, today.day),
        title: '三年前的故事',
        content: '三年前的今天，刚入职新公司。一切都那么新鲜，认识了很多新同事，学到了很多东西。',
        breakfast: '面包',
        lunch: '公司食堂',
        dinner: '和同事聚餐',
        mood: '开心',
        weather: '晴天',
        createdAt: DateTime(today.year - 3, today.month, today.day),
        updatedAt: DateTime(today.year - 3, today.month, today.day),
      ),

      // 前四年的今天
      DiaryEntry(
        id: 'sample_4years_ago',
        date: DateTime(today.year - 4, today.month, today.day),
        title: '四年前的今天',
        content: '四年前的今天，大学毕业典礼。和同学们告别，大家都各奔东西了。怀念那段青春时光。',
        breakfast: '宿舍泡面',
        lunch: '散伙饭',
        dinner: 'KTV snacks',
        snacks: '啤酒',
        mood: '难过',
        weather: '阴天',
        createdAt: DateTime(today.year - 4, today.month, today.day),
        updatedAt: DateTime(today.year - 4, today.month, today.day),
      ),
    ];

    final prefs = await _prefs;
    final jsonList = sampleEntries.map((e) => e.toJson()).toList();
    await prefs.setString(_diaryKey, jsonEncode(jsonList));
    await prefs.setBool(_initializedKey, true);
  }

  Future<void> saveEntry(DiaryEntry entry) async {
    final prefs = await _prefs;
    final entries = await getAllEntries();
    
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      entries[index] = entry;
    } else {
      entries.add(entry);
    }
    
    entries.sort((a, b) => b.date.compareTo(a.date));
    
    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_diaryKey, jsonEncode(jsonList));
  }

  Future<void> deleteEntry(String id) async {
    final prefs = await _prefs;
    final entries = await getAllEntries();
    
    entries.removeWhere((e) => e.id == id);
    
    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_diaryKey, jsonEncode(jsonList));
  }

  Future<DiaryEntry?> getEntryByDate(DateTime date) async {
    final entries = await getAllEntries();
    try {
      return entries.firstWhere(
        (e) => _isSameDay(e.date, date),
      );
    } catch (e) {
      return null;
    }
  }

  Future<List<DiaryEntry>> getEntriesByMonth(DateTime month) async {
    final entries = await getAllEntries();
    return entries.where((e) => 
      e.date.year == month.year && e.date.month == month.month
    ).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ========== 收藏夹功能 ==========

  Future<List<FavoriteItem>> getAllFavorites() async {
    final prefs = await _prefs;
    final String? jsonString = prefs.getString(_favoritesKey);

    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => FavoriteItem.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveFavorite(FavoriteItem item) async {
    final prefs = await _prefs;
    final items = await getAllFavorites();

    final index = items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final jsonList = items.map((i) => i.toJson()).toList();
    await prefs.setString(_favoritesKey, jsonEncode(jsonList));
  }

  Future<void> deleteFavorite(String id) async {
    final prefs = await _prefs;
    final items = await getAllFavorites();

    items.removeWhere((i) => i.id == id);

    final jsonList = items.map((i) => i.toJson()).toList();
    await prefs.setString(_favoritesKey, jsonEncode(jsonList));
  }

  Future<List<FavoriteItem>> getFavoritesByType(String type) async {
    final items = await getAllFavorites();
    return items.where((i) => i.type == type).toList();
  }

  Future<List<FavoriteItem>> searchFavorites(String keyword) async {
    final items = await getAllFavorites();
    final lowerKeyword = keyword.toLowerCase();
    return items.where((i) {
      final contentMatch = i.content?.toLowerCase().contains(lowerKeyword) ?? false;
      final sourceMatch = i.source?.toLowerCase().contains(lowerKeyword) ?? false;
      final tagMatch = i.tags.any((tag) => tag.toLowerCase().contains(lowerKeyword));
      return contentMatch || sourceMatch || tagMatch;
    }).toList();
  }

  // ========== 日记收藏功能 ==========

  Future<void> toggleFavorite(String entryId) async {
    final prefs = await _prefs;
    final entries = await getAllEntries();
    
    final index = entries.indexWhere((e) => e.id == entryId);
    if (index >= 0) {
      entries[index] = entries[index].copyWith(
        isFavorite: !entries[index].isFavorite,
      );
      
      final jsonList = entries.map((e) => e.toJson()).toList();
      await prefs.setString(_diaryKey, jsonEncode(jsonList));
    }
  }

  Future<List<DiaryEntry>> getFavoriteEntries() async {
    final entries = await getAllEntries();
    return entries.where((e) => e.isFavorite).toList();
  }

  Future<void> clearAllData() async {
    final prefs = await _prefs;
    await prefs.remove(_diaryKey);
    await prefs.remove(_favoritesKey);
    await prefs.remove(_initializedKey);
  }
}
