import 'dart:io';
import 'dart:ui' show lerpDouble;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'image_gallery_screen.dart';
import '../theme/app_colors.dart';
import 'app_ui.dart';

class WriteDiaryTopExtras extends StatelessWidget {
  static final Map<String, File> _imageFileCache = {};

  final ValueListenable<List<String>> imagesListenable;
  final VoidCallback onPickImages;
  final VoidCallback onFieldTap;
  final void Function(int oldIndex, int newIndex) onReorderImages;
  final void Function(int index) onDeleteImageAt;
  final TextEditingController breakfastController;
  final TextEditingController lunchController;
  final TextEditingController dinnerController;
  final TextEditingController moodController;
  final TextEditingController weatherController;
  final TextEditingController weightController;

  const WriteDiaryTopExtras({
    super.key,
    required this.imagesListenable,
    required this.onPickImages,
    required this.onFieldTap,
    required this.onReorderImages,
    required this.onDeleteImageAt,
    required this.breakfastController,
    required this.lunchController,
    required this.dinnerController,
    required this.moodController,
    required this.weatherController,
    required this.weightController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildMealSection()),
            const SizedBox(width: 12),
            Expanded(child: _buildMoodAndWeatherSectionCompact()),
          ],
        ),
        const SizedBox(height: 12),
        _buildImageSection(context),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildMealSection() {
    return Card(
      child: Padding(
        padding: AppUi.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMealInput(
              controller: breakfastController,
              label: '早餐',
              icon: Icons.wb_sunny_outlined,
              hint: '豆浆、油条',
            ),
            const SizedBox(height: 6),
            _buildMealInput(
              controller: lunchController,
              label: '午餐',
              icon: Icons.wb_sunny,
              hint: '红烧肉、米饭',
            ),
            const SizedBox(height: 6),
            _buildMealInput(
              controller: dinnerController,
              label: '晚餐',
              icon: Icons.nights_stay_outlined,
              hint: '蔬菜沙拉',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodAndWeatherSectionCompact() {
    return Card(
      child: Padding(
        padding: AppUi.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMealInput(
              controller: moodController,
              label: '心情',
              icon: Icons.mood,
              hint: '开心',
            ),
            const SizedBox(height: 6),
            _buildMealInput(
              controller: weatherController,
              label: '天气',
              icon: Icons.wb_sunny,
              hint: '晴天',
            ),
            const SizedBox(height: 6),
            _buildMealInput(
              controller: weightController,
              label: '体重',
              icon: Icons.monitor_weight,
              hint: '60.5',
              suffixText: 'kg',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    String? suffixText,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      onTap: onFieldTap,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        suffixText: suffixText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        isDense: true,
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final colors = AppColors.of(context);

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
                  size: 18,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '照片',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    onFieldTap();
                    onPickImages();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppUi.subtleSurface(context),
                      borderRadius: AppUi.smallRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 14,
                          color: colors.iconMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '添加照片',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppUi.mutedText(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ValueListenableBuilder<List<String>>(
              valueListenable: imagesListenable,
              builder: (context, images, _) {
                if (images.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ReorderableListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        buildDefaultDragHandles: true,
                        proxyDecorator: (child, index, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              final animValue = Curves.easeInOut.transform(
                                animation.value,
                              );
                              final elevation = lerpDouble(0, 6, animValue)!;
                              return Material(
                                elevation: elevation,
                                color: Colors.transparent,
                                child: child,
                              );
                            },
                            child: child,
                          );
                        },
                        itemBuilder: (context, index) {
                          return _buildImageThumbnail(
                            context: context,
                            images: images,
                            index: index,
                            path: images[index],
                          );
                        },
                        onReorder: onReorderImages,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail({
    required BuildContext context,
    required List<String> images,
    required int index,
    required String path,
  }) {
    final colors = AppColors.of(context);
    final file = _imageFileCache.putIfAbsent(path, () => File(path));

    return Container(
      key: ValueKey(path),
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _showFullScreenImage(context, images, index),
            child: Hero(
              tag: 'image_$path',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.outlineStrong),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                    cacheWidth: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.broken_image,
                          color: colors.iconMuted,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFullScreenImage(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGalleryScreen(
          images: List<String>.from(images),
          initialIndex: initialIndex,
          onDelete: onDeleteImageAt,
          canDelete: true,
        ),
      ),
    );
  }
}
