import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary_entry.dart';
import '../models/favorite_item.dart';

class StorageService {
  static const String _diaryKey = 'diary_entries';
  static const String _initializedKey = 'diary_initialized';
  static const String _favoritesKey = 'favorite_items';
  static const String _dataClearedKey = 'data_cleared'; // 标记数据是否被手动清除

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // 获取所有未删除的日记（正常列表）
  Future<List<DiaryEntry>> getAllEntries() async {
    final prefs = await _prefs;
    final String? jsonString = prefs.getString(_diaryKey);

    if (jsonString == null) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final entries = jsonList.map((json) => DiaryEntry.fromJson(json)).toList();
      // 只返回未删除的日记
      return entries.where((e) => e.deletedAt == null).toList();
    } catch (e) {
      return [];
    }
  }

  // 获取所有日记（包括已删除的，用于回收站）
  Future<List<DiaryEntry>> _getAllEntriesIncludingDeleted() async {
    final prefs = await _prefs;
    final String? jsonString = prefs.getString(_diaryKey);

    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => DiaryEntry.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // 获取回收站中的日记
  Future<List<DiaryEntry>> getDeletedEntries() async {
    final entries = await _getAllEntriesIncludingDeleted();
    return entries.where((e) => e.deletedAt != null).toList();
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

  // 软删除日记
  Future<void> deleteEntry(String id) async {
    final prefs = await _prefs;
    final entries = await _getAllEntriesIncludingDeleted();

    final index = entries.indexWhere((e) => e.id == id);
    if (index >= 0) {
      entries[index] = entries[index].copyWith(
        deletedAt: DateTime.now(),
      );

      final jsonList = entries.map((e) => e.toJson()).toList();
      await prefs.setString(_diaryKey, jsonEncode(jsonList));
    }
  }

  // 恢复日记
  Future<void> restoreEntry(String id) async {
    final prefs = await _prefs;
    final entries = await _getAllEntriesIncludingDeleted();

    final index = entries.indexWhere((e) => e.id == id);
    if (index >= 0) {
      entries[index] = entries[index].copyWith(
        deletedAt: null,
      );

      final jsonList = entries.map((e) => e.toJson()).toList();
      await prefs.setString(_diaryKey, jsonEncode(jsonList));
    }
  }

  // 永久删除日记
  Future<void> permanentlyDeleteEntry(String id) async {
    final prefs = await _prefs;
    final entries = await _getAllEntriesIncludingDeleted();

    entries.removeWhere((e) => e.id == id);

    final jsonList = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_diaryKey, jsonEncode(jsonList));
  }

  // 清理超过30天的已删除日记
  Future<void> cleanupOldDeletedEntries() async {
    final prefs = await _prefs;
    final entries = await _getAllEntriesIncludingDeleted();
    final now = DateTime.now();

    entries.removeWhere((e) {
      if (e.deletedAt == null) return false;
      final daysSinceDeleted = now.difference(e.deletedAt!).inDays;
      return daysSinceDeleted >= 30;
    });

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
    // 设置数据已清除标记，防止自动重新初始化测试数据
    await prefs.setBool(_dataClearedKey, true);
    
    // 清除应用目录下的图片文件夹
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      
      // 删除 images 文件夹
      final Directory imagesDir = Directory('${appDir.path}/images');
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }
      
      // 删除 imported_images 文件夹
      final Directory importedImagesDir = Directory('${appDir.path}/imported_images');
      if (await importedImagesDir.exists()) {
        await importedImagesDir.delete(recursive: true);
      }
    } catch (e) {
      print('清除图片文件夹失败: $e');
    }
  }

  // 复制图片到应用目录
  Future<String?> copyImageToAppDirectory(String sourcePath) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = '${appDir.path}/images';
      
      // 创建 images 目录（如果不存在）
      final Directory dir = Directory(imagesDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // 生成唯一文件名
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${sourcePath.split('/').last.split('\\').last}';
      final String destPath = '$imagesDir/$fileName';
      
      // 复制文件
      final File sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(destPath);
        return destPath;
      }
      return null;
    } catch (e) {
      print('复制图片失败: $e');
      return null;
    }
  }

  // 导出所有日记数据为 ZIP（包含图片）
  Future<String?> exportDataWithImages() async {
    try {
      final entries = await _getAllEntriesIncludingDeleted();
      
      // 收集所有图片路径
      final List<String> allImages = [];
      for (var entry in entries) {
        allImages.addAll(entry.images);
      }
      final uniqueImages = allImages.toSet().toList();
      
      // 创建数据 JSON
      final data = {
        'version': '1.0',
        'exportTime': DateTime.now().toIso8601String(),
        'entries': entries.map((e) => e.toJson()).toList(),
        'images': uniqueImages,
      };
      
      // 创建 ZIP 文件
      final archive = Archive();
      
      // 添加数据文件
      final jsonBytes = utf8.encode(jsonEncode(data));
      archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));
      
      // 添加图片文件
      for (var imagePath in uniqueImages) {
        final file = File(imagePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final fileName = imagePath.split('/').last.split('\\').last;
          archive.addFile(ArchiveFile('images/$fileName', bytes.length, bytes));
        }
      }
      
      // 编码 ZIP
      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes == null) return null;
      
      // 保存到临时文件
      final tempDir = await getTemporaryDirectory();
      final fileName = 'diary_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
      final zipPath = '${tempDir.path}/$fileName';
      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipBytes);
      
      return zipPath;
    } catch (e) {
      print('导出数据失败: $e');
      return null;
    }
  }

  // 导入 ZIP 文件（包含数据和图片）
  Future<bool> importDataFromZip(String zipPath) async {
    try {
      print('开始导入 ZIP: $zipPath');
      
      final zipFile = File(zipPath);
      if (!await zipFile.exists()) {
        print('ZIP 文件不存在');
        return false;
      }
      
      final bytes = await zipFile.readAsBytes();
      print('ZIP 文件大小: ${bytes.length} bytes');
      
      final archive = ZipDecoder().decodeBytes(bytes);
      print('ZIP 包含 ${archive.length} 个文件');
      
      // 找到数据文件
      ArchiveFile? dataFile;
      final List<ArchiveFile> imageFiles = [];
      
      for (var file in archive) {
        print('ZIP 中的文件: ${file.name}');
        if (file.name == 'data.json') {
          dataFile = file;
        } else if (file.name.startsWith('images/')) {
          imageFiles.add(file);
        }
      }
      
      if (dataFile == null) {
        print('未找到 data.json 文件');
        return false;
      }
      
      print('找到 ${imageFiles.length} 张图片');
      
      // 解析数据
      final jsonString = utf8.decode(dataFile.content);
      final data = jsonDecode(jsonString);
      
      // 获取应用目录
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/imported_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      // 解压图片
      final Map<String, String> pathMapping = {}; // 旧路径 -> 新路径
      for (var imageFile in imageFiles) {
        final fileName = imageFile.name.split('/').last;
        final newPath = '${imagesDir.path}/$fileName';
        final file = File(newPath);
        await file.writeAsBytes(imageFile.content);
        pathMapping[fileName] = newPath;
      }
      
      // 更新日记中的图片路径
      final List<dynamic> entriesJson = data['entries'];
      for (var entryJson in entriesJson) {
        final List<dynamic> oldImages = entryJson['images'] ?? [];
        final List<String> newImages = [];
        for (var oldPath in oldImages) {
          final fileName = oldPath.split('/').last.split('\\').last;
          if (pathMapping.containsKey(fileName)) {
            newImages.add(pathMapping[fileName]!);
          } else {
            // 如果图片不在 ZIP 中，保留原路径（可能是引用模式）
            newImages.add(oldPath);
          }
        }
        entryJson['images'] = newImages;
      }
      
      // 导入数据
      return await importData(data);
    } catch (e) {
      print('导入 ZIP 失败: $e');
      return false;
    }
  }

  // 导入日记数据
  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      final prefs = await _prefs;
      
      // 验证数据格式
      if (!data.containsKey('entries')) {
        print('导入失败：数据格式不正确，缺少 entries 字段');
        return false;
      }
      
      final List<dynamic> entriesJson = data['entries'];
      print('正在导入 ${entriesJson.length} 条日记');
      
      final List<DiaryEntry> newEntries = entriesJson
          .map((json) => DiaryEntry.fromJson(json))
          .toList();
      
      // 获取现有数据
      final existingEntries = await _getAllEntriesIncludingDeleted();
      
      // 合并数据（根据 ID 去重，新数据覆盖旧数据）
      final Map<String, DiaryEntry> entryMap = {};
      for (var entry in existingEntries) {
        entryMap[entry.id] = entry;
      }
      for (var entry in newEntries) {
        entryMap[entry.id] = entry;
      }
      
      // 保存合并后的数据
      final jsonList = entryMap.values.map((e) => e.toJson()).toList();
      await prefs.setString(_diaryKey, jsonEncode(jsonList));
      
      // 清除数据已清除标记，因为现在有数据了
      await prefs.remove(_dataClearedKey);
      
      print('导入成功，共 ${entryMap.length} 条日记');
      return true;
    } catch (e) {
      print('导入数据失败: $e');
      return false;
    }
  }
}
