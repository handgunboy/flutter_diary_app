import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../models/diary_entry.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../services/theme_service.dart';
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
  final _contentController = TextEditingController();
  final _breakfastController = TextEditingController();
  final _lunchController = TextEditingController();
  final _dinnerController = TextEditingController();
  final _snacksController = TextEditingController();
  final _moodController = TextEditingController();
  final _weatherController = TextEditingController();
  final _summaryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
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
      _images = List<String>.from(widget.existingEntry!.images);
      
      // 保存初始状态
      _initialContent = widget.existingEntry!.content;
      _initialBreakfast = widget.existingEntry!.breakfast ?? '';
      _initialLunch = widget.existingEntry!.lunch ?? '';
      _initialDinner = widget.existingEntry!.dinner ?? '';
      _initialSnacks = widget.existingEntry!.snacks ?? '';
      _initialMood = widget.existingEntry!.mood ?? '';
      _initialWeather = widget.existingEntry!.weather ?? '';
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
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _parseWithAi() async {
    if (_summaryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请先输入日记总结'),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    if (!_themeService.hasAiConfig) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('请先配置 AI API'),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
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
          if (result['content'] != null) {
            _contentController.text = result['content'];
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('AI 解析完成，请检查并保存'),
              backgroundColor: Colors.grey[800],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI 解析失败: $e'),
            backgroundColor: Colors.grey[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
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
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        setState(() {
          for (var image in images) {
            if (!_images.contains(image.path)) {
              _images.add(image.path);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择图片失败: $e'),
            backgroundColor: Colors.grey[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
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
        images: _images,
        createdAt: widget.existingEntry?.createdAt ?? now,
        updatedAt: now,
        isFavorite: widget.existingEntry?.isFavorite ?? false,
      );

      await _storageService.saveEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('日记保存成功'),
            backgroundColor: Colors.grey[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.grey[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  '图片',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickImages,
                  icon: Icon(Icons.add_photo_alternate, size: 18, color: Colors.grey[600]),
                  label: Text('添加', style: TextStyle(color: Colors.grey[600])),
                ),
              ],
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return _buildImageThumbnail(index);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageGalleryScreen(
          images: _images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(int index) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showFullScreenImage(index),
          child: Hero(
            tag: 'image_$index',
            child: Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_images[index]),
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
          ),
        ),
        Positioned(
          top: 4,
          right: 12,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  '今天吃了啥',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMealInput(
              controller: _breakfastController,
              label: '早餐',
              icon: Icons.wb_sunny_outlined,
              hint: '例如：豆浆、油条',
            ),
            const SizedBox(height: 12),
            _buildMealInput(
              controller: _lunchController,
              label: '午餐',
              icon: Icons.wb_sunny,
              hint: '例如：红烧肉、米饭',
            ),
            const SizedBox(height: 12),
            _buildMealInput(
              controller: _dinnerController,
              label: '晚餐',
              icon: Icons.nights_stay_outlined,
              hint: '例如：蔬菜沙拉',
            ),
            const SizedBox(height: 12),
            _buildMealInput(
              controller: _snacksController,
              label: '零食/其他',
              icon: Icons.cookie_outlined,
              hint: '例如：薯片、奶茶（可选）',
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
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

  Widget _buildContentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  '日记内容',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: '记录今天的故事...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              minLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请填写日记内容';
                }
                return null;
              },
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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
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
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 16),
                    // AI 总结输入框
            Card(
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
            ),
            const SizedBox(height: 16),
            _buildImageSection(),
            const SizedBox(height: 16),
            _buildMealSection(),
            const SizedBox(height: 16),
            _buildMoodAndWeatherSection(),
            const SizedBox(height: 16),
            _buildContentSection(),
            const SizedBox(height: 24),
            if (widget.existingEntry != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '创建于: ${DateFormat('yyyy-MM-dd HH:mm').format(widget.existingEntry!.createdAt)}\n'
                  '最后修改: ${DateFormat('yyyy-MM-dd HH:mm').format(widget.existingEntry!.updatedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageGalleryScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImageGalleryScreen({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<_ImageGalleryScreen> {
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
                heroAttributes: PhotoViewHeroAttributes(tag: 'image_$index'),
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
