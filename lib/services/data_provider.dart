import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/local/local_persistence.dart';
import '../domain/use_cases/category_use_cases.dart';
import '../domain/use_cases/goal_use_cases.dart';
import '../domain/use_cases/habit_use_cases.dart';
import '../domain/use_cases/routine_step_use_cases.dart';
import '../domain/use_cases/routine_use_cases.dart';
import '../models/category.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/milestone.dart';
import '../models/routine.dart';
import '../models/routine_step.dart';
import 'local_data_store.dart';
import 'remote_sync_service.dart';

class DataProvider extends ChangeNotifier {
  DataProvider({
    LocalPersistence? localPersistence,
    LocalDataStore? localStore,
    RemoteSyncService? remoteSync,
  })  : _localPersistence =
            localPersistence ?? LocalPersistence(legacyStore: localStore),
        _localStore = localStore ?? LocalDataStore(),
        _remoteSync = remoteSync ?? NoopRemoteSyncService(),
        _random = Random() {
    _loadFuture = _loadLocalCache();
  }

  final LocalPersistence _localPersistence;
  final LocalDataStore _localStore;
  final RemoteSyncService _remoteSync;
  final Random _random;

  late final HabitUseCases _habitUseCases =
      HabitUseCases(_localPersistence.habits);
  late final RoutineUseCases _routineUseCases =
      RoutineUseCases(_localPersistence.routines);
  late final RoutineStepUseCases _routineStepUseCases =
      RoutineStepUseCases(_localPersistence.routineSteps);
  late final GoalUseCases _goalUseCases =
      GoalUseCases(_localPersistence.goals);
  late final CategoryUseCases _categoryUseCases =
      CategoryUseCases(_localPersistence.categories);

  final _habitsController = StreamController<List<Habit>>.broadcast();
  final _routinesController = StreamController<List<Routine>>.broadcast();
  final _goalsController = StreamController<List<Goal>>.broadcast();
  final _categoriesController = StreamController<List<Category>>.broadcast();

  final List<Habit> _habits = [];
  final List<Routine> _routines = [];
  final List<Goal> _goals = [];
  final List<Category> _categories = [];
  final List<RoutineStep> _routineSteps = [];

  late final Future<void> _loadFuture;
  Future<void> _writeQueue = Future.value();
  bool _disposed = false;

  Future<void> _loadLocalCache() async {
    try {
      await _localPersistence.initialize();
      _habits
        ..clear()
        ..addAll(await _habitUseCases.fetchAll().then(_cloneHabits));
      _routines
        ..clear()
        ..addAll(await _routineUseCases.fetchAll().then(_cloneRoutines));
      _goals
        ..clear()
        ..addAll(await _goalUseCases.fetchAll().then(_cloneGoals));
      _categories
        ..clear()
        ..addAll(await _categoryUseCases.fetchAll().then(_cloneCategories));
      _routineSteps
        ..clear()
        ..addAll(await _routineStepUseCases.fetchAll().then(_cloneSteps));
      _emitAll();
      notifyListeners();
    } catch (error) {
      debugPrint('Falha ao carregar dados locais: $error');
    }
  }

  Future<void> _ensureLoaded() => _loadFuture;

