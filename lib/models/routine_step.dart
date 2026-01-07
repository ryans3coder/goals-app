class RoutineStep {
  const RoutineStep({
    required this.id,
    required this.routineId,
    required this.habitId,
    required this.order,
    required this.durationMinutes,
  });

  final String id;
  final String routineId;
  final String habitId;
  final int order;
  final int durationMinutes;

  factory RoutineStep.fromMap(Map<String, dynamic> map, {String? id}) {
    return RoutineStep(
      id: (map['id'] as String?) ?? id ?? '',
      routineId: (map['routineId'] as String?) ?? '',
      habitId: (map['habitId'] as String?) ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routineId': routineId,
      'habitId': habitId,
      'order': order,
      'durationMinutes': durationMinutes,
    };
  }
}
