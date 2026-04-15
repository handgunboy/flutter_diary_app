import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/diary_entry.dart';
import 'app_ui.dart';

class HomeSearchResults extends StatelessWidget {
  final ValueListenable<String> searchQueryListenable;
  final List<DiaryEntry> Function() getFilteredEntries;
  final Widget Function(DiaryEntry entry, String searchQuery) itemBuilder;

  const HomeSearchResults({
    super.key,
    required this.searchQueryListenable,
    required this.getFilteredEntries,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: searchQueryListenable,
      builder: (context, searchQuery, _) {
        final filteredEntries = getFilteredEntries();

        if (searchQuery.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 64,
                  color: AppUi.mutedIcon(context),
                ),
                const SizedBox(height: 16),
                Text(
                  '输入关键词搜索日记',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppUi.mutedText(context),
                  ),
                ),
              ],
            ),
          );
        }

        if (filteredEntries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppUi.mutedIcon(context),
                ),
                const SizedBox(height: 16),
                Text(
                  '没有找到匹配的日记',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppUi.mutedText(context),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: AppUi.pagePadding,
          itemCount: filteredEntries.length,
          addRepaintBoundaries: true,
          itemBuilder: (context, index) {
            final entry = filteredEntries[index];
            return RepaintBoundary(
              child: itemBuilder(entry, searchQuery),
            );
          },
        );
      },
    );
  }
}
