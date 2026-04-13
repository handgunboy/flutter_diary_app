import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../models/diary_entry.dart';

/// 心情图标映射
class MoodIcons {
  static final Map<String, IconData> _moodMap = {
    // 开心类
    '开心': Icons.sentiment_very_satisfied,
    '高兴': Icons.sentiment_very_satisfied,
    '快乐': Icons.sentiment_very_satisfied,
    '愉快': Icons.sentiment_satisfied,
    '欢乐': Icons.sentiment_very_satisfied,
    '喜悦': Icons.sentiment_very_satisfied,
    '兴奋': Icons.sentiment_very_satisfied,
    '幸福': Icons.favorite,
    '满足': Icons.sentiment_satisfied,
    '舒畅': Icons.sentiment_satisfied,
    '惬意': Icons.sentiment_satisfied,
    '爽': Icons.sentiment_very_satisfied,
    '棒': Icons.thumb_up,
    '好': Icons.sentiment_satisfied,
    '很好': Icons.sentiment_very_satisfied,
    '不错': Icons.sentiment_satisfied,
    '美滋滋': Icons.sentiment_very_satisfied,
    '乐': Icons.sentiment_very_satisfied,
    '笑': Icons.sentiment_very_satisfied,
    '哈哈': Icons.sentiment_very_satisfied,
    '嘿嘿': Icons.sentiment_satisfied,
    '嘻嘻': Icons.sentiment_very_satisfied,
    'haha': Icons.sentiment_very_satisfied,
    'happy': Icons.sentiment_very_satisfied,
    'good': Icons.sentiment_satisfied,
    'great': Icons.sentiment_very_satisfied,
    'excellent': Icons.sentiment_very_satisfied,
    'wonderful': Icons.sentiment_very_satisfied,
    'amazing': Icons.sentiment_very_satisfied,
    'perfect': Icons.sentiment_very_satisfied,
    'awesome': Icons.sentiment_very_satisfied,
    
    // 平静类
    '平静': Icons.sentiment_neutral,
    '淡定': Icons.sentiment_neutral,
    '安宁': Icons.sentiment_neutral,
    '安静': Icons.sentiment_neutral,
    '宁静': Icons.sentiment_neutral,
    '平和': Icons.sentiment_neutral,
    '沉稳': Icons.sentiment_neutral,
    '冷静': Icons.sentiment_neutral,
    '一般': Icons.sentiment_neutral,
    '还行': Icons.sentiment_neutral,
    '可以': Icons.sentiment_neutral,
    'ok': Icons.sentiment_neutral,
    'okay': Icons.sentiment_neutral,
    'normal': Icons.sentiment_neutral,
    'fine': Icons.sentiment_neutral,
    'calm': Icons.sentiment_neutral,
    'peaceful': Icons.sentiment_neutral,
    'relaxed': Icons.sentiment_neutral,
    
    // 难过类
    '难过': Icons.sentiment_dissatisfied,
    '伤心': Icons.sentiment_dissatisfied,
    '悲伤': Icons.sentiment_dissatisfied,
    '痛苦': Icons.sentiment_very_dissatisfied,
    '难受': Icons.sentiment_dissatisfied,
    '郁闷': Icons.sentiment_dissatisfied,
    '沮丧': Icons.sentiment_dissatisfied,
    '失落': Icons.sentiment_dissatisfied,
    '委屈': Icons.sentiment_dissatisfied,
    '想哭': Icons.sentiment_very_dissatisfied,
    '哭': Icons.sentiment_very_dissatisfied,
    '流泪': Icons.sentiment_very_dissatisfied,
    '悲哀': Icons.sentiment_dissatisfied,
    '忧愁': Icons.sentiment_dissatisfied,
    '忧郁': Icons.sentiment_dissatisfied,
    '不开心': Icons.sentiment_dissatisfied,
    '不好': Icons.sentiment_dissatisfied,
    '差': Icons.sentiment_dissatisfied,
    '糟': Icons.sentiment_very_dissatisfied,
    '糟糕': Icons.sentiment_very_dissatisfied,
    'sad': Icons.sentiment_dissatisfied,
    'unhappy': Icons.sentiment_dissatisfied,
    'upset': Icons.sentiment_dissatisfied,
    'depressed': Icons.sentiment_dissatisfied,
    'cry': Icons.sentiment_very_dissatisfied,
    'crying': Icons.sentiment_very_dissatisfied,
    'bad': Icons.sentiment_dissatisfied,
    'terrible': Icons.sentiment_very_dissatisfied,
    'awful': Icons.sentiment_very_dissatisfied,
    
    // 生气类
    '生气': Icons.sentiment_very_dissatisfied,
    '愤怒': Icons.sentiment_very_dissatisfied,
    '恼火': Icons.sentiment_very_dissatisfied,
    '烦躁': Icons.sentiment_dissatisfied,
    '暴躁': Icons.sentiment_very_dissatisfied,
    '火大': Icons.sentiment_very_dissatisfied,
    '气': Icons.sentiment_dissatisfied,
    '怒': Icons.sentiment_very_dissatisfied,
    'angry': Icons.sentiment_very_dissatisfied,
    'mad': Icons.sentiment_very_dissatisfied,
    'furious': Icons.sentiment_very_dissatisfied,
    'annoyed': Icons.sentiment_dissatisfied,
    'irritated': Icons.sentiment_dissatisfied,
    
    // 疲惫类
    '累': Icons.battery_alert,
    '疲惫': Icons.battery_alert,
    '疲倦': Icons.battery_alert,
    '困': Icons.bedtime,
    '想睡': Icons.bedtime,
    '困乏': Icons.bedtime,
    '疲劳': Icons.battery_alert,
    '无力': Icons.battery_alert,
    '没劲': Icons.battery_alert,
    'tired': Icons.battery_alert,
    'exhausted': Icons.battery_alert,
    'sleepy': Icons.bedtime,
    
    // 焦虑类
    '焦虑': Icons.psychology,
    '紧张': Icons.psychology,
    '担心': Icons.psychology,
    '害怕': Icons.warning,
    '恐惧': Icons.warning,
    '慌': Icons.psychology,
    'anxious': Icons.psychology,
    'nervous': Icons.psychology,
    'worried': Icons.psychology,
    'scared': Icons.warning,
    'afraid': Icons.warning,
    
    // 惊喜类
    '惊喜': Icons.stars,
    '惊讶': Icons.stars,
    '意外': Icons.stars,
    '震惊': Icons.stars,
    'surprised': Icons.stars,
    'shocked': Icons.stars,
    'amazed': Icons.stars,
    'astonished': Icons.stars,
    
    // 爱心类
    '爱': Icons.favorite,
    '喜欢': Icons.favorite,
    '心动': Icons.favorite,
    '甜蜜': Icons.favorite,
    '浪漫': Icons.favorite,
    'love': Icons.favorite,
    'like': Icons.favorite,
    'sweet': Icons.favorite,
    
    // 思考类
    '思考': Icons.psychology,
    '疑惑': Icons.help_outline,
    '迷茫': Icons.psychology,
    '困惑': Icons.help_outline,
    '疑问': Icons.help_outline,
    'think': Icons.psychology,
    'thinking': Icons.psychology,
    'confused': Icons.help_outline,
    'puzzled': Icons.help_outline,
    
    // 生病类
    '生病': Icons.sick,
    '不舒服': Icons.sick,
    '难受': Icons.sick,
    '痛': Icons.sick,
    '疼': Icons.sick,
    'sick': Icons.sick,
    'ill': Icons.sick,
    'unwell': Icons.sick,
    'pain': Icons.sick,
    
    // 无聊类
    '无聊': Icons.bedtime_outlined,
    '没意思': Icons.bedtime_outlined,
    '枯燥': Icons.bedtime_outlined,
    'bored': Icons.bedtime_outlined,
    'boring': Icons.bedtime_outlined,
  };

