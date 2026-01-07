import 'goal.dart';
import 'habit.dart';
import 'habit_category.dart';
import 'feedback_preferences.dart';
import 'routine.dart';
import 'routine_event.dart';
import 'routine_step.dart';

class BackupSnapshot {
  BackupSnapshot({
    required this.schemaVersion,
    required this.timestamp,
    required this.habits,
    required this.routines,
    required this.routineSteps,
    required this.goals,
    required this.categories,
    required this.feedbackPreferences,
    required this.routineEvents,
  });

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final DateTime timestamp;
  final List<Habit> habits;
  final List<Routine> routines;
  final List<RoutineStep> routineSteps;
  final List<Goal> goals;
  final List<HabitCategory> categories;
  final FeedbackPreferences feedbackPreferences;
  final List<RoutineEvent> routineEvents;

  Map<String, dynamic> toMap() {
    return {
      'schemaVersion': schemaVersion,
      'timestamp': timestamp.toIso8601String(),
      'habits': habits.map((habit) => habit.toMap()).toList(),
      'routines': routines.map((routine) => routine.toMap()).toList(),
      'routineSteps': routineSteps.map((step) => step.toMap()).toList(),
      'goals': goals.map((goal) => goal.toMap()).toList(),
      'categories': categories.map((category) => category.toMap()).toList(),
      'feedbackPreferences': feedbackPreferences.toMap(),
      'routineEvents': routineEvents.map((event) => event.toMap()).toList(),
    };
  }

  factory BackupSnapshot.fromMap(Map<String, dynamic> map) {
    return BackupSnapshot(
      schemaVersion: (map['schemaVersion'] as int?) ?? 0,
      timestamp: _parseTimestamp(map['timestamp']),
      habits: _decodeList(map['habits'], Habit.fromMap),
      routines: _decodeList(map['routines'], Routine.fromMap),
      routineSteps: _decodeList(map['routineSteps'], RoutineStep.fromMap),
      goals: _decodeList(map['goals'], Goal.fromMap),
      categories: _decodeList(map['categories'], HabitCategory.fromMap),
      feedbackPreferences: _decodeFeedbackPreferences(
        map['feedbackPreferences'],
      ),
      routineEvents: _decodeList(map['routineEvents'], RoutineEvent.fromMap),
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static FeedbackPreferences _decodeFeedbackPreferences(dynamic value) {
    if (value is Map) {
      return FeedbackPreferences.fromMap(Map<String, dynamic>.from(value));
    }
    return FeedbackPreferences.defaults();
  }

  static List<T> _decodeList<T>(
    dynamic value,
    T Function(Map<String, dynamic> map) factory,
  ) {
    if (value is! List) {
      return [];
    }
    return value
        .whereType<Map>()
        .map((item) => factory(Map<String, dynamic>.from(item)))
        .toList();
  }
}
