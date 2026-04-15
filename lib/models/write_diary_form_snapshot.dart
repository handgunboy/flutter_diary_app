import 'diary_entry.dart';

class WriteDiaryFormSnapshot {
  final String content;
  final String breakfast;
  final String lunch;
  final String dinner;
  final String snacks;
  final String mood;
  final String weather;
  final String weight;
  final List<String> images;

  const WriteDiaryFormSnapshot({
    required this.content,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snacks,
    required this.mood,
    required this.weather,
    required this.weight,
    required this.images,
  });

  factory WriteDiaryFormSnapshot.empty() {
    return const WriteDiaryFormSnapshot(
      content: '',
      breakfast: '',
      lunch: '',
      dinner: '',
      snacks: '',
      mood: '',
      weather: '',
      weight: '',
      images: <String>[],
    );
  }

  factory WriteDiaryFormSnapshot.fromEntry(DiaryEntry entry) {
    return WriteDiaryFormSnapshot(
      content: entry.content,
      breakfast: entry.breakfast ?? '',
      lunch: entry.lunch ?? '',
      dinner: entry.dinner ?? '',
      snacks: entry.snacks ?? '',
      mood: entry.mood ?? '',
      weather: entry.weather ?? '',
      weight: entry.weight ?? '',
      images: List<String>.unmodifiable(entry.images),
    );
  }

  bool hasAnyMeaningfulInput() {
    return content.trim().isNotEmpty ||
        breakfast.trim().isNotEmpty ||
        lunch.trim().isNotEmpty ||
        dinner.trim().isNotEmpty ||
        snacks.trim().isNotEmpty ||
        mood.trim().isNotEmpty ||
        weather.trim().isNotEmpty ||
        weight.trim().isNotEmpty ||
        images.isNotEmpty;
  }

  bool isSameAs(WriteDiaryFormSnapshot other) {
    return content == other.content &&
        breakfast == other.breakfast &&
        lunch == other.lunch &&
        dinner == other.dinner &&
        snacks == other.snacks &&
        mood == other.mood &&
        weather == other.weather &&
        weight == other.weight &&
        _listEquals(images, other.images);
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