  static IconData? getIcon(String mood) {
    // 直接匹配
    if (_moodMap.containsKey(mood)) {
      return _moodMap[mood];
    }
    
    // 小写匹配
    final lowerMood = mood.toLowerCase();
    if (_moodMap.containsKey(lowerMood)) {
      return _moodMap[lowerMood];
    }
    
    // 包含匹配 - 检查关键词是否包含在mood中
    for (final entry in _moodMap.entries) {
      if (mood.contains(entry.key) || entry.key.contains(mood)) {
        return entry.value;
      }
    }
    
    return null;
  }
}

/// 天气图标映射
class WeatherIcons {
  static final Map<String, IconData> _weatherMap = {
    // 晴天类
    '晴': Icons.wb_sunny,
    '晴天': Icons.wb_sunny,
    '太阳': Icons.wb_sunny,
    '阳光': Icons.wb_sunny,
    '晴朗': Icons.wb_sunny,
    'sunny': Icons.wb_sunny,
    'sun': Icons.wb_sunny,
    'clear': Icons.wb_sunny,
    'sunny day': Icons.wb_sunny,
    'hot': Icons.wb_sunny,
    '炎热': Icons.wb_sunny,
    '热': Icons.wb_sunny,
    '暴晒': Icons.wb_sunny,
    
    // 多云类
    '多云': Icons.wb_cloudy,
    '阴天': Icons.wb_cloudy,
    '阴': Icons.cloud,
    'cloudy': Icons.wb_cloudy,
    'overcast': Icons.wb_cloudy,
    'cloud': Icons.cloud,
    'clouds': Icons.cloud,
    
    // 雨天类
    '雨': Icons.water_drop,
    '下雨': Icons.water_drop,
    '雨天': Icons.water_drop,
    '小雨': Icons.water_drop,
    '中雨': Icons.water_drop,
    '大雨': Icons.water_drop,
    '暴雨': Icons.water_drop,
    '阵雨': Icons.water_drop,
    '雷阵雨': Icons.thunderstorm,
    'rain': Icons.water_drop,
    'rainy': Icons.water_drop,
    'drizzle': Icons.water_drop,
    'shower': Icons.water_drop,
    'downpour': Icons.water_drop,
    'storm': Icons.thunderstorm,
    'thunderstorm': Icons.thunderstorm,
    'thunder': Icons.thunderstorm,
    '雷': Icons.thunderstorm,
    '打雷': Icons.thunderstorm,
    
    // 雪天类
    '雪': Icons.ac_unit,
    '下雪': Icons.ac_unit,
    '雪天': Icons.ac_unit,
    '小雪': Icons.ac_unit,
    '中雪': Icons.ac_unit,
    '大雪': Icons.ac_unit,
    '暴雪': Icons.ac_unit,
    'snow': Icons.ac_unit,
    'snowy': Icons.ac_unit,
    'snowfall': Icons.ac_unit,
    'blizzard': Icons.ac_unit,
    '冰雹': Icons.ac_unit,
    'hail': Icons.ac_unit,
    
    // 风天类
    '风': Icons.air,
    '大风': Icons.air,
    '微风': Icons.air,
    '刮风': Icons.air,
    '风暴': Icons.storm,
    '台风': Icons.storm,
    '飓风': Icons.storm,
    'wind': Icons.air,
    'windy': Icons.air,
    'breeze': Icons.air,
    'gale': Icons.air,
    'storm': Icons.storm,
    'typhoon': Icons.storm,
    'hurricane': Icons.storm,
    
    // 雾天类
    '雾': Icons.foggy,
    '大雾': Icons.foggy,
    '雾霾': Icons.foggy,
    '雾天': Icons.foggy,
    'fog': Icons.foggy,
    'foggy': Icons.foggy,
    'haze': Icons.foggy,
    'smog': Icons.foggy,
    'mist': Icons.foggy,
    
    // 特殊天气
    '彩虹': Icons.looks,
    'rainbow': Icons.looks,
    '沙尘': Icons.grain,
    '沙尘暴': Icons.grain,
    'sandstorm': Icons.grain,
    'dust': Icons.grain,
    
    // 夜晚
    '月亮': Icons.nights_stay,
    '晚上': Icons.nights_stay,
    '夜晚': Icons.nights_stay,
    'moon': Icons.nights_stay,
    'night': Icons.nights_stay,
    'evening': Icons.nights_stay,
    '星空': Icons.nights_stay,
    'starry': Icons.nights_stay,
    
    // 温度相关
    '冷': Icons.thermostat,
    '寒冷': Icons.thermostat,
    'cool': Icons.thermostat,
    'cold': Icons.thermostat,
    'freezing': Icons.thermostat,
    '冰冻': Icons.thermostat,
    '冰': Icons.thermostat,
    'warm': Icons.thermostat,
    '温暖': Icons.thermostat,
    '凉爽': Icons.thermostat,
    '凉快': Icons.thermostat,
  };

