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
  final String? weight;
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
    this.weight,
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
      'weight': weight,
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
      weight: json['weight'],
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
    Object? breakfast = const Object(),
    Object? lunch = const Object(),
    Object? dinner = const Object(),
    Object? snacks = const Object(),
    Object? mood = const Object(),
    Object? weather = const Object(),
    Object? weight = const Object(),
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    Object? deletedAt = const Object(),
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      breakfast: breakfast == const Object() ? this.breakfast : breakfast as String?,
      lunch: lunch == const Object() ? this.lunch : lunch as String?,
      dinner: dinner == const Object() ? this.dinner : dinner as String?,
      snacks: snacks == const Object() ? this.snacks : snacks as String?,
      mood: mood == const Object() ? this.mood : mood as String?,
      weather: weather == const Object() ? this.weather : weather as String?,
      weight: weight == const Object() ? this.weight : weight as String?,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      deletedAt: deletedAt == const Object() ? this.deletedAt : deletedAt as DateTime?,
    );
  }
}
