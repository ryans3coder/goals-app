class Habit {
  const Habit({
    required this.id,
    required this.userId,
    required this.title,
    required this.frequency,
    required this.currentStreak,
    required this.isCompletedToday,
  });

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
      frequency: (map['frequency'] as List<dynamic>?)
              ?.map((value) => value.toString())
              .toList() ??
          const [],
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      isCompletedToday: (map['isCompletedToday'] as bool?) ?? false,
    );
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
}
