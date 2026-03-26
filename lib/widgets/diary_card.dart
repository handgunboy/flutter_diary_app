import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../models/diary_entry.dart';

class DiaryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onDelete;
  final bool showDate;

  const DiaryCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onDelete,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.title.isEmpty ? '无标题' : entry.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (entry.mood != null)
                    _buildTag(context, entry.mood!),
                  if (entry.weather != null)
                    _buildTag(context, entry.weather!),
                  IconButton(
                    icon: Icon(
                      entry.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      color: entry.isFavorite ? Colors.grey[700] : Colors.grey[600],
                      size: 20,
                    ),
                    onPressed: onToggleFavorite,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey[600], size: 20),
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
                  child: _buildMealInfo(entry),
                ),
              Text(
                entry.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[700],
                  height: 1.4,
                ),
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
                        color: Colors.grey[500],
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

  Widget _buildTag(BuildContext context, String label) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  bool _hasMealInfo(DiaryEntry entry) {
    return entry.breakfast != null || 
           entry.lunch != null || 
           entry.dinner != null || 
           entry.snacks != null;
  }

  Widget _buildMealInfo(DiaryEntry entry) {
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
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant, size: 16, color: Colors.orange[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              meals.join(' | '),
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[800],
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
    final imagesToShow = entry.images.take(3).toList();
    final hasMore = entry.images.length > 3;

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imagesToShow.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: index < imagesToShow.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _DiaryCardImageGallery(
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
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(imagesToShow[index]),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.broken_image, color: Colors.grey[500]),
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
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '+${entry.images.length - 3}',
                          style: const TextStyle(
                            color: Colors.white,
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

class _DiaryCardImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _DiaryCardImageGallery({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_DiaryCardImageGallery> createState() => _DiaryCardImageGalleryState();
}

class _DiaryCardImageGalleryState extends State<_DiaryCardImageGallery> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: FileImage(File(widget.images[index])),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
              );
            },
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
