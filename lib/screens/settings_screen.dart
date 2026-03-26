import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/theme_service.dart';
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
      }
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
}
