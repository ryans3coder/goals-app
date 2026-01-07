enum RoutineEventType {
  routineStarted,
  stepCompleted,
  stepSkipped,
  routineCompleted,
}

class RoutineEvent {
  const RoutineEvent({
    required this.id,
    required this.type,
    required this.routineId,
    required this.timestamp,
    this.habitId,
  });

  final String id;
  final RoutineEventType type;
  final String routineId;
  final String? habitId;
  final DateTime timestamp;

  factory RoutineEvent.fromMap(Map<String, dynamic> map, {String? id}) {
    return RoutineEvent(
      id: (map['id'] as String?) ?? id ?? '',
      type: _parseType(map['type']),
      routineId: (map['routineId'] as String?) ?? '',
      habitId: (map['habitId'] as String?)?.trim(),
      timestamp: _parseDateTime(map['timestamp']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': _encodeType(type),
      'routineId': routineId,
      if (habitId != null) 'habitId': habitId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static RoutineEventType _parseType(dynamic value) {
    if (value is String) {
      for (final entry in _typeMap.entries) {
        if (entry.value == value) {
          return entry.key;
        }
      }
    }
    return RoutineEventType.routineStarted;
  }

  static String _encodeType(RoutineEventType type) {
    return _typeMap[type] ?? 'routine_started';
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

  static const Map<RoutineEventType, String> _typeMap = {
    RoutineEventType.routineStarted: 'routine_started',
    RoutineEventType.stepCompleted: 'step_completed',
    RoutineEventType.stepSkipped: 'step_skipped',
    RoutineEventType.routineCompleted: 'routine_completed',
  };
}
