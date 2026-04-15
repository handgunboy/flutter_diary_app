import 'package:flutter/material.dart';

import '../services/theme_service.dart' show ThemeModeType;

class ThemeModeUi {
  const ThemeModeUi._();

  static String text(ThemeModeType mode) {
    switch (mode) {
      case ThemeModeType.light:
        return '白天模式';
      case ThemeModeType.dark:
        return '黑夜模式';
      case ThemeModeType.system:
        return '跟随系统';
    }
  }

  static IconData icon(ThemeModeType mode) {
    switch (mode) {
      case ThemeModeType.light:
        return Icons.light_mode;
      case ThemeModeType.dark:
        return Icons.dark_mode;
      case ThemeModeType.system:
        return Icons.brightness_auto;
    }
  }
}

class SettingsThemeModeDialog extends StatelessWidget {
  final ThemeModeType selectedMode;
  final Future<void> Function(ThemeModeType mode) onModeSelected;

  const SettingsThemeModeDialog({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择主题模式'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ThemeModeType.values.map((mode) {
          return RadioListTile<ThemeModeType>(
            title: Row(
              children: [
                Icon(ThemeModeUi.icon(mode)),
                const SizedBox(width: 12),
                Text(ThemeModeUi.text(mode)),
              ],
            ),
            value: mode,
            groupValue: selectedMode,
            onChanged: (value) async {
              if (value == null) return;
              await onModeSelected(value);
              if (!context.mounted) return;
              Navigator.pop(context);
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
    );
  }
}
