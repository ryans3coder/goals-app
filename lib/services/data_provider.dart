import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/goal.dart';
import '../models/habit.dart';
import '../models/routine.dart';

typedef RemoteSync = Future<void> Function(Map<String, dynamic> payload);

class DataProvider extends ChangeNotifier {
  DataProvider({SharedPreferences? preferences, RemoteSync? remoteSync})
      : _preferences = preferences,
        _remoteSync = remoteSync,
        _random = Random() {
    unawaited(_initializeLocal());
  }

  final SharedPreferences? _preferences;
  final RemoteSync? _remoteSync;
  final Random _random;

  static const _habitsKey = 'local_habits';
  static const _routinesKey = 'local_routines';
  static const _goalsKey = 'local_goals';
  static const _routineHistoryKey = 'local_routine_history';

  final _habitsController = StreamController<List<Habit>>.broadcast();
  final _routinesController = StreamController<List<Routine>>.broadcast();
  final _goalsController = StreamController<List<Goal>>.broadcast();

  SharedPreferences? _resolvedPreferences;
  bool _localLoaded = false;

  final List<Habit> _habits = [];
  final List<Routine> _routines = [];
  final List<Goal> _goals = [];

  Future<void> _initializeLocal() async {
    await _loadLocalCache();
  }

  Future<SharedPreferences> _getPreferences() async {
    if (_resolvedPreferences != null) {
      return _resolvedPreferences!;
    }
    _resolvedPreferences =
        _preferences ?? await SharedPreferences.getInstance();
    return _resolvedPreferences!;
  }

