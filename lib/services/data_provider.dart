import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/goal.dart';
import '../models/habit.dart';
import '../models/milestone.dart';
import '../models/routine.dart';
import 'local_data_store.dart';
import 'remote_sync_service.dart';

class DataProvider extends ChangeNotifier {
  DataProvider({
    LocalDataStore? localStore,
    RemoteSyncService? remoteSync,
  })  : _localStore = localStore ?? LocalDataStore(),
        _remoteSync = remoteSync ?? NoopRemoteSyncService(),
        _random = Random() {
    _loadFuture = _loadLocalCache();
  }

  final LocalDataStore _localStore;
  final RemoteSyncService _remoteSync;
  final Random _random;

  final _habitsController = StreamController<List<Habit>>.broadcast();
  final _routinesController = StreamController<List<Routine>>.broadcast();
  final _goalsController = StreamController<List<Goal>>.broadcast();

  final List<Habit> _habits = [];
  final List<Routine> _routines = [];
  final List<Goal> _goals = [];

  late final Future<void> _loadFuture;
  Future<void> _writeQueue = Future.value();
  bool _disposed = false;

  Future<void> _loadLocalCache() async {
    try {
      final snapshot = await _localStore.loadSnapshot();
      _hydrate(snapshot);
      _emitAll();
      notifyListeners();
    } catch (error) {
      debugPrint('Falha ao carregar dados locais: $error');
    }
  }

  Future<void> _ensureLoaded() => _loadFuture;

  void _hydrate(LocalSnapshot snapshot) {
    _habits
      ..clear()
      ..addAll(snapshot.habits.map(_cloneHabit));
    _routines
      ..clear()
      ..addAll(snapshot.routines.map(_cloneRoutine));
    _goals
      ..clear()
      ..addAll(snapshot.goals.map(_cloneGoal));
  }

  String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomSuffix = _random.nextInt(1000000).toString().padLeft(6, '0');
    return '$timestamp$randomSuffix';
  }

  void _emitAll() {
    _emitHabits();
    _emitRoutines();
    _emitGoals();
  }

  void _emitHabits() {
    if (_habitsController.isClosed) {
      return;
    }
    _habitsController.add(List.unmodifiable(_habits.map(_cloneHabit)));
  }

  void _emitRoutines() {
    if (_routinesController.isClosed) {
      return;
    }
    _routinesController.add(List.unmodifiable(_routines.map(_cloneRoutine)));
  }

  void _emitGoals() {
    if (_goalsController.isClosed) {
      return;
    }
    _goalsController.add(List.unmodifiable(_goals.map(_cloneGoal)));
  }

  Future<void> _saveLocalState() async {
    if (_disposed) {
      return;
    }
    _emitAll();
    notifyListeners();
    await _queuePersist();
  }

  Future<void> _queuePersist() {
    _writeQueue = _writeQueue.then((_) => _persistSnapshot());
    return _writeQueue;
  }

  Future<void> _persistSnapshot() async {
    await _localStore.saveSnapshot(_snapshot());
  }

  void _scheduleRemoteSync() {
    final snapshot = _snapshot();
    unawaited(_remoteSync.enqueueSync(snapshot));
  }

  LocalSnapshot _snapshot() {
    return LocalSnapshot(
      habits: _habits.map(_cloneHabit).toList(),
      routines: _routines.map(_cloneRoutine).toList(),
      goals: _goals.map(_cloneGoal).toList(),
    );
  }

  Habit _cloneHabit(Habit habit) {
    return Habit(
      id: habit.id,
      userId: habit.userId,
      title: habit.title,
      frequency: habit.frequency,
      currentStreak: habit.currentStreak,
      isCompletedToday: habit.isCompletedToday,
    );
  }

  Routine _cloneRoutine(Routine routine) {
    return Routine(
      id: routine.id,
      userId: routine.userId,
      title: routine.title,
      icon: routine.icon,
      triggerTime: routine.triggerTime,
      steps: routine.steps,
    );
  }

  Milestone _cloneMilestone(Milestone milestone) {
    return Milestone(
      title: milestone.title,
      isCompleted: milestone.isCompleted,
    );
  }

  Goal _cloneGoal(Goal goal) {
    return Goal(
      id: goal.id,
      userId: goal.userId,
      title: goal.title,
      reason: goal.reason,
      deadline: goal.deadline,
      milestones: goal.milestones.map(_cloneMilestone).toList(),
    );
  }

  Future<void> addHabit(Habit habit) async {
    await _ensureLoaded();
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
    await _saveLocalState();
    _scheduleRemoteSync();
  }

  Stream<List<Habit>> watchHabits() async* {
    await _ensureLoaded();
    yield List.unmodifiable(_habits.map(_cloneHabit));
    yield* _habitsController.stream;
  }

  Future<void> updateHabitCompletion({
    required Habit habit,
    required bool isCompletedToday,
  }) async {
    await _ensureLoaded();
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

    await _saveLocalState();
    _scheduleRemoteSync();
  }

  Future<void> addRoutine(Routine routine) async {
    await _ensureLoaded();
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
    await _saveLocalState();
    _scheduleRemoteSync();
  }

  Stream<List<Routine>> watchRoutines() async* {
    await _ensureLoaded();
    yield List.unmodifiable(_routines.map(_cloneRoutine));
    yield* _routinesController.stream;
  }

  Future<void> addRoutineHistory({
    required Routine routine,
    DateTime? completedAt,
  }) async {
    await _ensureLoaded();
    await _localStore.addRoutineHistory(
      routine: routine,
      completedAt: completedAt,
      historyId: _generateId(),
    );
  }

  Future<void> addGoal(Goal goal) async {
    await _ensureLoaded();
    final goalId = goal.id.isEmpty ? _generateId() : goal.id;
    final normalizedGoal = Goal(
      id: goalId,
      userId: goal.userId.isEmpty ? 'local' : goal.userId,
      title: goal.title,
      reason: goal.reason,
      deadline: goal.deadline,
      milestones: goal.milestones.map(_cloneMilestone).toList(),
    );

    final index = _goals.indexWhere((item) => item.id == goalId);
    if (index >= 0) {
      _goals[index] = normalizedGoal;
    } else {
      _goals.add(normalizedGoal);
    }
    await _saveLocalState();
    _scheduleRemoteSync();
  }

  Stream<List<Goal>> watchGoals() async* {
    await _ensureLoaded();
    yield List.unmodifiable(_goals.map(_cloneGoal));
    yield* _goalsController.stream;
  }

  Future<void> updateGoalMilestones({
    required Goal goal,
  }) async {
    await _ensureLoaded();
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
      milestones: goal.milestones.map(_cloneMilestone).toList(),
    );

    await _saveLocalState();
    _scheduleRemoteSync();
  }

  @override
  void dispose() {
    _disposed = true;
    _habitsController.close();
    _routinesController.close();
    _goalsController.close();
    super.dispose();
  }
}
