class Habit {
  Habit({
    required this.id,
    required this.userId,
    required this.title,
    required List<String> frequency,
    required this.currentStreak,
    required this.isCompletedToday,
  }) : frequency = List.unmodifiable(frequency);

  final String id;
  final String userId;
  final String title;
  final List<String> frequency;
  final int currentStreak;
  final bool isCompletedToday;

  factory Habit.fromMap(Map<String, dynamic> map, {String? id}) {
    return Habit(
      id: (map['id'] as String?) ?? id ?? '',
      userId: (map['userId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      frequency: _parseFrequency(map['frequency']),
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      isCompletedToday: (map['isCompletedToday'] as bool?) ?? false,
    );
  }

  factory Habit.fromJson(Map<String, dynamic> json, {String? id}) {
    return Habit.fromMap(json, id: id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'frequency': frequency,
      'currentStreak': currentStreak,
      'isCompletedToday': isCompletedToday,
    };
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
}
