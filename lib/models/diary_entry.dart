class DiaryEntry {
  final String id;
  final DateTime date;
  final String title;
  final String content;
  final String? breakfast;
  final String? lunch;
  final String? dinner;
  final String? snacks;
  final String? mood;
  final String? weather;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final DateTime? deletedAt; // 软删除时间，null表示未删除

  DiaryEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    this.breakfast,
    this.lunch,
    this.dinner,
    this.snacks,
    this.mood,
    this.weather,
    this.images = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.deletedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'content': content,
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
      'snacks': snacks,
      'mood': mood,
      'weather': weather,
      'images': images,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFavorite': isFavorite,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      title: json['title'],
      content: json['content'],
      breakfast: json['breakfast'],
      lunch: json['lunch'],
      dinner: json['dinner'],
      snacks: json['snacks'],
      mood: json['mood'],
      weather: json['weather'],
      images: List<String>.from(json['images'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isFavorite: json['isFavorite'] ?? false,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? content,
    String? breakfast,
    String? lunch,
    String? dinner,
    String? snacks,
    String? mood,
    String? weather,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    Object? deletedAt = const Object(), // 使用特殊值来区分"未传入"和"传入null"
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      snacks: snacks ?? this.snacks,
      mood: mood ?? this.mood,
      weather: weather ?? this.weather,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      deletedAt: deletedAt == const Object() ? this.deletedAt : deletedAt as DateTime?,
    );
  }
}