  static IconData? getIcon(String weather) {
    // 直接匹配
    if (_weatherMap.containsKey(weather)) {
      return _weatherMap[weather];
    }
    
    // 小写匹配
    final lowerWeather = weather.toLowerCase();
    if (_weatherMap.containsKey(lowerWeather)) {
      return _weatherMap[lowerWeather];
    }
    
    // 包含匹配
    for (final entry in _weatherMap.entries) {
      if (weather.contains(entry.key) || entry.key.contains(weather)) {
        return entry.value;
      }
    }
    
    return null;
  }
}

class DiaryCard extends StatelessWidget {
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
                  // 心情和天气标签移到左边
                  if (entry.mood != null)
                    _buildMoodTag(context, entry.mood!),
                  if (entry.weather != null)
                    _buildWeatherTag(context, entry.weather!),
                  const Spacer(),
                  // IconButton(
                  //   icon: Icon(
                  //     entry.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  //     color: entry.isFavorite ? Colors.grey[700] : Colors.grey[600],
                  //     size: 20,
                  //   ),
                  //   onPressed: onToggleFavorite,
                  //   padding: EdgeInsets.zero,
                  //   constraints: const BoxConstraints(),
                  // ),
                  // const SizedBox(width: 4),
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
              _buildHighlightedText(
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

  Widget _buildMoodTag(BuildContext context, String mood) {
    final icon = MoodIcons.getIcon(mood);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.grey[400] : Colors.grey[700];
    final borderColor = isDark ? Colors.grey[700] : Colors.grey[300];
    final isHighlighted = searchQuery.isNotEmpty && mood.toLowerCase().contains(searchQuery.toLowerCase());

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHighlighted ? Colors.red : borderColor!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isHighlighted ? Colors.red : textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            mood,
            style: TextStyle(
              fontSize: 12,
              color: isHighlighted ? Colors.red : textColor,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherTag(BuildContext context, String weather) {
    final icon = WeatherIcons.getIcon(weather);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.grey[400] : Colors.grey[700];
    final borderColor = isDark ? Colors.grey[700] : Colors.grey[300];
    final isHighlighted = searchQuery.isNotEmpty && weather.toLowerCase().contains(searchQuery.toLowerCase());

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHighlighted ? Colors.red : borderColor!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isHighlighted ? Colors.red : textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            weather,
            style: TextStyle(
              fontSize: 12,
              color: isHighlighted ? Colors.red : textColor,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
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

  // 构建带高亮的文本
  Widget _buildHighlightedText(String text, String query, {int maxLines = 3}) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.grey[700],
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
        // 添加剩余文本
        if (start < text.length) {
          spans.add(TextSpan(
            text: text.substring(start),
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.4,
            ),
          ));
        }
        break;
      }

      // 添加高亮前的文本
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: TextStyle(
            color: Colors.grey[700],
            height: 1.4,
          ),
        ));
      }

      // 添加高亮文本
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          color: Colors.red,
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
