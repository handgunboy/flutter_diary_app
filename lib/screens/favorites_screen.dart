import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../services/storage_service.dart';
import '../widgets/app_top_toast.dart';
import '../widgets/diary_card.dart';
import 'write_diary_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final StorageService _storageService = StorageService();
  List<DiaryEntry> _favoriteEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final entries = await _storageService.getFavoriteEntries();
    setState(() {
      _favoriteEntries = entries;
      _isLoading = false;
    });
  }

  Future<void> _navigateToWriteDiary(DiaryEntry entry) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriteDiaryScreen(
          selectedDate: entry.date,
          existingEntry: entry,
        ),
      ),
    );
    
    if (result == true) {
      _loadFavorites();
    }
  }

  Future<void> _toggleFavorite(DiaryEntry entry) async {
    await _storageService.toggleFavorite(entry.id);
    _loadFavorites();
    if (mounted) {
      AppTopToast.show(context, '已取消收藏');
    }
  }

  Future<void> _deleteEntry(DiaryEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这篇日记吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _storageService.deleteEntry(entry.id);
      _loadFavorites();
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
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _favoriteEntries.isEmpty
                      ? _buildEmptyState()
                      : _buildFavoritesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无收藏日记',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在主页点击心形图标收藏日记',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteEntries.length,
      itemBuilder: (context, index) {
        final entry = _favoriteEntries[index];
        return _buildEntryCard(entry);
      },
    );
  }

  Widget _buildEntryCard(DiaryEntry entry) {
    return DiaryCard(
      entry: entry,
      onTap: () => _navigateToWriteDiary(entry),
      onToggleFavorite: () => _toggleFavorite(entry),
      onDelete: () => _deleteEntry(entry),
      showDate: true,
    );
  }
}
