import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import '../theme/app_colors.dart';
import 'app_ui.dart';
import 'image_gallery_screen.dart';
import 'mood_icons.dart';

class DiaryCard extends StatelessWidget {
  // LRU 缓存限制，防止内存泄漏
  static const int _maxCacheSize = 100;
  static final Map<String, File> _imageFileCache = {};
  static final List<String> _accessOrder = [];  // 访问顺序用于 LRU

  static File _getCachedFile(String path) {
    // 如果已存在，更新访问顺序
    if (_imageFileCache.containsKey(path)) {
      _accessOrder.remove(path);
      _accessOrder.add(path);
      return _imageFileCache[path]!;
    }

    // 如果缓存满了，移除最久未访问的
    if (_imageFileCache.length >= _maxCacheSize && _accessOrder.isNotEmpty) {
      final oldestKey = _accessOrder.removeAt(0);
      _imageFileCache.remove(oldestKey);
    }

    // 添加到缓存
    final file = File(path);
    _imageFileCache[path] = file;
    _accessOrder.add(path);
    return file;
  }

  final DiaryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;
  final bool showDate;
  final String searchQuery;

  const DiaryCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onDelete,
    this.showDate = false,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppUi.itemGap),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppUi.mediumRadius,
        child: Padding(
          padding: AppUi.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (entry.mood != null)
                    _buildMoodTag(context, entry.mood!),
                  if (entry.weather != null)
                    _buildWeatherTag(context, entry.weather!),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: AppUi.mutedIcon(context), size: 20),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_hasMealInfo(entry))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildMealInfo(context, entry),
                ),
              _buildHighlightedText(
                context,
                entry.content,
                searchQuery,
                maxLines: 3,
              ),
              if (entry.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildImagePreview(context),
              ],
              if (showDate) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      DateFormat('yyyy年MM月dd日').format(entry.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppUi.mutedText(context),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodTag(BuildContext context, String mood) {
    final colors = AppColors.of(context);
    final icon = MoodIcons.getIcon(mood);
    final textColor = colors.textSecondary;
    final borderColor = colors.outline;
    final isHighlighted = searchQuery.isNotEmpty && mood.toLowerCase().contains(searchQuery.toLowerCase());

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHighlighted ? colors.danger : borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isHighlighted ? colors.danger : textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            mood,
            style: TextStyle(
              fontSize: 12,
              color: isHighlighted ? colors.danger : textColor,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherTag(BuildContext context, String weather) {
    final colors = AppColors.of(context);
    final icon = WeatherIcons.getIcon(weather);
    final textColor = colors.textSecondary;
    final borderColor = colors.outline;
    final isHighlighted = searchQuery.isNotEmpty && weather.toLowerCase().contains(searchQuery.toLowerCase());

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHighlighted ? colors.danger : borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isHighlighted ? colors.danger : textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            weather,
            style: TextStyle(
              fontSize: 12,
              color: isHighlighted ? colors.danger : textColor,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    String query, {
    int maxLines = 3,
  }) {
    final colors = AppColors.of(context);
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppUi.mutedText(context),
          height: 1.4,
        ),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final List<TextSpan> spans = [];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(
            text: text.substring(start),
            style: TextStyle(
              color: AppUi.mutedText(context),
              height: 1.4,
            ),
          ));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: TextStyle(
            color: AppUi.mutedText(context),
            height: 1.4,
          ),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          color: colors.danger,
          height: 1.4,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }

  bool _hasMealInfo(DiaryEntry entry) {
    return entry.breakfast != null ||
           entry.lunch != null ||
           entry.dinner != null ||
           entry.snacks != null;
  }

  Widget _buildMealInfo(BuildContext context, DiaryEntry entry) {
    final colors = AppColors.of(context);
    final meals = <String>[];
    if (entry.breakfast != null && entry.breakfast!.isNotEmpty) {
      meals.add('早: ${entry.breakfast}');
    }
    if (entry.lunch != null && entry.lunch!.isNotEmpty) {
      meals.add('午: ${entry.lunch}');
    }
    if (entry.dinner != null && entry.dinner!.isNotEmpty) {
      meals.add('晚: ${entry.dinner}');
    }
    if (entry.snacks != null && entry.snacks!.isNotEmpty) {
      meals.add('零食: ${entry.snacks}');
    }

    if (meals.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.warningBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant, size: 16, color: colors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              meals.join(' | '),
              style: TextStyle(
                fontSize: 12,
                color: colors.warning,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    final colors = AppColors.of(context);
    final imagesToShow = entry.images.take(3).toList();
    final hasMore = entry.images.length > 3;

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imagesToShow.length,
        itemBuilder: (context, index) {
          final imagePath = imagesToShow[index];
          final imageFile = _getCachedFile(imagePath);
          return Padding(
            padding: EdgeInsets.only(right: index < imagesToShow.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageGalleryScreen(
                      images: entry.images,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              child: Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.outline),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        imageFile,
                        fit: BoxFit.cover,
                        cacheWidth: 160,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: colors.imagePlaceholderStrong,
                            child: Icon(Icons.broken_image, color: colors.iconMuted),
                          );
                        },
                      ),
                    ),
                  ),
                  if (index == 2 && hasMore)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colors.scrim.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '+${entry.images.length - 3}',
                          style: TextStyle(
                            color: colors.actionPrimaryForeground,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
