import 'dart:async';
import 'dart:io';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/diary_entry.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../services/theme_service.dart' show ThemeService, ImageStorageMode;
import '../widgets/image_gallery_screen.dart';
import 'settings_screen.dart';

class WriteDiaryScreen extends StatefulWidget {
  final DateTime selectedDate;
  final DiaryEntry? existingEntry;

  const WriteDiaryScreen({
    super.key,
    required this.selectedDate,
    this.existingEntry,
  });

  @override
  State<WriteDiaryScreen> createState() => _WriteDiaryScreenState();
}

class _WriteDiaryScreenState extends State<WriteDiaryScreen> {
  final StorageService _storageService = StorageService();
  final AiService _aiService = AiService();
  final ThemeService _themeService = ThemeService();
  late final _contentController = _TimeHighlightController();
  final _breakfastController = TextEditingController();
  final _lunchController = TextEditingController();
  final _dinnerController = TextEditingController();
  final _snacksController = TextEditingController();
  final _moodController = TextEditingController();
  final _weatherController = TextEditingController();
  final _weightController = TextEditingController();
  final _summaryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _contentFieldKey = GlobalKey();
  bool _isLoading = false;
  bool _isAiParsing = false;

  List<String> _images = []; // 日记图片列表

  // 保存初始状态，用于检查是否有变更
  String _initialContent = '';
  String _initialBreakfast = '';
  String _initialLunch = '';
  String _initialDinner = '';
  String _initialSnacks = '';
  String _initialMood = '';
  String _initialWeather = '';
  String _initialWeight = '';
  List<String> _initialImages = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _contentController.text = widget.existingEntry!.content;
      _breakfastController.text = widget.existingEntry!.breakfast ?? '';
      _lunchController.text = widget.existingEntry!.lunch ?? '';
      _dinnerController.text = widget.existingEntry!.dinner ?? '';
      _snacksController.text = widget.existingEntry!.snacks ?? '';
      _moodController.text = widget.existingEntry!.mood ?? '';
      _weatherController.text = widget.existingEntry!.weather ?? '';
      _weightController.text = widget.existingEntry!.weight ?? '';
      _images = List<String>.from(widget.existingEntry!.images);
      
