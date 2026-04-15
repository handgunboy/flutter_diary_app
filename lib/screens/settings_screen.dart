import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../services/theme_service.dart' show ThemeService;
import '../services/storage_service.dart';
import '../services/webdav_service.dart';
import '../widgets/app_ui.dart';
import '../widgets/app_top_toast.dart';
import '../widgets/settings_action_group_card.dart';
import '../widgets/settings_ai_section.dart';
import '../widgets/settings_storage_mode_section.dart';
import '../widgets/settings_theme_mode_dialog.dart' show ThemeModeUi;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeService _themeService = ThemeService();
  final StorageService _storageService = StorageService();
  final WebdavService _webdavService = WebdavService();
  final TextEditingController _aiApiUrlController = TextEditingController();
  final TextEditingController _aiApiKeyController = TextEditingController();
  // WebDAV 配置控制器
  final TextEditingController _webdavUrlController = TextEditingController();
  final TextEditingController _webdavUsernameController = TextEditingController();
  final TextEditingController _webdavPasswordController = TextEditingController();
  bool _obscureApiKey = true;
  bool _obscureWebdavPassword = true;
  bool _webdavConfigured = false;

  @override
  void initState() {
    super.initState();
    _aiApiUrlController.text = _themeService.aiApiUrl;
    _aiApiKeyController.text = _themeService.aiApiKey;
    _themeService.addListener(_onThemeChanged);
    _loadWebdavConfig();
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    _aiApiUrlController.dispose();
    _aiApiKeyController.dispose();
    _webdavUrlController.dispose();
    _webdavUsernameController.dispose();
    _webdavPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadWebdavConfig() async {
    final isConfigured = await _webdavService.isConfigured();
    final url = await _webdavService.getUrl();
    final username = await _webdavService.getUsername();
    final password = await _webdavService.getPassword();
    if (mounted) {
      setState(() {
        _webdavConfigured = isConfigured;
        _webdavUrlController.text = url ?? '';
        _webdavUsernameController.text = username ?? '';
        _webdavPasswordController.text = password ?? '';
      });
    }
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _saveAiApiConfig() async {
    await _themeService.setAiApiConfig(
      _aiApiUrlController.text.trim(),
      _aiApiKeyController.text.trim(),
    );
    if (mounted) {
      AppTopToast.show(context, 'API配置已保存');
    }
  }

  // 导出数据（包含图片的 ZIP 文件）
  Future<void> _exportData() async {
    try {
      // 显示进度提示
      if (mounted) {
        AppTopToast.show(context, '正在打包数据，请稍候...');
      }
      
      final zipPath = await _storageService.exportDataWithImages();
      
      if (zipPath != null) {
        // 分享文件
        await Share.shareXFiles(
          [XFile(zipPath)],
          subject: '日记备份',
        );
        
        if (mounted) {
          AppTopToast.show(context, '导出成功，已唤起分享');
        }
      } else {
        if (mounted) {
          AppTopToast.show(context, '导出失败', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        AppTopToast.show(context, '导出失败: $e', isError: true);
      }
    }
  }

  // 导入数据（ZIP 文件，包含图片）
  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (!mounted) return;
      
      if (result != null && result.files.single.path != null) {
        // 确认导入
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认导入'),
            content: const Text('导入数据会合并到现有日记中，相同 ID 的日记会被覆盖。图片会被解压到应用目录。是否继续？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('导入'),
              ),
            ],
          ),
        );
        
        if (confirmed == true) {
          if (mounted) {
            AppTopToast.show(context, '正在导入数据，请稍候...');
          }
          
          final success = await _storageService.importDataFromZip(result.files.single.path!);
          
          if (mounted) {
            AppTopToast.show(
              context,
              success ? '数据导入成功' : '数据导入失败',
              isError: !success,
            );
            
            // 如果导入成功，返回 true 通知主页刷新
            if (success) {
              Navigator.pop(context, true);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppTopToast.show(context, '导入失败: $e', isError: true);
      }
    }
  }

  // WebDAV 相关方法
  Future<void> _saveWebdavConfig() async {
    final url = _webdavUrlController.text.trim();
    final username = _webdavUsernameController.text.trim();
    final password = _webdavPasswordController.text.trim();

    if (url.isEmpty || username.isEmpty || password.isEmpty) {
      if (mounted) {
        AppTopToast.show(context, '请填写完整的 WebDAV 配置', isError: true);
      }
      return;
    }

    await _webdavService.saveConfig(
      url: url,
      username: username,
      password: password,
    );

    if (mounted) {
      setState(() {
        _webdavConfigured = true;
      });
      AppTopToast.show(context, 'WebDAV 配置已保存');
    }
  }

  Future<void> _testWebdavConnection() async {
    final url = _webdavUrlController.text.trim();
    final username = _webdavUsernameController.text.trim();
    final password = _webdavPasswordController.text.trim();

    if (url.isEmpty || username.isEmpty || password.isEmpty) {
      if (mounted) {
        AppTopToast.show(context, '请先填写完整的 WebDAV 配置', isError: true);
      }
      return;
    }

    if (!mounted) return;
    AppTopToast.show(context, '正在测试连接...');

    try {
      // 使用临时配置测试连接
      final success = await _webdavService.testConnectionWithConfig(
        url: url,
        username: username,
        password: password,
      );
      if (mounted) {
        AppTopToast.show(context, success ? '连接成功' : '连接失败');
      }
    } catch (e) {
      if (mounted) {
        AppTopToast.show(context, '连接失败: $e', isError: true);
      }
    }
  }

  Future<void> _backupToWebdav({bool includeImages = true}) async {
    if (!_webdavConfigured) {
      if (mounted) {
        AppTopToast.show(context, '请先配置 WebDAV', isError: true);
      }
      return;
    }

    if (!mounted) return;

    try {
      // 显示进度对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildProgressDialog(
          includeImages ? '正在准备完整备份（含图片）...' : '正在准备数据备份...',
        ),
      );

      // 导出数据（可选是否含图片）
      final zipPath = includeImages
          ? await _storageService.exportDataWithImages()
          : await _storageService.exportDataOnly();
      
      if (zipPath == null) {
        if (mounted) {
          Navigator.pop(context);
          AppTopToast.show(context, '备份数据准备失败', isError: true);
        }
        return;
      }

      if (!mounted) return;

      // 更新进度
      Navigator.pop(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildProgressDialog('正在上传到 WebDAV...'),
      );

      // 上传到 WebDAV
      await _webdavService.backupToWebdav(zipFilePath: zipPath);

      if (mounted) {
        Navigator.pop(context);
        AppTopToast.show(context, includeImages ? '完整备份成功' : '数据备份成功');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        AppTopToast.show(context, '备份失败: $e', isError: true);
      }
    }
  }

  Future<void> _restoreFromWebdav() async {
    if (!_webdavConfigured) {
      if (mounted) {
        AppTopToast.show(context, '请先配置 WebDAV', isError: true);
      }
      return;
    }

    if (!mounted) return;

    try {
      // 获取备份列表
      AppTopToast.show(context, '正在获取备份列表...');
      final backups = await _webdavService.listBackups();
      
      if (!mounted) return;
      
      if (backups.isEmpty) {
        AppTopToast.show(context, '云端没有找到备份文件', isError: true);
        return;
      }

      // 显示备份选择对话框
      final selectedBackup = await _showBackupSelectionDialog(backups);
      if (!mounted) return;
      if (selectedBackup == null) return; // 用户取消

      // 确认恢复
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认恢复'),
          content: Text('将从云端恢复备份"${selectedBackup['name']}"到本地，相同 ID 的日记会被覆盖。是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('恢复'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      if (!mounted) return;

      // 显示进度对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildProgressDialog('正在下载备份文件...'),
      );

      // 从 WebDAV 下载指定备份
      final zipPath = await _webdavService.restoreFromWebdav(
        remoteFileName: selectedBackup['name'] as String,
      );

      if (!mounted) return;

      // 更新进度 - 安全关闭对话框
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // 关闭下载进度
      }
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildProgressDialog('正在导入数据...'),
      );

      // 导入数据
      final success = await _storageService.importDataFromZip(zipPath);

      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // 关闭导入进度
        }
        AppTopToast.show(context, success ? '恢复成功' : '恢复失败', isError: !success);
        if (success && Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        // 确保关闭任何打开的对话框
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        AppTopToast.show(context, '恢复失败: $e', isError: true);
      }
    }
  }

  Future<Map<String, dynamic>?> _showBackupSelectionDialog(
    List<Map<String, dynamic>> backups,
  ) async {
    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择要恢复的备份'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: backups.length,
            itemBuilder: (context, index) {
              final backup = backups[index];
              final name = backup['name'] as String;
              final size = backup['size'] as int;
              final time = backup['modified'] as DateTime;
              final type = backup['type'] as String;

              // 格式化大小
              String sizeStr;
              if (size < 1024) {
                sizeStr = '$size B';
              } else if (size < 1024 * 1024) {
                sizeStr = '${(size / 1024).toStringAsFixed(1)} KB';
              } else {
                sizeStr = '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
              }

              return ListTile(
                leading: Icon(
                  type == '完整' ? Icons.backup : Icons.description,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(name),
                subtitle: Text('$type · $sizeStr · ${time.toString().split('.').first}'),
                onTap: () => Navigator.pop(context, backup),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDialog(String message) {
    return AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }

  void _showWebdavConfigDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('WebDAV 配置'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _webdavUrlController,
                  decoration: const InputDecoration(
                    labelText: '服务器地址',
                    hintText: 'https://example.com/dav/',
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: AppUi.itemGap),
                TextField(
                  controller: _webdavUsernameController,
                  decoration: const InputDecoration(
                    labelText: '用户名',
                  ),
                ),
                const SizedBox(height: AppUi.itemGap),
                TextField(
                  controller: _webdavPasswordController,
                  decoration: InputDecoration(
                    labelText: '密码',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureWebdavPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureWebdavPassword = !_obscureWebdavPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureWebdavPassword,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _testWebdavConnection,
                    icon: const Icon(Icons.wifi, size: 18),
                    label: const Text('测试连接'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                _saveWebdavConfig();
                Navigator.pop(dialogContext);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: AppUi.headerPadding,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    tooltip: '返回',
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '设置',
                    style: GoogleFonts.righteous(
                      fontSize: 28,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: AppUi.pagePadding,
                children: [
          // 主题设置
          Card(
            child: ListTile(
              leading: Icon(
                ThemeModeUi.icon(_themeService.themeMode),
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('主题模式'),
              onTap: () => _themeService.cycleThemeMode(),
            ),
          ),
          const SizedBox(height: AppUi.sectionGap),

          // 图片存储模式设置
          SettingsStorageModeSection(
            selectedMode: _themeService.imageStorageMode,
            onModeSelected: (mode) async {
              await _themeService.setImageStorageMode(mode);
              if (!mounted) return;
              setState(() {});
            },
          ),
          const SizedBox(height: AppUi.sectionGap),

          // AI API 配置
          SettingsAiSection(
            apiUrlController: _aiApiUrlController,
            apiKeyController: _aiApiKeyController,
            obscureApiKey: _obscureApiKey,
            onToggleObscureApiKey: () {
              setState(() {
                _obscureApiKey = !_obscureApiKey;
              });
            },
            onSaveApiConfig: _saveAiApiConfig,
            hasAiConfig: _themeService.hasAiConfig,
            aiDataAccess: _themeService.aiDataAccess,
            onAiDataAccessChanged: (value) async {
              await _themeService.setAiDataAccess(value);
              if (!mounted) return;
              setState(() {});
            },
          ),
          const SizedBox(height: 16),

          // // AI提示词设置 - 暂时用不到，已注释
          // Card(
          //   child: Padding(
          //     padding: const EdgeInsets.all(16),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         Row(
          //           children: [
          //             Icon(
          //               Icons.psychology,
          //               color: Theme.of(context).colorScheme.primary,
          //             ),
          //             const SizedBox(width: 8),
          //             Text(
          //               'AI提示词',
          //               style: Theme.of(context).textTheme.titleMedium?.copyWith(
          //                 fontWeight: FontWeight.bold,
          //               ),
          //             ),
          //           ],
          //         ),
          //         const SizedBox(height: 8),
          //         Text(
          //           '设置AI生成日记时的提示词，可以帮助AI更好地理解你的需求',
          //           style: TextStyle(
          //             fontSize: 12,
          //             color: Colors.grey[600],
          //           ),
          //         ),
          //         const SizedBox(height: 12),
          //         TextField(
          //           controller: _aiPromptController,
          //           maxLines: 5,
          //           decoration: InputDecoration(
          //             hintText: '例如：请帮我润色这段日记，使其更加生动有趣...',
          //             border: OutlineInputBorder(
          //               borderRadius: BorderRadius.circular(8),
          //             ),
          //           ),
          //         ),
          //         const SizedBox(height: 12),
          //         SizedBox(
          //           width: double.infinity,
          //           child: ElevatedButton.icon(
          //             onPressed: _saveAiPrompt,
          //             icon: const Icon(Icons.save),
          //             label: const Text('保存提示词'),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 16),

          // 数据导入导出
          SettingsActionGroupCard(
            items: [
              SettingsActionItem(
                icon: Icons.download,
                title: '导出数据',
                subtitle: '将日记数据和图片打包为 ZIP 文件',
                onTap: _exportData,
              ),
              SettingsActionItem(
                icon: Icons.upload,
                title: '导入数据',
                subtitle: '从 ZIP 文件导入日记数据和图片',
                onTap: _importData,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // WebDAV 云备份
          SettingsActionGroupCard(
            items: [
              SettingsActionItem(
                icon: Icons.cloud,
                title: 'WebDAV 配置',
                subtitle: _webdavConfigured ? '已配置，点击修改' : '未配置',
                onTap: _showWebdavConfigDialog,
              ),
              SettingsActionItem(
                icon: Icons.backup,
                title: '完整备份到 WebDAV',
                subtitle: '包含日记数据和所有图片',
                onTap: () => _backupToWebdav(includeImages: true),
              ),
              SettingsActionItem(
                icon: Icons.description,
                title: '仅数据备份到 WebDAV',
                subtitle: '仅包含日记数据，不含图片（更快）',
                onTap: () => _backupToWebdav(includeImages: false),
              ),
              SettingsActionItem(
                icon: Icons.restore,
                title: '从 WebDAV 恢复',
                subtitle: '从云存储恢复数据',
                onTap: _restoreFromWebdav,
              ),
            ],
          ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
