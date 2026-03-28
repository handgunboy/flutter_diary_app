import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/theme_service.dart' show ThemeService, ImageStorageMode, ThemeModeType;
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeService _themeService = ThemeService();
  final StorageService _storageService = StorageService();
  final TextEditingController _aiPromptController = TextEditingController();
  final TextEditingController _aiApiUrlController = TextEditingController();
  final TextEditingController _aiApiKeyController = TextEditingController();
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _aiPromptController.text = _themeService.aiPrompt;
    _aiApiUrlController.text = _themeService.aiApiUrl;
    _aiApiKeyController.text = _themeService.aiApiKey;
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    _aiPromptController.dispose();
    _aiApiUrlController.dispose();
    _aiApiKeyController.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<void> _saveAiPrompt() async {
    await _themeService.setAiPrompt(_aiPromptController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI提示词已保存')),
      );
    }
  }

  Future<void> _saveAiApiConfig() async {
    await _themeService.setAiApiConfig(
      _aiApiUrlController.text.trim(),
      _aiApiKeyController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API配置已保存')),
      );
    }
  }

  // 导出数据（包含图片的 ZIP 文件）
  Future<void> _exportData() async {
    try {
      // 显示进度提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正在打包数据，请稍候...')),
        );
      }
      
      final zipPath = await _storageService.exportDataWithImages();
      
      if (zipPath != null) {
        // 分享文件
        await Share.shareXFiles(
          [XFile(zipPath)],
          subject: '日记备份',
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: InkWell(
                onTap: () async {
                  // 打开文件所在文件夹
                  final file = File(zipPath);
                  if (await file.exists()) {
                    final result = await OpenFilex.open(zipPath);
                    if (result.type != ResultType.done) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('无法打开文件: ${result.message}')),
                      );
                    }
                  }
                },
                child: Text(
                  '数据已导出到: $zipPath\n点击查看文件',
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.yellow,
                  ),
                ),
              ),
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: '知道了',
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('导出失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('正在导入数据，请稍候...')),
            );
          }
          
          final success = await _storageService.importDataFromZip(result.files.single.path!);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? '数据导入成功' : '数据导入失败'),
              ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  String _getThemeModeText(ThemeModeType mode) {
    switch (mode) {
      case ThemeModeType.light:
        return '白天模式';
      case ThemeModeType.dark:
        return '黑夜模式';
      case ThemeModeType.system:
        return '跟随系统';
    }
  }

  IconData _getThemeModeIcon(ThemeModeType mode) {
    switch (mode) {
      case ThemeModeType.light:
        return Icons.light_mode;
      case ThemeModeType.dark:
        return Icons.dark_mode;
      case ThemeModeType.system:
        return Icons.brightness_auto;
    }
  }

  void _showThemeModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeModeType.values.map((mode) {
            return RadioListTile<ThemeModeType>(
              title: Row(
                children: [
                  Icon(_getThemeModeIcon(mode)),
                  const SizedBox(width: 12),
                  Text(_getThemeModeText(mode)),
                ],
              ),
              value: mode,
              groupValue: _themeService.themeMode,
              onChanged: (value) async {
                if (value != null) {
                  await _themeService.setThemeMode(value);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
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
            child: const Text('确定清除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storageService.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('所有数据已清除')),
        );
        // 刷新页面状态
        setState(() {});
      }
      // 返回 true 通知主页刷新
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 12, bottom: 12),
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
                padding: const EdgeInsets.all(16),
                children: [
          // 主题设置
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    _getThemeModeIcon(_themeService.themeMode),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('主题模式'),
                  subtitle: Text(_getThemeModeText(_themeService.themeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showThemeModeDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 图片存储模式设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.image,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '图片存储模式',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '选择日记图片的存储方式，影响导出功能',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStorageModeOption(
                          title: '复制到应用',
                          subtitle: '图片复制到应用文件夹，可完整导出',
                          icon: Icons.copy,
                          isSelected: _themeService.imageStorageMode == ImageStorageMode.copy,
                          onTap: () async {
                            await _themeService.setImageStorageMode(ImageStorageMode.copy);
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStorageModeOption(
                          title: '仅引用',
                          subtitle: '只保存图片路径，节省空间',
                          icon: Icons.link,
                          isSelected: _themeService.imageStorageMode == ImageStorageMode.reference,
                          onTap: () async {
                            await _themeService.setImageStorageMode(ImageStorageMode.reference);
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // AI API 配置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.api,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI API 配置',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_themeService.hasAiConfig)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                              const SizedBox(width: 4),
                              Text(
                                '已配置',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '配置 AI 服务的 API 地址和密钥，用于心情分析等功能',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _aiApiUrlController,
                    decoration: InputDecoration(
                      labelText: 'API 地址',
                      hintText: '例如：https://api.openai.com/v1/chat/completions',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _aiApiKeyController,
                    obscureText: _obscureApiKey,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: '输入你的 API 密钥',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureApiKey = !_obscureApiKey;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveAiApiConfig,
                      icon: const Icon(Icons.save),
                      label: const Text('保存 API 配置'),
                    ),
                  ),
                  const Divider(height: 24),
                  // AI 数据访问隐私开关
                  Row(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '允许 AI 访问日记数据',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '开启后，AI 可以读取您的日记内容，提供更个性化的建议',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _themeService.aiDataAccess,
                        onChanged: (value) async {
                          await _themeService.setAiDataAccess(value);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  if (_themeService.aiDataAccess) ...[
                    const Divider(height: 24),
                    // AI 功能说明
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI 可以帮您：',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildFeatureItem('📊 心情统计', '分析一段时间的心情分布'),
                              _buildFeatureItem('🍽️ 饮食回顾', '统计最近的饮食记录'),
                              _buildFeatureItem('🔍 关键词搜索', '搜索包含特定内容的日记'),
                              _buildFeatureItem('💭 心情筛选', '找出特定心情的日记'),
                              _buildFeatureItem('📅 日期查询', '查看指定日期范围的日记'),
                              _buildFeatureItem('📆 去年今天', '回顾去年今天的日记'),
                              _buildFeatureItem('📝 写作建议', '根据历史日记提供写作灵感'),
                              _buildFeatureItem('💡 智能分析', '基于数据给出生活建议'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
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
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.download,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('导出数据'),
                  subtitle: const Text('将日记数据和图片打包为 ZIP 文件'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.upload,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('导入数据'),
                  subtitle: const Text('从 ZIP 文件导入日记数据和图片'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _importData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 清除数据
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.delete_forever,
                    color: Colors.red[400],
                  ),
                  title: const Text('清除所有数据'),
                  subtitle: const Text('清除所有日记数据，此操作不可恢复'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _clearAllData,
                ),
              ],
            ),
          ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageModeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: ' - $description',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