  String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomSuffix = _random.nextInt(1000000).toString().padLeft(6, '0');
    return '$timestamp$randomSuffix';
  }

  void _emitAll() {
    _emitHabits();
    _emitRoutines();
    _emitGoals();
    _emitCategories();
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

  void _emitCategories() {
    if (_categoriesController.isClosed) {
      return;
    }
    _categoriesController.add(List.unmodifiable(_categories.map(_cloneCategory)));
  }

  Future<void> _saveLocalState({
    Future<void> Function()? persist,
  }) async {
    if (_disposed) {
      return;
    }
    _emitAll();
    notifyListeners();
    if (persist != null) {
      await _queuePersist(persist);
    }
  }

  Future<void> _queuePersist(Future<void> Function() action) {
    _writeQueue = _writeQueue.then((_) async {
      try {
        await action();
      } catch (error) {
        debugPrint('Falha ao persistir dados locais: $error');
      }
    });
    return _writeQueue;
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
      categoryId: habit.categoryId,
    );
  }

  List<Habit> _cloneHabits(List<Habit> habits) {
    return habits.map(_cloneHabit).toList();
  }

  Routine _cloneRoutine(Routine routine) {
    return Routine(
      id: routine.id,
      userId: routine.userId,
      title: routine.title,
      icon: routine.icon,
      triggerTime: routine.triggerTime,
      steps: routine.steps,
      categoryId: routine.categoryId,
    );
  }

  List<Routine> _cloneRoutines(List<Routine> routines) {
    return routines.map(_cloneRoutine).toList();
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
      specific: goal.specific,
      measurable: goal.measurable,
      achievable: goal.achievable,
      relevant: goal.relevant,
      timeBound: goal.timeBound,
      categoryId: goal.categoryId,
    );
  }

  List<Goal> _cloneGoals(List<Goal> goals) {
    return goals.map(_cloneGoal).toList();
  }

  Category _cloneCategory(Category category) {
    return Category(
      id: category.id,
      userId: category.userId,
      title: category.title,
      colorHex: category.colorHex,
      icon: category.icon,
    );
  }

  List<Category> _cloneCategories(List<Category> categories) {
    return categories.map(_cloneCategory).toList();
  }

  RoutineStep _cloneRoutineStep(RoutineStep step) {
    return RoutineStep(
      id: step.id,
      routineId: step.routineId,
      habitId: step.habitId,
      order: step.order,
      durationMinutes: step.durationMinutes,
    );
  }

  List<RoutineStep> _cloneSteps(List<RoutineStep> steps) {
    return steps.map(_cloneRoutineStep).toList();
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
      categoryId: habit.categoryId,
    );

    final index = _habits.indexWhere((item) => item.id == habitId);
    if (index >= 0) {
      _habits[index] = normalizedHabit;
    } else {
      _habits.add(normalizedHabit);
    }
    await _saveLocalState(
      persist: () => _habitUseCases.upsert(normalizedHabit),
    );
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
    final updatedHabit = _habitUseCases.updateCompletion(
      habit: currentHabit,
      isCompletedToday: isCompletedToday,
    );
    _habits[index] = updatedHabit;

    await _saveLocalState(
      persist: () => _habitUseCases.upsert(updatedHabit),
    );
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
      categoryId: routine.categoryId,
    );

    final index = _routines.indexWhere((item) => item.id == routineId);
    if (index >= 0) {
      _routines[index] = normalizedRoutine;
    } else {
      _routines.add(normalizedRoutine);
    }
    await _saveLocalState(
      persist: () => _routineUseCases.upsert(normalizedRoutine),
    );
    await _persistRoutineStepsFromStrings(
      routineId: normalizedRoutine.id,
      steps: normalizedRoutine.steps,
    );
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
    try {
      await _localStore.addRoutineHistory(
        routine: routine,
        completedAt: completedAt,
        historyId: _generateId(),
      );
    } catch (error) {
      debugPrint('Falha ao salvar histórico da rotina: $error');
    }
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
      specific: goal.specific,
      measurable: goal.measurable,
      achievable: goal.achievable,
      relevant: goal.relevant,
      timeBound: goal.timeBound,
      categoryId: goal.categoryId,
    );

    final index = _goals.indexWhere((item) => item.id == goalId);
    if (index >= 0) {
      _goals[index] = normalizedGoal;
    } else {
      _goals.add(normalizedGoal);
    }
    await _saveLocalState(
      persist: () => _goalUseCases.upsert(normalizedGoal),
    );
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
    final updatedGoal = Goal(
      id: currentGoal.id,
      userId: currentGoal.userId,
      title: currentGoal.title,
      reason: currentGoal.reason,
      deadline: currentGoal.deadline,
      milestones: goal.milestones.map(_cloneMilestone).toList(),
      specific: currentGoal.specific,
      measurable: currentGoal.measurable,
      achievable: currentGoal.achievable,
      relevant: currentGoal.relevant,
      timeBound: currentGoal.timeBound,
      categoryId: currentGoal.categoryId,
    );
    _goals[index] = updatedGoal;

    await _saveLocalState(
      persist: () => _goalUseCases.upsert(updatedGoal),
    );
    _scheduleRemoteSync();
  }

  Stream<List<Category>> watchCategories() async* {
    await _ensureLoaded();
    yield List.unmodifiable(_categories.map(_cloneCategory));
    yield* _categoriesController.stream;
  }

  Future<void> addCategory(Category category) async {
    await _ensureLoaded();
    final categoryId = category.id.isEmpty ? _generateId() : category.id;
    final normalizedCategory = Category(
      id: categoryId,
      userId: category.userId.isEmpty ? 'local' : category.userId,
      title: category.title,
      colorHex: category.colorHex,
      icon: category.icon,
    );

    final index = _categories.indexWhere((item) => item.id == categoryId);
    if (index >= 0) {
      _categories[index] = normalizedCategory;
    } else {
      _categories.add(normalizedCategory);
    }

    await _saveLocalState(
      persist: () => _categoryUseCases.upsert(normalizedCategory),
    );
  }

  Future<void> updateRoutineSteps({
    required String routineId,
    required List<RoutineStep> steps,
  }) async {
    await _ensureLoaded();
    await _persistRoutineSteps(routineId: routineId, steps: steps);
  }

  Future<void> _persistRoutineSteps({
    required String routineId,
    required List<RoutineStep> steps,
  }) async {
    final preparedSteps = <RoutineStep>[];
    preparedSteps.addAll(steps);

    _routineSteps
      ..removeWhere((item) => item.routineId == routineId)
      ..addAll(preparedSteps.map(_cloneRoutineStep));

    await _saveLocalState(
      persist: () async {
        await _routineStepUseCases.deleteByRoutineId(routineId);
        if (preparedSteps.isNotEmpty) {
          await _routineStepUseCases.upsertAll(preparedSteps);
        }
      },
    );
  }

  Future<void> _persistRoutineStepsFromStrings({
    required String routineId,
    required List<String> steps,
  }) async {
    final preparedSteps = <RoutineStep>[];
    if (steps.isNotEmpty) {
      for (int index = 0; index < steps.length; index++) {
        preparedSteps.add(
          RoutineStep(
            id: _generateId(),
            routineId: routineId,
            habitId: steps[index],
            order: index,
            durationMinutes: 0,
          ),
        );
      }
    }
    await _persistRoutineSteps(routineId: routineId, steps: preparedSteps);
  }

  @override
  void dispose() {
    _disposed = true;
    _habitsController.close();
    _routinesController.close();
    _goalsController.close();
    _categoriesController.close();
    super.dispose();
  }
}
