class FavoriteItem {
  final String id;
  final String type; // 'text' 或 'image'
  final String? content; // 摘抄的句子（type为text时使用）
  final String? imagePath; // 图片路径（type为image时使用）
  final String? source; // 来源（书名、文章等）
  final DateTime createdAt;
  final List<String> tags; // 标签

  FavoriteItem({
    required this.id,
    required this.type,
    this.content,
    this.imagePath,
    this.source,
    required this.createdAt,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'content': content,
      'imagePath': imagePath,
      'source': source,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
    };
  }

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'],
      type: json['type'],
      content: json['content'],
      imagePath: json['imagePath'],
      source: json['source'],
      createdAt: DateTime.parse(json['createdAt']),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  FavoriteItem copyWith({
    String? id,
    String? type,
    String? content,
    String? imagePath,
    String? source,
    DateTime? createdAt,
    List<String>? tags,
  }) {
    return FavoriteItem(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }
}