  String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomSuffix = _random.nextInt(1000000).toString().padLeft(6, '0');
    return '$timestamp$randomSuffix';
  }

  Future<void> _loadLocalCache() async {
    if (_localLoaded) {
      return;
    }
    _localLoaded = true;

    final preferences = await _getPreferences();
    final habitsRaw = preferences.getString(_habitsKey);
    final routinesRaw = preferences.getString(_routinesKey);
    final goalsRaw = preferences.getString(_goalsKey);

    _habits
      ..clear()
      ..addAll(_decodeHabits(habitsRaw));
    _routines
      ..clear()
      ..addAll(_decodeRoutines(routinesRaw));
    _goals
      ..clear()
      ..addAll(_decodeGoals(goalsRaw));

    _emitAll();
    notifyListeners();
  }

  void _emitAll() {
    _emitHabits();
    _emitRoutines();
    _emitGoals();
  }

  void _emitHabits() {
    _habitsController.add(List.unmodifiable(_habits));
  }

  void _emitRoutines() {
    _routinesController.add(List.unmodifiable(_routines));
  }

  void _emitGoals() {
    _goalsController.add(List.unmodifiable(_goals));
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

  Future<void> _persistHabits() async {
    final preferences = await _getPreferences();
    final encoded = jsonEncode(_habits.map((habit) => habit.toMap()).toList());
    await preferences.setString(_habitsKey, encoded);
  }

  Future<void> _persistRoutines() async {
    final preferences = await _getPreferences();
    final encoded =
        jsonEncode(_routines.map((routine) => routine.toMap()).toList());
    await preferences.setString(_routinesKey, encoded);
  }

  Future<void> _persistGoals() async {
    final preferences = await _getPreferences();
    final encoded = jsonEncode(_goals.map((goal) => goal.toMap()).toList());
    await preferences.setString(_goalsKey, encoded);
  }

  Future<void> _saveLocalHabits() async {
    _emitHabits();
    notifyListeners();
    await _persistHabits();
  }

  Future<void> _saveLocalRoutines() async {
    _emitRoutines();
    notifyListeners();
    await _persistRoutines();
  }

  Future<void> _saveLocalGoals() async {
    _emitGoals();
    notifyListeners();
    await _persistGoals();
  }

  void _triggerRemoteSync() {
    unawaited(_syncRemote());
  }

  Future<void> _syncRemote() async {
    try {
      final remoteSync = _remoteSync;
      if (remoteSync == null) {
        return;
      }
      await remoteSync({
        'habits': _habits.map((habit) => habit.toMap()).toList(),
        'routines': _routines.map((routine) => routine.toMap()).toList(),
        'goals': _goals.map((goal) => goal.toMap()).toList(),
      });
    } catch (_) {}
  }

  Future<void> addHabit(Habit habit) async {
    await _loadLocalCache();
    final habitId = habit.id.isEmpty ? _generateId() : habit.id;
    final normalizedHabit = Habit(
      id: habitId,
      userId: habit.userId.isEmpty ? 'local' : habit.userId,
      title: habit.title,
      frequency: habit.frequency,
      currentStreak: habit.currentStreak,
      isCompletedToday: habit.isCompletedToday,
    );

    final index = _habits.indexWhere((item) => item.id == habitId);
    if (index >= 0) {
      _habits[index] = normalizedHabit;
    } else {
      _habits.add(normalizedHabit);
    }
    await _saveLocalHabits();
    _triggerRemoteSync();
  }

  Stream<List<Habit>> watchHabits() async* {
    await _loadLocalCache();
    yield List.unmodifiable(_habits);
    yield* _habitsController.stream;
  }

  Future<void> updateHabitCompletion({
    required Habit habit,
    required bool isCompletedToday,
  }) async {
    await _loadLocalCache();
    if (habit.id.isEmpty) {
      return;
    }
    final index = _habits.indexWhere((item) => item.id == habit.id);
    if (index < 0) {
      return;
    }

    final currentHabit = _habits[index];
    var updatedStreak = currentHabit.currentStreak;
    if (isCompletedToday && !currentHabit.isCompletedToday) {
      updatedStreak += 1;
    } else if (!isCompletedToday && currentHabit.isCompletedToday) {
      updatedStreak = updatedStreak > 0 ? updatedStreak - 1 : 0;
    }

    _habits[index] = Habit(
      id: currentHabit.id,
      userId: currentHabit.userId,
      title: currentHabit.title,
      frequency: currentHabit.frequency,
      currentStreak: updatedStreak,
      isCompletedToday: isCompletedToday,
    );

    await _saveLocalHabits();
    _triggerRemoteSync();
  }

  Future<void> addRoutine(Routine routine) async {
    await _loadLocalCache();
    final routineId = routine.id.isEmpty ? _generateId() : routine.id;
    final normalizedRoutine = Routine(
      id: routineId,
      userId: routine.userId.isEmpty ? 'local' : routine.userId,
      title: routine.title,
      icon: routine.icon,
      triggerTime: routine.triggerTime,
      steps: routine.steps,
    );

    final index = _routines.indexWhere((item) => item.id == routineId);
    if (index >= 0) {
      _routines[index] = normalizedRoutine;
    } else {
      _routines.add(normalizedRoutine);
    }
    await _saveLocalRoutines();
    _triggerRemoteSync();
  }

  Stream<List<Routine>> watchRoutines() async* {
    await _loadLocalCache();
    yield List.unmodifiable(_routines);
    yield* _routinesController.stream;
  }

  Future<void> addRoutineHistory({
    required Routine routine,
    DateTime? completedAt,
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
      'id': _generateId(),
      'routineId': routine.id,
      'routineTitle': routine.title,
      'completedAt': (completedAt ?? DateTime.now()).toIso8601String(),
      'steps': routine.steps,
    });

    await preferences.setString(_routineHistoryKey, jsonEncode(historyList));
  }

  Future<void> addGoal(Goal goal) async {
    await _loadLocalCache();
    final goalId = goal.id.isEmpty ? _generateId() : goal.id;
    final normalizedGoal = Goal(
      id: goalId,
      userId: goal.userId.isEmpty ? 'local' : goal.userId,
      title: goal.title,
      reason: goal.reason,
      deadline: goal.deadline,
      milestones: goal.milestones,
    );

    final index = _goals.indexWhere((item) => item.id == goalId);
    if (index >= 0) {
      _goals[index] = normalizedGoal;
    } else {
      _goals.add(normalizedGoal);
    }
    await _saveLocalGoals();
    _triggerRemoteSync();
  }

  Stream<List<Goal>> watchGoals() async* {
    await _loadLocalCache();
    yield List.unmodifiable(_goals);
    yield* _goalsController.stream;
  }

  Future<void> updateGoalMilestones({
    required Goal goal,
  }) async {
    await _loadLocalCache();
    if (goal.id.isEmpty) {
      return;
    }

    final index = _goals.indexWhere((item) => item.id == goal.id);
    if (index < 0) {
      return;
    }

    final currentGoal = _goals[index];
    _goals[index] = Goal(
      id: currentGoal.id,
      userId: currentGoal.userId,
      title: currentGoal.title,
      reason: currentGoal.reason,
      deadline: currentGoal.deadline,
      milestones: goal.milestones,
    );

    await _saveLocalGoals();
    _triggerRemoteSync();
  }
}