      // 保存初始状态
      _initialContent = widget.existingEntry!.content;
      _initialBreakfast = widget.existingEntry!.breakfast ?? '';
      _initialLunch = widget.existingEntry!.lunch ?? '';
      _initialDinner = widget.existingEntry!.dinner ?? '';
      _initialSnacks = widget.existingEntry!.snacks ?? '';
      _initialMood = widget.existingEntry!.mood ?? '';
      _initialWeather = widget.existingEntry!.weather ?? '';
      _initialWeight = widget.existingEntry!.weight ?? '';
      _initialImages = List<String>.from(widget.existingEntry!.images);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _breakfastController.dispose();
    _lunchController.dispose();
    _dinnerController.dispose();
    _snacksController.dispose();
    _moodController.dispose();
    _weatherController.dispose();
    _weightController.dispose();
    _summaryController.dispose();
    _onChangeDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _parseWithAi() async {
    if (_summaryController.text.trim().isEmpty) {
      _showSnackBar('请先输入日记总结');
      return;
    }

    if (!_themeService.hasAiConfig) {
      _showSnackBar('请先配置 AI API');
      return;
    }

    setState(() => _isAiParsing = true);

    try {
      final result = await _aiService.parseDiary(_summaryController.text.trim());
      
      if (result != null) {
        setState(() {
          if (result['breakfast'] != null) {
            _breakfastController.text = result['breakfast'];
          }
          if (result['lunch'] != null) {
            _lunchController.text = result['lunch'];
          }
          if (result['dinner'] != null) {
            _dinnerController.text = result['dinner'];
          }
          if (result['snacks'] != null) {
            _snacksController.text = result['snacks'];
          }
          if (result['mood'] != null) {
            _moodController.text = result['mood'];
          }
          if (result['weather'] != null) {
            _weatherController.text = result['weather'];
          }
          if (result['weight'] != null) {
            _weightController.text = result['weight'];
          }
          if (result['content'] != null) {
            _contentController.text = result['content'];
          }
        });

        if (mounted) {
          _showSnackBar('AI 解析完成，请检查并保存');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('AI 解析失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isAiParsing = false);
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final storageMode = _themeService.imageStorageMode;
        
        for (var image in images) {
          if (!_images.contains(image.path)) {
            if (storageMode == ImageStorageMode.copy) {
              // 复制到应用文件夹
              final copiedPath = await _storageService.copyImageToAppDirectory(image.path);
              if (copiedPath != null) {
                setState(() {
                  _images.add(copiedPath);
                });
              } else {
                if (mounted) {
                  _showSnackBar('复制图片失败: ${image.path}');
                }
              }
            } else {
              // 仅保存引用
              setState(() {
                _images.add(image.path);
              });
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('选择图片失败: $e');
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 12, bottom: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
            tooltip: '返回',
          ),
          const SizedBox(width: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${widget.selectedDate.year}',
                style: GoogleFonts.righteous(
                  fontSize: 28,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '年',
                style: GoogleFonts.righteous(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '${widget.selectedDate.month}',
                style: GoogleFonts.righteous(
                  fontSize: 28,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '月',
                style: GoogleFonts.righteous(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '${widget.selectedDate.day}',
                style: GoogleFonts.righteous(
                  fontSize: 28,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '日',
                style: GoogleFonts.righteous(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveDiary,
            tooltip: '保存日记',
          ),
        ],
      ),
    );
  }

  Widget _buildAiSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_fix_high,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI 智能填写',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_themeService.hasAiConfig)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          '已配置',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('去配置'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '输入日记总结，AI 会自动解析并填写下面的表单',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _summaryController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '例如：今天天气晴朗，早上吃了豆浆油条，中午和朋友吃了火锅，心情很开心...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAiParsing ? null : _parseWithAi,
                icon: _isAiParsing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: Text(_isAiParsing ? 'AI 解析中...' : 'AI 自动填写'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasChanges() {
    if (widget.existingEntry == null) {
      // 新建日记，只要有内容就算有变更
      return _contentController.text.trim().isNotEmpty ||
             _breakfastController.text.trim().isNotEmpty ||
             _lunchController.text.trim().isNotEmpty ||
             _dinnerController.text.trim().isNotEmpty ||
             _snacksController.text.trim().isNotEmpty ||
             _moodController.text.trim().isNotEmpty ||
             _weatherController.text.trim().isNotEmpty ||
             _weightController.text.trim().isNotEmpty ||
             _images.isNotEmpty;
    } else {
      // 编辑日记，检查是否有变更
      return _contentController.text != _initialContent ||
             _breakfastController.text != _initialBreakfast ||
             _lunchController.text != _initialLunch ||
             _dinnerController.text != _initialDinner ||
             _snacksController.text != _initialSnacks ||
             _moodController.text != _initialMood ||
             _weatherController.text != _initialWeather ||
             _weightController.text != _initialWeight ||
             !_listEquals(_images, _initialImages);
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _handleBack() async {
    if (!_hasChanges()) {
      Navigator.pop(context);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未保存的修改'),
        content: const Text('你有未保存的修改，确定要离开吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('离开', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveDiary() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final content = _contentController.text.trim();
      // 自动生成标题：取内容前10个字，如果没有内容则使用日期
      final title = content.isEmpty
          ? '${widget.selectedDate.month}月${widget.selectedDate.day}日的日记'
          : (content.length > 10 ? content.substring(0, 10) : content);

      final entry = DiaryEntry(
        id: widget.existingEntry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        date: widget.selectedDate,
        title: title,
        content: content,
        breakfast: _breakfastController.text.trim().isEmpty ? null : _breakfastController.text.trim(),
        lunch: _lunchController.text.trim().isEmpty ? null : _lunchController.text.trim(),
        dinner: _dinnerController.text.trim().isEmpty ? null : _dinnerController.text.trim(),
        snacks: _snacksController.text.trim().isEmpty ? null : _snacksController.text.trim(),
        mood: _moodController.text.trim().isEmpty ? null : _moodController.text.trim(),
        weather: _weatherController.text.trim().isEmpty ? null : _weatherController.text.trim(),
        weight: _weightController.text.trim().isEmpty ? null : _weightController.text.trim(),
        images: _images,
        createdAt: widget.existingEntry?.createdAt ?? now,
        updatedAt: now,
        isFavorite: widget.existingEntry?.isFavorite ?? false,
      );

      await _storageService.saveEntry(entry);

      if (mounted) {
        _showSnackBar('日记保存成功');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('保存失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
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
                  onTap: _pickImages,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('添加照片', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  // 使用 const 构造函数减少重建
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        final double animValue = Curves.easeInOut.transform(animation.value);
                        final double elevation = lerpDouble(0, 6, animValue)!;
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
                    return _buildImageThumbnail(index);
                  },
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final item = _images.removeAt(oldIndex);
                      _images.insert(newIndex, item);
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(int initialIndex) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGalleryScreen(
          images: _images,
          initialIndex: initialIndex,
          onDelete: (index) {
            // 实时更新缩略图
            setState(() {
              _images.removeAt(index);
            });
          },
        ),
      ),
    );
    
    // 如果返回了删除信息，确保状态已更新
    if (result != null && result is Map && result.containsKey('deletedIndex')) {
      final deletedIndex = result['deletedIndex'] as int;
      if (!_images.contains(result['deletedPath'])) {
        // 已经通过 onDelete 回调删除了
      }
    }
  }

  // 图片文件缓存，避免重复读取
  final Map<String, File> _imageFileCache = {};

  Widget _buildImageThumbnail(int index) {
    final path = _images[index];

    // 从缓存获取 File 对象
    final file = _imageFileCache.putIfAbsent(path, () => File(path));

    return Container(
      key: ValueKey(path),
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _showFullScreenImage(index),
            child: Hero(
              tag: 'image_$path', // 使用 path 作为 tag 更稳定
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                    cacheWidth: 200, // 限制缓存大小，减少内存占用
                    cacheHeight: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, color: Colors.grey[500]),
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

  Widget _buildMealSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMealInput(
              controller: _breakfastController,
              label: '早餐',
              icon: Icons.wb_sunny_outlined,
              hint: '豆浆、油条',
            ),
            const SizedBox(height: 6),
            _buildMealInput(
              controller: _lunchController,
              label: '午餐',
              icon: Icons.wb_sunny,
              hint: '红烧肉、米饭',
            ),
            const SizedBox(height: 6),
            _buildMealInput(
              controller: _dinnerController,
              label: '晚餐',
              icon: Icons.nights_stay_outlined,
              hint: '蔬菜沙拉',
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
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        isDense: true,
      ),
    );
  }

  Widget _buildMoodAndWeatherSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sentiment_satisfied, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  '今天怎么样',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _moodController,
              decoration: InputDecoration(
                labelText: '心情',
                hintText: '例如：开心、平静、焦虑...',
                prefixIcon: Icon(Icons.mood, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weatherController,
              decoration: InputDecoration(
                labelText: '天气',
                hintText: '例如：晴天、多云、下雨...',
                prefixIcon: Icon(Icons.wb_sunny, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 日期卡片
  Widget _buildDateSection() {
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[widget.selectedDate.weekday - 1];
    final dateStr = DateFormat('MM/dd').format(widget.selectedDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(
                  '日期',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    weekday,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
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

  // 紧凑版天气心情（用于双列布局）
  Widget _buildMoodAndWeatherSectionCompact() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _moodController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                labelText: '心情',
                hintText: '开心',
                prefixIcon: Icon(Icons.mood, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _weatherController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                labelText: '天气',
                hintText: '晴天',
                prefixIcon: Icon(Icons.wb_sunny, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _weightController,
              style: const TextStyle(fontSize: 13),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '体重',
                hintText: '60.5',
                prefixIcon: Icon(Icons.monitor_weight, size: 18),
                suffixText: 'kg',
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _lastValue;
  // 用于节流 onChanged 的定时器
  Timer? _onChangeDebounceTimer;

  // 显示全屏日记编辑对话框
  void _showFullScreenEditor() async {
    // 首次点击且内容为空时，添加当前时间
    if (_contentController.text.isEmpty) {
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _contentController.text = '$timeStr ';
      _lastValue = _contentController.text;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _buildFullScreenEditor(),
      ),
    );
  }

  // 构建全屏编辑器
  Widget _buildFullScreenEditor() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        title: const Text(
          '编辑日记',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('完成'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 编辑区域 - 从底部开始显示
          Expanded(
            child: SingleChildScrollView(
              reverse: true, // 从底部开始显示
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: _contentController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '记录今天的故事...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.bottom, // 从底部对齐
                onChanged: (value) {
                  // 取消之前的定时器
                  _onChangeDebounceTimer?.cancel();

                  // 检测是否刚输入了换行符（通过比较上次值和当前值）
                  if (_lastValue != null &&
                      value.length > _lastValue!.length &&
                      value.endsWith('\n')) {
                    final now = DateTime.now();
                    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                    // 在换行后添加时间
                    _contentController.text = '$value$timeStr ';
                    // 将光标移到末尾
                    _contentController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _contentController.text.length),
                    );
                  }

                  // 使用节流，每 500ms 才更新一次 _lastValue
                  _onChangeDebounceTimer = Timer(const Duration(milliseconds: 500), () {
                    _lastValue = _contentController.text;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Card(
      key: _contentFieldKey,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: TextFormField(
          controller: _contentController,
          decoration: InputDecoration(
            hintText: '记录今天的故事...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            alignLabelWithHint: true,
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请填写日记内容';
            }
            return null;
          },
          onTap: () {
            // 首次点击且内容为空时，添加当前时间（使用微任务避免阻塞UI）
            if (_contentController.text.isEmpty) {
              Future.microtask(() {
                final now = DateTime.now();
                final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                _contentController.text = '$timeStr ';
                _lastValue = _contentController.text;
                // 将光标移到末尾
                _contentController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _contentController.text.length),
                );
              });
            }
          },
          onChanged: (value) {
            // 取消之前的定时器
            _onChangeDebounceTimer?.cancel();

            // 检测是否刚输入了换行符（通过比较上次值和当前值）
            if (_lastValue != null &&
                value.length > _lastValue!.length &&
                value.endsWith('\n')) {
              final now = DateTime.now();
              final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
              // 在换行后添加时间
              _contentController.text = '$value$timeStr ';
              // 将光标移到末尾
              _contentController.selection = TextSelection.fromPosition(
                TextPosition(offset: _contentController.text.length),
              );
            }

            // 使用节流，每 500ms 才更新一次 _lastValue
            _onChangeDebounceTimer = Timer(const Duration(milliseconds: 500), () {
              _lastValue = _contentController.text;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTimestampSection() {
    if (widget.existingEntry == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        '创建于 ${DateFormat('yyyy/MM/dd HH:mm:ss').format(widget.existingEntry!.createdAt)}  修改于 ${DateFormat('yyyy/MM/dd HH:mm:ss').format(widget.existingEntry!.updatedAt)}',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[500],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 禁用自动调整，使用手动处理避免卡顿
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 顶部区域 - 固定不滚动
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAppBar(),
                    const SizedBox(height: 4),
                    // 第一行：今天吃了啥（左）+ 心情天气（右）
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildMealSection()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMoodAndWeatherSectionCompact()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 第二行：照片（全宽）
                    _buildImageSection(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              // 内容区域 - 可滚动，使用 Expanded 填充剩余空间
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildContentSection()),
                      const SizedBox(height: 8),
                      _buildTimestampSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 自定义 TextEditingController，用于高亮时间格式
class _TimeHighlightController extends TextEditingController {
  // 时间格式正则表达式 (HH:mm)
  static final RegExp _timeRegex = RegExp(r'\b(\d{2}):(\d{2})\b');

  // 缓存上次构建的文本和结果，避免重复计算
  String? _lastText;
  TextSpan? _lastSpan;
  bool? _lastIsDark;

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final String text = this.text;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 如果文本和主题都没有变化，直接返回缓存的结果
    if (text == _lastText && _lastIsDark == isDark && _lastSpan != null) {
      return _lastSpan!;
    }

    _lastText = text;
    _lastIsDark = isDark;

    // 如果文本很短或没有内容，直接返回普通文本
    if (text.isEmpty) {
      _lastSpan = TextSpan(text: text, style: style);
      return _lastSpan!;
    }

    // 如果文本很长（超过1000字符），跳过复杂的高亮处理，直接返回普通文本
    if (text.length > 1000) {
      _lastSpan = TextSpan(text: text, style: style);
      return _lastSpan!;
    }

    final List<InlineSpan> spans = [];
    int lastMatchEnd = 0;

    // 获取主题颜色
    final timeColor = isDark ? Colors.grey[400] : Colors.grey[700];

    // 查找所有时间格式并高亮
    for (final Match match in _timeRegex.allMatches(text)) {
      // 添加时间前的普通文本
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: style,
        ));
      }

      // 添加时间纯文本样式
      final timeText = match.group(0)!;
      spans.add(TextSpan(
        text: timeText,
        style: (style ?? const TextStyle()).copyWith(
          color: timeColor,
          fontWeight: FontWeight.w500,
        ),
      ));

      lastMatchEnd = match.end;
    }

    // 添加剩余文本
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: style,
      ));
    }

    // 如果没有匹配到时间，返回普通文本
    if (spans.isEmpty) {
      _lastSpan = TextSpan(text: text, style: style);
      return _lastSpan!;
    }

    _lastSpan = TextSpan(children: spans);
    return _lastSpan!;
  }
}
