class Habit {
  Habit({
    required this.id,
    required this.userId,
    required this.title,
    required List<String> frequency,
    required this.currentStreak,
    required this.isCompletedToday,
    this.categoryId,
    this.emoji = '',
    this.description = '',
  }) : frequency = List.unmodifiable(frequency);

  final String id;
  final String userId;
  final String title;
  final List<String> frequency;
  final int currentStreak;
  final bool isCompletedToday;
  final String? categoryId;
  final String emoji;
  final String description;

  factory Habit.fromMap(Map<String, dynamic> map, {String? id}) {
    return Habit(
      id: (map['id'] as String?) ?? id ?? '',
      userId: (map['userId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      frequency: _parseFrequency(map['frequency']),
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      isCompletedToday: (map['isCompletedToday'] as bool?) ?? false,
      categoryId: _parseCategoryId(map),
      emoji: (map['emoji'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
    );
  }

  factory Habit.fromJson(Map<String, dynamic> json, {String? id}) {
    return Habit.fromMap(json, id: id);
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'userId': userId,
      'title': title,
      'frequency': frequency,
      'currentStreak': currentStreak,
      'isCompletedToday': isCompletedToday,
      'emoji': emoji,
      'description': description,
    };
    if (categoryId != null && categoryId!.isNotEmpty) {
      map['categoryId'] = categoryId;
    }
    return map;
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  static List<String> _parseFrequency(dynamic value) {
    if (value is List) {
      return List<String>.unmodifiable(
        value.map((item) => item.toString()),
      );
    }
    return const [];
  }

  static String? _parseCategoryId(Map<String, dynamic> map) {
    final categoryId = map['categoryId'];
    if (categoryId is String && categoryId.trim().isNotEmpty) {
      return categoryId;
    }
    final legacyCategory = map['category'];
    if (legacyCategory is String && legacyCategory.trim().isNotEmpty) {
      return legacyCategory;
    }
    return null;
  }
}
