import 'package:flutter/material.dart';

import '../services/theme_service.dart' show ImageStorageMode;
import '../theme/app_colors.dart';
import 'app_ui.dart';

class SettingsStorageModeSection extends StatelessWidget {
  final ImageStorageMode selectedMode;
  final ValueChanged<ImageStorageMode> onModeSelected;

  const SettingsStorageModeSection({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppUi.cardPadding,
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
                color: AppUi.mutedText(context),
              ),
            ),
            const SizedBox(height: AppUi.itemGap),
            Row(
              children: [
                Expanded(
                  child: _StorageModeOption(
                    title: '复制到应用',
                    subtitle: '图片复制到应用文件夹，可完整导出',
                    icon: Icons.copy,
                    isSelected: selectedMode == ImageStorageMode.copy,
                    onTap: () => onModeSelected(ImageStorageMode.copy),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StorageModeOption(
                    title: '仅引用',
                    subtitle: '只保存图片路径，节省空间',
                    icon: Icons.link,
                    isSelected: selectedMode == ImageStorageMode.reference,
                    onTap: () => onModeSelected(ImageStorageMode.reference),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageModeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _StorageModeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : AppUi.subtleSurface(context),
          borderRadius: AppUi.mediumRadius,
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
                  : colors.textMuted,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
