import 'dart:developer' as developer;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:path_provider/path_provider.dart';

/// WebDAV 备份服务
///
/// 功能：
/// 1. 配置管理 - 保存 WebDAV 服务器信息
/// 2. 测试连接 - 验证配置是否正确
/// 3. 备份到 WebDAV - 上传 ZIP 文件
/// 4. 从 WebDAV 恢复 - 下载 ZIP 文件
class WebdavService {
  static final WebdavService _instance = WebdavService._internal();
  factory WebdavService() => _instance;
  WebdavService._internal();

  static const String _keyUrl = 'webdav_url';
  static const String _keyUsername = 'webdav_username';
  static const String _keyPassword = 'webdav_password';
  static const String _keyRemotePath = 'webdav_remote_path';

  webdav.Client? _client;

  /// 获取 WebDAV URL
  Future<String?> getUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUrl);
  }

  /// 获取用户名
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  /// 获取密码
  Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPassword);
  }

  /// 获取远程路径（默认 /diary_backup/）
  Future<String> getRemotePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRemotePath) ?? '/diary_backup/';
  }

  /// 保存配置
  Future<void> saveConfig({
    required String url,
    required String username,
    required String password,
    String? remotePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUrl, url);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyPassword, password);
    if (remotePath != null) {
      await prefs.setString(_keyRemotePath, remotePath);
    }
    // 清除缓存的客户端
    _client = null;
    developer.log('💾 WebDAV 配置已保存', name: 'WebdavService');
  }

  /// 清除配置
  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUrl);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyRemotePath);
    _client = null;
    developer.log('🗑️ WebDAV 配置已清除', name: 'WebdavService');
  }

  /// 检查是否已配置
  Future<bool> isConfigured() async {
    final url = await getUrl();
    final username = await getUsername();
    final password = await getPassword();
    return url != null && url.isNotEmpty && username != null && password != null;
  }

  /// 初始化客户端
  Future<webdav.Client> _getClient() async {
    if (_client != null) return _client!;

    final url = await getUrl();
    final username = await getUsername();
    final password = await getPassword();

    if (url == null || username == null || password == null) {
      throw Exception('WebDAV 未配置，请先在设置中配置');
    }

    _client = webdav.newClient(
      url,
      user: username,
      password: password,
    );

    // 设置超时（毫秒）
    _client!.setConnectTimeout(10000);
    _client!.setSendTimeout(60000);
    _client!.setReceiveTimeout(60000);

    developer.log('🔌 WebDAV 客户端已初始化: $url', name: 'WebdavService');
    return _client!;
  }

  /// 测试连接
  Future<bool> testConnection() async {
    try {
      developer.log('🔍 测试 WebDAV 连接...', name: 'WebdavService');
      final client = await _getClient();
      await client.ping();
      developer.log('✅ WebDAV 连接成功', name: 'WebdavService');
      return true;
    } catch (e) {
      developer.log('❌ WebDAV 连接失败: $e', name: 'WebdavService');
      rethrow;
    }
  }

  /// 使用临时配置测试连接（不保存到 SharedPreferences）
  Future<bool> testConnectionWithConfig({
    required String url,
    required String username,
    required String password,
  }) async {
    try {
      developer.log('🔍 测试 WebDAV 连接（临时配置）...', name: 'WebdavService');
      
      final client = webdav.newClient(
        url,
        user: username,
        password: password,
      );

      // 设置超时（毫秒）
      client.setConnectTimeout(10000);
      client.setSendTimeout(60000);
      client.setReceiveTimeout(60000);

      await client.ping();
      developer.log('✅ WebDAV 连接成功', name: 'WebdavService');
      return true;
    } catch (e) {
      developer.log('❌ WebDAV 连接失败: $e', name: 'WebdavService');
      rethrow;
    }
  }

  /// 确保远程目录存在
  Future<void> _ensureRemoteDir(String remoteDir) async {
    final client = await _getClient();
    try {
      await client.mkdir(remoteDir);
      developer.log('📁 远程目录已创建: $remoteDir', name: 'WebdavService');
    } catch (e) {
      // 目录可能已存在，忽略错误
      developer.log('📁 远程目录可能已存在: $e', name: 'WebdavService');
    }
  }

  /// 备份到 WebDAV
  /// [zipFilePath] 本地 ZIP 文件路径
  /// [remoteFileName] 远程文件名（可选，默认使用时间戳）
  Future<void> backupToWebdav({
    required String zipFilePath,
    String? remoteFileName,
  }) async {
    try {
      developer.log('📤 开始备份到 WebDAV...', name: 'WebdavService');
      
      final client = await _getClient();
      final remoteDir = await getRemotePath();
      await _ensureRemoteDir(remoteDir);

      final fileName = remoteFileName ?? 'diary_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
      final remotePath = '$remoteDir$fileName';

      final file = File(zipFilePath);
      if (!await file.exists()) {
        throw Exception('本地 ZIP 文件不存在: $zipFilePath');
      }

      final bytes = await file.readAsBytes();
      await client.write(remotePath, bytes);

      developer.log('✅ 备份成功: $remotePath', name: 'WebdavService');
    } catch (e) {
      developer.log('❌ 备份失败: $e', name: 'WebdavService');
      rethrow;
    }
  }

  /// 从 WebDAV 恢复
  /// 返回下载的 ZIP 文件本地路径
  Future<String> restoreFromWebdav({String? remoteFileName}) async {
    try {
      developer.log('📥 开始从 WebDAV 恢复...', name: 'WebdavService');
      
      final client = await _getClient();
      final remoteDir = await getRemotePath();

      // 如果未指定文件名，获取最新的备份文件
      final fileName = remoteFileName ?? await _getLatestBackup(client, remoteDir);
      final remotePath = '$remoteDir$fileName';

      // 下载文件到临时目录
      final tempDir = await getTemporaryDirectory();
      final localPath = '${tempDir.path}/webdav_restore_${DateTime.now().millisecondsSinceEpoch}.zip';
      
      final bytes = await client.read(remotePath);
      final file = File(localPath);
      await file.writeAsBytes(bytes);

      developer.log('✅ 恢复成功: $localPath', name: 'WebdavService');
      return localPath;
    } catch (e) {
      developer.log('❌ 恢复失败: $e', name: 'WebdavService');
      rethrow;
    }
  }

  /// 获取最新的备份文件
  Future<String> _getLatestBackup(webdav.Client client, String remoteDir) async {
    try {
      final files = await client.readDir(remoteDir);
      final zipFiles = files
          .where((f) => f.name?.endsWith('.zip') == true)
          .toList();

      if (zipFiles.isEmpty) {
        throw Exception('远程目录没有找到备份文件');
      }

      // 按文件名排序（时间戳）
      zipFiles.sort((a, b) {
        final nameA = a.name ?? '';
        final nameB = b.name ?? '';
        return nameB.compareTo(nameA); // 降序
      });

      final latest = zipFiles.first.name ?? '';
      developer.log('📄 找到最新备份: $latest', name: 'WebdavService');
      return latest;
    } catch (e) {
      developer.log('❌ 获取备份列表失败: $e', name: 'WebdavService');
      rethrow;
    }
  }

  /// 列出所有备份文件
  Future<List<Map<String, dynamic>>> listBackups() async {
    try {
      final client = await _getClient();
      final remoteDir = await getRemotePath();
      
      final files = await client.readDir(remoteDir);
      final zipFiles = files
          .where((f) => f.name?.endsWith('.zip') == true)
          .map((f) {
            final name = f.name ?? '';
            // 从文件名解析时间戳：diary_backup_1234567890.zip 或 diary_data_1234567890.zip
            DateTime? parsedTime;
            final match = RegExp(r'(\d{10,})').firstMatch(name);
            if (match != null) {
              final timestamp = int.tryParse(match.group(1)!);
              if (timestamp != null) {
                parsedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
              }
            }
            
            return {
              'name': name,
              'size': f.size ?? 0,
              'modified': parsedTime ?? DateTime.now(),
              'type': name.contains('data_') ? '仅数据' : '完整',
            };
          })
          .toList();

      // 按时间降序
      zipFiles.sort((a, b) {
        return (b['modified'] as DateTime).compareTo(a['modified'] as DateTime);
      });

      return zipFiles;
    } catch (e) {
      developer.log('❌ 获取备份列表失败: $e', name: 'WebdavService');
      return [];
    }
  }
}
