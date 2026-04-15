import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../services/theme_service.dart' show ThemeService;
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_ui.dart';
import '../widgets/app_top_toast.dart';
import '../widgets/settings_action_group_card.dart';
import '../widgets/settings_ai_section.dart';
import '../widgets/settings_storage_mode_section.dart';
import '../widgets/settings_theme_mode_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeService _themeService = ThemeService();
  final StorageService _storageService = StorageService();
  final TextEditingController _aiApiUrlController = TextEditingController();
  final TextEditingController _aiApiKeyController = TextEditingController();
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _aiApiUrlController.text = _themeService.aiApiUrl;
    _aiApiKeyController.text = _themeService.aiApiKey;
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    _aiApiUrlController.dispose();
    _aiApiKeyController.dispose();
    super.dispose();
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

  void _showThemeModeDialog() {
    showDialog(
      context: context,
      builder: (_) => SettingsThemeModeDialog(
        selectedMode: _themeService.themeMode,
        onModeSelected: (mode) => _themeService.setThemeMode(mode),
      ),
    );
  }

  Future<void> _clearAllData() async {
    final colors = AppColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除所有数据？'),
        content: const Text('此操作将清除所有日记数据，且无法恢复！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('确定清除', style: TextStyle(color: colors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storageService.clearAllData();
      if (!mounted) return;
      AppTopToast.show(context, '所有数据已清除');
      // 刷新页面状态
      setState(() {});
      // 返回 true 通知主页刷新
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
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
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    ThemeModeUi.icon(_themeService.themeMode),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('主题模式'),
                  subtitle: Text(ThemeModeUi.text(_themeService.themeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showThemeModeDialog,
                ),
              ],
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

          // 通知测试
          SettingsActionGroupCard(
            items: [
              SettingsActionItem(
                icon: Icons.notifications,
                title: '测试通知',
                subtitle: '发送一条测试通知',
                onTap: _testNotification,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 清除数据
          SettingsActionGroupCard(
            items: [
              SettingsActionItem(
                icon: Icons.delete_forever,
                iconColor: colors.danger,
                title: '清除所有数据',
                subtitle: '清除所有日记数据，此操作不可恢复',
                onTap: _clearAllData,
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

  Future<void> _testNotification() async {
    final notificationService = NotificationService();
    await notificationService.showDiaryReminder();
    
    if (mounted) {
      AppTopToast.show(context, '测试通知已发送');
    }
  }
}
