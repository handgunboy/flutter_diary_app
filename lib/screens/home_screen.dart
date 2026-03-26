import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/diary_entry.dart';
import '../services/storage_service.dart';
import '../widgets/diary_card.dart';
import 'write_diary_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController(initialPage: 10000);
  final TextEditingController _searchController = TextEditingController();
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<DiaryEntry>> _events = {};
  bool _isAnimating = false;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEntries();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<DiaryEntry> _getAllEntries() {
    List<DiaryEntry> all = [];
    for (var entries in _events.values) {
      all.addAll(entries);
    }
    return all;
  }

  List<DiaryEntry> _getFilteredEntries() {
    if (_searchQuery.isEmpty) {
      return [];
    }
    final query = _searchQuery.toLowerCase();
    return _getAllEntries().where((entry) {
      return entry.title.toLowerCase().contains(query) ||
             entry.content.toLowerCase().contains(query) ||
             (entry.breakfast?.toLowerCase().contains(query) ?? false) ||
             (entry.lunch?.toLowerCase().contains(query) ?? false) ||
             (entry.dinner?.toLowerCase().contains(query) ?? false) ||
             (entry.snacks?.toLowerCase().contains(query) ?? false) ||
             (entry.mood?.toLowerCase().contains(query) ?? false) ||
             (entry.weather?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  Future<void> _loadEntries() async {
    final entries = await _storageService.getAllEntries();
    setState(() {
      _events = {};
      for (var entry in entries) {
        final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
        if (_events[date] == null) {
          _events[date] = [];
        }
        _events[date]!.add(entry);
      }
    });
  }

  List<DiaryEntry> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _events[date] ?? [];
  }



  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _scaffoldKey.currentState?.closeDrawer();
  }

  void _onPageChanged(int page) {
    if (_isAnimating) return;
    
    final dayOffset = page - 10000;
    final newDate = DateTime.now().add(Duration(days: dayOffset));
    
    setState(() {
      _selectedDay = newDate;
      _focusedDay = newDate;
    });
  }

  Future<void> _navigateToWriteDiary([DateTime? date, DiaryEntry? existingEntry]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriteDiaryScreen(
          selectedDate: date ?? _selectedDay ?? DateTime.now(),
          existingEntry: existingEntry,
        ),
      ),
    );
    
    if (result == true) {
      _loadEntries();
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
      _loadEntries();
    }
  }

  void _goToPreviousDay() {
    if (_selectedDay != null && !_isAnimating) {
      _isAnimating = true;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        _isAnimating = false;
      });
    }
  }

  void _goToNextDay() {
    if (_selectedDay != null && !_isAnimating) {
      _isAnimating = true;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        _isAnimating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSearching) {
          _toggleSearch();
          return false;
        }
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildCalendarDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 12, bottom: 12),
                child: Row(
                  children: [
                    if (!_isSearching && _selectedDay != null)
                      InkWell(
                        onTap: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${_selectedDay!.month}',
                                style: GoogleFonts.righteous(
                                  fontSize: 32,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '月',
                                style: GoogleFonts.righteous(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '${_selectedDay!.day}',
                                style: GoogleFonts.righteous(
                                  fontSize: 32,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '日',
                                style: GoogleFonts.righteous(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_isSearching)
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: '搜索日记...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    if (!_isSearching) const Spacer(),
                    IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _isSearching ? Icons.close : Icons.search,
                          key: ValueKey<bool>(_isSearching),
                        ),
                      ),
                      onPressed: _toggleSearch,
                      tooltip: _isSearching ? '关闭搜索' : '搜索',
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmark),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FavoritesScreen(),
                          ),
                        );
                      },
                      tooltip: '收藏夹',
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      tooltip: '设置',
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isSearching
                  ? _buildSearchResults()
                  : PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      physics: const BouncingScrollPhysics(),
                      allowImplicitScrolling: true,
                      itemBuilder: (context, index) {
                        final dayOffset = index - 10000;
                        final date = DateTime.now().add(Duration(days: dayOffset));
                        return _buildDayPage(date);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToWriteDiary(),
        backgroundColor: Colors.grey[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.edit),
      ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final filteredEntries = _getFilteredEntries();
    
    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '输入关键词搜索日记',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
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
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '没有找到匹配的日记',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredEntries.length,
      itemBuilder: (context, index) {
        final entry = filteredEntries[index];
        return _buildSearchResultCard(entry);
      },
    );
  }

  Widget _buildSearchResultCard(DiaryEntry entry) {
    return DiaryCard(
      entry: entry,
      onTap: () => _navigateToWriteDiary(entry.date, entry),
      onToggleFavorite: () async {
        final storageService = StorageService();
        await storageService.toggleFavorite(entry.id);
        _loadEntries();
      },
      onDelete: () => _deleteEntry(entry),
      showDate: true,
    );
  }

  Widget _buildDayPage(DateTime date) {
    return RepaintBoundary(
      child: _DayPageContent(
        date: date,
        events: _events,
        onNavigateToWriteDiary: _navigateToWriteDiary,
        onDeleteEntry: _deleteEntry,
        onToggleFavorite: _loadEntries,
      ),
    );
  }

  Widget _buildCalendarDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TableCalendar<DiaryEntry>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      eventLoader: _getEventsForDay,
                      onDaySelected: (selectedDay, focusedDay) {
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final targetDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
                        final dayOffset = targetDay.difference(today).inDays;
                        final pageIndex = 10000 + dayOffset;
                        
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        
                        _pageController.jumpToPage(pageIndex);
                        _scaffoldKey.currentState?.closeDrawer();
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarFormat: CalendarFormat.month,
                      availableCalendarFormats: const {
                        CalendarFormat.month: '月',
                      },
                      sixWeekMonthsEnforced: true,
                      calendarStyle: CalendarStyle(
                        markersMaxCount: 1,
                        markerDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                        formatButtonDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        formatButtonTextStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        weekendStyle: TextStyle(
                          color: Colors.red[400],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      locale: 'en_US',
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          return Center(
                            child: Text(
                              '${day.day}',
                              style: GoogleFonts.righteous(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          );
                        },
                        todayBuilder: (context, day, focusedDay) {
                          return Center(
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: GoogleFonts.righteous(
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          return Center(
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: GoogleFonts.righteous(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        outsideBuilder: (context, day, focusedDay) {
                          return Center(
                            child: Text(
                              '${day.day}',
                              style: GoogleFonts.righteous(
                                fontSize: 16,
                                color: Colors.grey[400],
                              ),
                            ),
                          );
                        },
                        disabledBuilder: (context, day, focusedDay) {
                          return Center(
                            child: Text(
                              '${day.day}',
                              style: GoogleFonts.righteous(
                                fontSize: 16,
                                color: Colors.grey[300],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 独立的页面内容组件，优化性能
class _DayPageContent extends StatefulWidget {
  final DateTime date;
  final Map<DateTime, List<DiaryEntry>> events;
  final Function(DateTime?, DiaryEntry?) onNavigateToWriteDiary;
  final Function(DiaryEntry) onDeleteEntry;
  final Function() onToggleFavorite;

  const _DayPageContent({
    required this.date,
    required this.events,
    required this.onNavigateToWriteDiary,
    required this.onDeleteEntry,
    required this.onToggleFavorite,
  });

  @override
  State<_DayPageContent> createState() => _DayPageContentState();
}

class _DayPageContentState extends State<_DayPageContent> {
  List<DiaryEntry> getEventsForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return widget.events[d] ?? [];
  }

  List<Map<String, dynamic>> getHistoricalEntries(DateTime selectedDay) {
    final List<Map<String, dynamic>> historicalEntries = [];
    
    for (int yearOffset = 0; yearOffset <= 4; yearOffset++) {
      final year = selectedDay.year - yearOffset;
      final d = DateTime(year, selectedDay.month, selectedDay.day);
      final entries = getEventsForDay(d);
      
      if (entries.isNotEmpty) {
        historicalEntries.add({
          'year': year,
          'date': d,
          'entries': entries,
        });
      }
    }
    
    return historicalEntries;
  }

  @override
  Widget build(BuildContext context) {
    final historicalData = getHistoricalEntries(widget.date);
    final currentYearEntries = getEventsForDay(widget.date);

    if (historicalData.isEmpty && currentYearEntries.isEmpty) {
      return buildEmptyState(context);
    }

    return buildHistoricalList(context, historicalData);
  }

  Widget buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_edu_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.date.month}月${widget.date.day}日没有历史记录',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '滑动切换日期或点击日历选择',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHistoricalList(BuildContext context, List<Map<String, dynamic>> historicalData) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historicalData.length,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      cacheExtent: 100,
      itemBuilder: (context, index) {
        final data = historicalData[index];
        final year = data['year'] as int;
        final entries = data['entries'] as List<DiaryEntry>;
        final isCurrentYear = year == widget.date.year;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                '$year',
                style: GoogleFonts.righteous(
                  fontSize: 22,
                  color: isCurrentYear ? Colors.red : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            ...entries.map((entry) => buildEntryCard(context, entry, year)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget buildEntryCard(BuildContext context, DiaryEntry entry, int year) {
    return DiaryCard(
      entry: entry,
      onTap: () => widget.onNavigateToWriteDiary(entry.date, entry),
      onToggleFavorite: () async {
        final storageService = StorageService();
        await storageService.toggleFavorite(entry.id);
        widget.onToggleFavorite();
      },
      onDelete: () => widget.onDeleteEntry(entry),
    );
  }

}
