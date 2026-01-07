class RoutineStep {
  const RoutineStep({
    required this.id,
    required this.routineId,
    required this.habitId,
    required this.order,
    required this.durationSeconds,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String routineId;
  final String habitId;
  final int order;
  final int durationSeconds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory RoutineStep.fromMap(Map<String, dynamic> map, {String? id}) {
    final durationSeconds = (map['durationSeconds'] as num?)?.toInt();
    final durationMinutes = (map['durationMinutes'] as num?)?.toInt();
    return RoutineStep(
      id: (map['id'] as String?) ?? id ?? '',
      routineId: (map['routineId'] as String?) ?? '',
      habitId: (map['habitId'] as String?) ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
      durationSeconds:
          durationSeconds ?? (durationMinutes != null ? durationMinutes * 60 : 0),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routineId': routineId,
      'habitId': habitId,
      'order': order,
      'durationSeconds': durationSeconds,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
