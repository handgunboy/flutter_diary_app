import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_top_toast.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  final StorageService _storageService = StorageService();
  List<DiaryEntry> _deletedEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeletedEntries();
  }

  Future<void> _loadDeletedEntries() async {
    setState(() => _isLoading = true);
    final entries = await _storageService.getDeletedEntries();
    setState(() {
      _deletedEntries = entries;
      _isLoading = false;
    });
  }

  Future<void> _restoreEntry(DiaryEntry entry) async {
    final colors = AppColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复日记'),
        content: Text('确定要恢复《${entry.title}》吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('恢复', style: TextStyle(color: colors.success)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storageService.restoreEntry(entry.id);
      _loadDeletedEntries();
      if (mounted) {
        AppTopToast.show(context, '日记已恢复');
        // 返回true通知主页刷新
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _permanentlyDeleteEntry(DiaryEntry entry) async {
    final colors = AppColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('永久删除'),
        content: Text('确定要永久删除《${entry.title}》吗？此操作无法撤销！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('删除', style: TextStyle(color: colors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storageService.permanentlyDeleteEntry(entry.id);
      _loadDeletedEntries();
      if (mounted) {
        AppTopToast.show(context, '日记已永久删除');
      }
    }
  }

  Future<void> _emptyRecycleBin() async {
    if (_deletedEntries.isEmpty) return;

    final colors = AppColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空回收站'),
        content: Text('确定要清空回收站吗？${_deletedEntries.length}篇日记将被永久删除，此操作无法撤销！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('清空', style: TextStyle(color: colors.danger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final idsToDelete = _deletedEntries.map((e) => e.id).toList();
      await _storageService.permanentlyDeleteEntries(idsToDelete);
      _loadDeletedEntries();
      if (mounted) {
        AppTopToast.show(context, '回收站已清空');
      }
    }
  }

  String _getRemainingDays(DiaryEntry entry) {
    if (entry.deletedAt == null) return '';
    final daysSinceDeleted = DateTime.now().difference(entry.deletedAt!).inDays;
    final remainingDays = 30 - daysSinceDeleted;
    if (remainingDays <= 0) return '即将清理';
    return '$remainingDays天后清理';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('回收站'),
        actions: [
          if (_deletedEntries.isNotEmpty)
            TextButton.icon(
              onPressed: _emptyRecycleBin,
              icon: const Icon(Icons.delete_forever, size: 20),
              label: const Text('清空'),
              style: TextButton.styleFrom(
                foregroundColor: colors.danger,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deletedEntries.isEmpty
              ? _buildEmptyState()
              : _buildDeletedList(),
    );
  }

  Widget _buildEmptyState() {
    final colors = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            size: 64,
            color: colors.calendarDayOutsideText,
          ),
          const SizedBox(height: 16),
          Text(
            '回收站是空的',
            style: TextStyle(
              fontSize: 16,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '删除的日记会在这里保留30天',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _deletedEntries.length,
      itemBuilder: (context, index) {
        final entry = _deletedEntries[index];
        return _buildDeletedCard(entry);
      },
    );
  }

  Widget _buildDeletedCard(DiaryEntry entry) {
    final colors = AppColors.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.warningBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getRemainingDays(entry),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: colors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('yyyy-MM-dd').format(entry.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.delete, size: 14, color: colors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '删除于 ${DateFormat('MM-dd HH:mm').format(entry.deletedAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _restoreEntry(entry),
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('恢复'),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.success,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _permanentlyDeleteEntry(entry),
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text('彻底删除'),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.danger,
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
