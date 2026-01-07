import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/goal.dart';
import '../models/habit.dart';
import '../models/feedback_preferences.dart';
import '../models/routine.dart';
import '../models/routine_event.dart';

class LocalSnapshot {
  const LocalSnapshot({
    required this.habits,
    required this.routines,
    required this.goals,
  });

  final List<Habit> habits;
  final List<Routine> routines;
  final List<Goal> goals;
}

class LocalDataStore {
  LocalDataStore({SharedPreferences? preferences})
      : _preferences = preferences;

  static const _habitsKey = 'local_habits';
  static const _routinesKey = 'local_routines';
  static const _goalsKey = 'local_goals';
  static const _routineHistoryKey = 'local_routine_history';
  static const _routineEventsKey = 'local_routine_events';
  static const _feedbackPreferencesKey = 'feedback_preferences';

  final SharedPreferences? _preferences;
  SharedPreferences? _resolvedPreferences;

  Future<SharedPreferences> _getPreferences() async {
    if (_resolvedPreferences != null) {
      return _resolvedPreferences!;
    }
    _resolvedPreferences =
        _preferences ?? await SharedPreferences.getInstance();
    return _resolvedPreferences!;
  }

  Future<LocalSnapshot> loadSnapshot() async {
    final preferences = await _getPreferences();
    final habitsRaw = preferences.getString(_habitsKey);
    final routinesRaw = preferences.getString(_routinesKey);
    final goalsRaw = preferences.getString(_goalsKey);

    return LocalSnapshot(
      habits: _decodeHabits(habitsRaw),
      routines: _decodeRoutines(routinesRaw),
      goals: _decodeGoals(goalsRaw),
    );
  }

  Future<void> saveSnapshot(LocalSnapshot snapshot) async {
    final preferences = await _getPreferences();
    await preferences.setString(
      _habitsKey,
      jsonEncode(snapshot.habits.map((habit) => habit.toMap()).toList()),
    );
    await preferences.setString(
      _routinesKey,
      jsonEncode(snapshot.routines.map((routine) => routine.toMap()).toList()),
    );
    await preferences.setString(
      _goalsKey,
      jsonEncode(snapshot.goals.map((goal) => goal.toMap()).toList()),
    );
  }

  Future<void> addRoutineHistory({
    required Routine routine,
    DateTime? completedAt,
    required String historyId,
  }) async {
    final preferences = await _getPreferences();
    final raw = preferences.getString(_routineHistoryKey);
    final historyList = <Map<String, dynamic>>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              historyList.add(Map<String, dynamic>.from(item));
            }
          }
        }
      } catch (_) {}
    }

    historyList.add({
      'id': historyId,
      'routineId': routine.id,
      'routineTitle': routine.title,
      'completedAt': (completedAt ?? DateTime.now()).toIso8601String(),
      'steps': routine.steps,
    });

    await preferences.setString(_routineHistoryKey, jsonEncode(historyList));
  }

  Future<void> addRoutineEvent(RoutineEvent event) async {
    final preferences = await _getPreferences();
    final raw = preferences.getString(_routineEventsKey);
    final events = _decodeRoutineEvents(raw);
    if (events.any((item) => item.id == event.id)) {
      return;
    }
    events.add(event);
    await preferences.setString(
      _routineEventsKey,
      jsonEncode(events.map((item) => item.toMap()).toList()),
    );
  }

  Future<void> addRoutineEventIfAbsent({
    required RoutineEvent event,
    required String dedupeKey,
  }) async {
    final preferences = await _getPreferences();
    final raw = preferences.getString(_routineEventsKey);
    final events = _decodeRoutineEvents(raw);
    if (events.any((item) => item.id == event.id)) {
      return;
    }
    if (events.any((item) => _eventDedupeKey(item) == dedupeKey)) {
      return;
    }
    events.add(event);
    await preferences.setString(
      _routineEventsKey,
      jsonEncode(events.map((item) => item.toMap()).toList()),
    );
  }

  Future<FeedbackPreferences> loadFeedbackPreferences() async {
    final preferences = await _getPreferences();
    final raw = preferences.getString(_feedbackPreferencesKey);
    if (raw == null || raw.isEmpty) {
      final defaults = FeedbackPreferences.defaults();
      await saveFeedbackPreferences(defaults);
      return defaults;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return FeedbackPreferences.fromMap(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {}
    final fallback = FeedbackPreferences.defaults();
    await saveFeedbackPreferences(fallback);
    return fallback;
  }

  Future<void> saveFeedbackPreferences(FeedbackPreferences preferences) async {
    final storage = await _getPreferences();
    await storage.setString(
      _feedbackPreferencesKey,
      jsonEncode(preferences.toMap()),
    );
  }

  List<RoutineEvent> loadRoutineEvents() {
    final raw = _resolvedPreferences?.getString(_routineEventsKey);
    return _decodeRoutineEvents(raw);
  }

  List<RoutineEvent> loadRoutineEventsByType(
    RoutineEventType type,
  ) {
    final events = loadRoutineEvents();
    return events.where((event) => event.type == type).toList();
  }

  List<RoutineEvent> loadRoutineEventsByDateRange({
    required DateTime start,
    required DateTime end,
  }) {
    final events = loadRoutineEvents();
    return events
        .where(
          (event) =>
              !event.timestamp.isBefore(start) &&
              !event.timestamp.isAfter(end),
        )
        .toList();
  }

  List<Habit> _decodeHabits(String? raw) {
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      return decoded
          .whereType<Map>()
          .map((item) => Habit.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<Routine> _decodeRoutines(String? raw) {
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      return decoded
          .whereType<Map>()
          .map((item) => Routine.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<Goal> _decodeGoals(String? raw) {
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      return decoded
          .whereType<Map>()
          .map((item) => Goal.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<RoutineEvent> _decodeRoutineEvents(String? raw) {
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }
      return decoded
          .whereType<Map>()
          .map((item) => RoutineEvent.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  String _eventDedupeKey(RoutineEvent event) {
    final type = RoutineEvent.encodeType(event.type);
    return [
      type,
      event.routineId,
      event.habitId ?? '',
      event.stepIndex?.toString() ?? '',
      _resolveExecutionId(event),
    ].join('|');
  }

  String _resolveExecutionId(RoutineEvent event) {
    if (event.executionId != null && event.executionId!.isNotEmpty) {
      return event.executionId!;
    }
    final metadataValue = event.metadata?['executionId'];
    return metadataValue?.toString() ?? '';
  }
}
