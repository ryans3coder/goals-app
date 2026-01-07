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
    this.stepIndex,
    this.metadata,
  });

  final String id;
  final RoutineEventType type;
  final String routineId;
  final String? habitId;
  final DateTime timestamp;
  final int? stepIndex;
  final Map<String, dynamic>? metadata;

  factory RoutineEvent.fromMap(Map<String, dynamic> map, {String? id}) {
    return RoutineEvent(
      id: (map['id'] as String?) ?? id ?? '',
      type: _parseType(map['type']),
      routineId: (map['routineId'] as String?) ?? '',
      habitId: (map['habitId'] as String?)?.trim(),
      stepIndex: _parseStepIndex(map['stepIndex']),
      metadata: _parseMetadata(map['metadata']),
      timestamp: _parseDateTime(map['timestamp']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': _encodeType(type),
      'routineId': routineId,
      if (habitId != null) 'habitId': habitId,
      if (stepIndex != null) 'stepIndex': stepIndex,
      if (metadata != null) 'metadata': metadata,
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

  static String encodeType(RoutineEventType type) => _encodeType(type);

  static DateTime? _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static int? _parseStepIndex(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return int.tryParse(value);
    }
    return null;
  }

  static Map<String, dynamic>? _parseMetadata(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
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
