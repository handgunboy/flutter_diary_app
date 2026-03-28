import 'dart:io';
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
import 'recycle_bin_screen.dart';
import 'ai_chat_screen.dart';

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
                    // IconButton(
                    //   icon: const Icon(Icons.bookmark),
                    //   onPressed: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => const FavoritesScreen(),
                    //       ),
                    //     );
                    //   },
                    //   tooltip: '收藏夹',
                    // ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecycleBinScreen(),
                          ),
                        );
                        // 如果回收站有数据变化，刷新主页
                        if (result == true) {
                          _loadEntries();
                        }
                      },
                      tooltip: '回收站',
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AiChatScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/images/txbb.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                        // 如果设置页面返回 true（数据被清除），刷新主页
                        if (result == true) {
                          _loadEntries();
                        }
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
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Drawer(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 自定义年月选择器
                _buildCalendarHeader(),
              // 日历主体 - 设置固定高度
              SizedBox(
                height: 350,
                child: TableCalendar<DiaryEntry>(
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
                  headerVisible: false, // 隐藏默认的header
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
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    weekendStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  locale: 'en_US',
                  calendarBuilders: CalendarBuilders(
                    dowBuilder: (context, day) {
                      final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
                      final weekdayIndex = day.weekday - 1; // Monday = 1, so index = 0
                      final isWeekend = day.weekday == 6 || day.weekday == 7; // Saturday or Sunday
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      
                      return Center(
                        child: Text(
                          weekdays[weekdayIndex],
                          style: TextStyle(
                            color: isWeekend
                                ? (isDark ? Colors.grey[500] : Colors.grey[600])
                                : (isDark ? Colors.grey[400] : Colors.grey[800]),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                    defaultBuilder: (context, day, focusedDay) {
                      return _buildCalendarDay(day, focusedDay, false, false);
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return _buildCalendarDay(day, focusedDay, true, false);
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return _buildCalendarDay(day, focusedDay, false, true);
                    },
                    outsideBuilder: (context, day, focusedDay) {
                      return _buildCalendarDay(day, focusedDay, false, false, isOutside: true);
                    },
                    disabledBuilder: (context, day, focusedDay) {
                      return _buildCalendarDay(day, focusedDay, false, false, isDisabled: true);
                    },
                  ),
                ),
              ),
              // 分割线
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey[300],
                indent: 16,
                endIndent: 16,
              ),
              // 当月日记列表 - 不再使用 Expanded，高度自适应
              _buildMonthlyDiaryListForScrollable(),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildCalendarHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[800] : Colors.grey[200];
    final textColor = isDark ? Colors.grey[300] : Colors.grey[700];
    final iconColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // 年份选择 - 下拉框样式
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _focusedDay.year,
                icon: Icon(Icons.arrow_drop_down, size: 20, color: iconColor),
                style: GoogleFonts.righteous(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(8),
                menuMaxHeight: 200,
                items: List.generate(11, (index) {
                  final year = 2020 + index;
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(
                      '$year',
                      style: GoogleFonts.righteous(
                        fontSize: 16,
                        fontWeight: year == _focusedDay.year ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }),
                onChanged: (int? year) {
                  if (year != null) {
                    setState(() {
                      _focusedDay = DateTime(year, _focusedDay.month, 1);
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 月份选择 - 下拉框样式
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _focusedDay.month,
                icon: Icon(Icons.arrow_drop_down, size: 20, color: iconColor),
                style: GoogleFonts.righteous(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(8),
                menuMaxHeight: 200,
                items: List.generate(12, (index) {
                  final month = index + 1;
                  return DropdownMenuItem<int>(
                    value: month,
                    child: Text(
                      '$month',
                      style: GoogleFonts.righteous(
                        fontSize: 16,
                        fontWeight: month == _focusedDay.month ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }),
                onChanged: (int? month) {
                  if (month != null) {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, month, 1);
                    });
                  }
                },
              ),
            ),
          ),
          const Spacer(),
          // 返回今天按钮 - 灰色
          IconButton(
            onPressed: () => _goToToday(),
            icon: Icon(
              Icons.my_location,
              size: 20,
              color: iconColor,
            ),
            tooltip: '定位到今天',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // 获取某天的第一个日记的第一张图片
  String? _getDayFirstImage(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    final entries = _events[date] ?? [];
    if (entries.isEmpty) return null;
    
    // 获取第一个日记的第一张图片
    final firstEntry = entries.first;
    if (firstEntry.images.isNotEmpty) {
      return firstEntry.images.first;
    }
    return null;
  }

  Widget _buildCalendarDay(
    DateTime day,
    DateTime focusedDay,
    bool isToday,
    bool isSelected, {
    bool isOutside = false,
    bool isDisabled = false,
  }) {
    final imagePath = _getDayFirstImage(day);
    final textColor = isDisabled
        ? Colors.grey[300]
        : isOutside
            ? Colors.grey[400]
            : isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface;

    Widget dayWidget = AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : isToday
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: GoogleFonts.righteous(
              fontSize: 16,
              color: textColor,
            ),
          ),
        ),
      ),
    );

    // 如果有图片，显示图片背景
    if (imagePath != null && !isDisabled) {
      dayWidget = AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 图片背景
                Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // 图片加载失败时显示默认样式
                    return Container(
                      color: isToday
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.grey[200],
                    );
                  },
                ),
                // 半透明遮罩，让日期数字更清晰
                Container(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                      : Colors.black.withOpacity(0.2),
                ),
                // 日期数字
                Center(
                  child: Text(
                    '${day.day}',
                    style: GoogleFonts.righteous(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
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

    return dayWidget;
  }

  void _showYearPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择年份'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: ListView.builder(
              itemCount: 11, // 2020-2030
              itemBuilder: (context, index) {
                final year = 2020 + index;
                final isSelected = year == _focusedDay.year;
                return ListTile(
                  title: Text(
                    '$year年',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  trailing: isSelected ? Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  ) : null,
                  onTap: () {
                    setState(() {
                      _focusedDay = DateTime(year, _focusedDay.month, 1);
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showMonthPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择月份'),
          content: SizedBox(
            width: 300,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.5,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected = month == _focusedDay.month;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, month, 1);
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$month月',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedDay = now;
      _selectedDay = now;
    });
    // 只在日历内部跳转到今天，不关闭侧边栏，不跳回主页
  }

  // 获取当月有图片日记的日期列表
  List<DateTime> _getMonthDaysWithEntries() {
    final List<DateTime> daysWithEntries = [];
    final year = _focusedDay.year;
    final month = _focusedDay.month;

    // 获取当月所有日期
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);

    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(year, month, day);
      final entries = _events[date] ?? [];
      // 只添加有图片的日记日期
      if (entries.isNotEmpty && entries.first.images.isNotEmpty) {
        daysWithEntries.add(date);
      }
    }

    // 按日期倒序排列
    daysWithEntries.sort((a, b) => b.compareTo(a));
    return daysWithEntries;
  }

  // 获取周几的中文名称
  String _getWeekdayName(DateTime date) {
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[date.weekday - 1];
  }

  Widget _buildMonthlyDiaryList() {
    final daysWithEntries = _getMonthDaysWithEntries();

    if (daysWithEntries.isEmpty) {
      return Center(
        child: Text(
          '本月暂无日记',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: daysWithEntries.length,
      itemBuilder: (context, index) {
        final date = daysWithEntries[index];
        final entries = _events[date] ?? [];
        final firstEntry = entries.first;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return InkWell(
          onTap: () {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final targetDay = DateTime(date.year, date.month, date.day);
            final dayOffset = targetDay.difference(today).inDays;
            final pageIndex = 10000 + dayOffset;

            setState(() {
              _selectedDay = date;
              _focusedDay = date;
            });

            _pageController.jumpToPage(pageIndex);
            _scaffoldKey.currentState?.closeDrawer();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：周几和日期 - 添加灰色背景
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getWeekdayName(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date.day}',
                        style: GoogleFonts.righteous(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[200] : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // 右侧：图片卡片
                Expanded(
                  child: _buildDiaryCard(firstEntry, isDark: isDark),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 可滚动版本的日记列表 - 外层已有 SingleChildScrollView，这里只用 Column
  Widget _buildMonthlyDiaryListForScrollable() {
    final daysWithEntries = _getMonthDaysWithEntries();

    if (daysWithEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            '本月暂无日记',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: daysWithEntries.map((date) {
          final entries = _events[date] ?? [];
          final firstEntry = entries.first;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return InkWell(
            onTap: () {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final targetDay = DateTime(date.year, date.month, date.day);
              final dayOffset = targetDay.difference(today).inDays;
              final pageIndex = 10000 + dayOffset;

              setState(() {
                _selectedDay = date;
                _focusedDay = date;
              });

              _pageController.jumpToPage(pageIndex);
              _scaffoldKey.currentState?.closeDrawer();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧：周几和日期 - 添加灰色背景
                  Container(
                    width: 50,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getWeekdayName(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: GoogleFonts.righteous(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[200] : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 右侧：图片卡片
                  Expanded(
                    child: _buildDiaryCard(firstEntry, isDark: isDark),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDiaryCard(DiaryEntry entry, {bool isDark = false}) {
    final hasImage = entry.images.isNotEmpty;
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final tagBgColor = isDark ? Colors.grey[800] : Colors.grey[200];
    final tagTextColor = isDark ? Colors.grey[400] : Colors.grey[700];
    final shadowColor = isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图片区域
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.file(
                  File(entry.images.first),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isDark ? Colors.grey[700] : Colors.grey[200],
                      child: Icon(Icons.image_not_supported, color: isDark ? Colors.grey[500] : Colors.grey[400]),
                    );
                  },
                ),
              ),
            ),
          // 标签区域
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[50],
              borderRadius: hasImage
                  ? const BorderRadius.vertical(bottom: Radius.circular(12))
                  : BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // 心情标签 - 简洁无背景
                if (entry.mood != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (MoodIcons.getIcon(entry.mood!) != null) ...[
                        Icon(
                          MoodIcons.getIcon(entry.mood!)!,
                          size: 14,
                          color: tagTextColor,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        entry.mood!,
                        style: TextStyle(
                          fontSize: 12,
                          color: tagTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                if (entry.mood != null && entry.weather != null)
                  const SizedBox(width: 12),
                // 天气标签 - 简洁无背景
                if (entry.weather != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (WeatherIcons.getIcon(entry.weather!) != null) ...[
                        Icon(
                          WeatherIcons.getIcon(entry.weather!)!,
                          size: 14,
                          color: tagTextColor,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        entry.weather!,
                        style: TextStyle(
                          fontSize: 12,
                          color: tagTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
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
