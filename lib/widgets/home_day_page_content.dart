import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/diary_entry.dart';
import '../theme/app_colors.dart';
import 'diary_card.dart';

class HomeDayPageContent extends StatelessWidget {
  final DateTime date;
  final Map<DateTime, List<DiaryEntry>> events;
  final Future<void> Function(DateTime?, DiaryEntry?) onNavigateToWriteDiary;
  final Future<void> Function(DiaryEntry) onDeleteEntry;
  final Future<void> Function(DiaryEntry) onToggleFavorite;
  final String searchQuery;

  const HomeDayPageContent({
    super.key,
    required this.date,
    required this.events,
    required this.onNavigateToWriteDiary,
    required this.onDeleteEntry,
    required this.onToggleFavorite,
    this.searchQuery = '',
  });

  List<DiaryEntry> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return events[normalizedDay] ?? const <DiaryEntry>[];
  }

  List<_HistoricalEntriesGroup> _getHistoricalEntries(DateTime selectedDay) {
    final historicalEntries = <_HistoricalEntriesGroup>[];

    for (int yearOffset = 0; yearOffset <= 4; yearOffset++) {
      final year = selectedDay.year - yearOffset;
      final historicalDate = DateTime(year, selectedDay.month, selectedDay.day);
      final entries = _getEventsForDay(historicalDate);

      if (entries.isNotEmpty) {
        historicalEntries.add(
          _HistoricalEntriesGroup(
            year: year,
            entries: entries,
          ),
        );
      }
    }

    return historicalEntries;
  }

  @override
  Widget build(BuildContext context) {
    final historicalData = _getHistoricalEntries(date);
    final currentYearEntries = _getEventsForDay(date);

    if (historicalData.isEmpty && currentYearEntries.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildHistoricalList(context, historicalData);
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_edu_outlined,
            size: 64,
            color: colors.calendarDayOutsideText,
          ),
          const SizedBox(height: 16),
          Text(
            '${date.month}月${date.day}日没有历史记录',
            style: TextStyle(
              fontSize: 16,
              color: colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '滑动切换日期或点击日历选择',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalList(
    BuildContext context,
    List<_HistoricalEntriesGroup> historicalData,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historicalData.length,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      cacheExtent: 250,
      itemBuilder: (context, index) {
        final colors = AppColors.of(context);
        final data = historicalData[index];
        final isCurrentYear = data.year == date.year;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                '${data.year}',
                style: GoogleFonts.righteous(
                  fontSize: 22,
                  color: isCurrentYear
                      ? colors.danger
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            ...data.entries.map(
              (entry) => _buildEntryCard(context, entry),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildEntryCard(BuildContext context, DiaryEntry entry) {
    return DiaryCard(
      entry: entry,
      onTap: () => onNavigateToWriteDiary(entry.date, entry),
      onToggleFavorite: () => onToggleFavorite(entry),
      onDelete: () => onDeleteEntry(entry),
      searchQuery: searchQuery,
    );
  }
}

class _HistoricalEntriesGroup {
  final int year;
  final List<DiaryEntry> entries;

  const _HistoricalEntriesGroup({
    required this.year,
    required this.entries,
  });
}
