import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/local/local_persistence.dart';
import '../domain/habits/habit_category_defaults.dart';
import '../domain/use_cases/habit_category_use_cases.dart';
import '../domain/use_cases/goal_use_cases.dart';
import '../domain/use_cases/habit_use_cases.dart';
import '../domain/use_cases/routine_step_use_cases.dart';
import '../domain/use_cases/routine_use_cases.dart';
import '../domain/habits/habit_form_options.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import '../models/milestone.dart';
import '../models/routine.dart';
import '../models/routine_event.dart';
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
  late final HabitCategoryUseCases _categoryUseCases =
      HabitCategoryUseCases(_localPersistence.categories);

  final _habitsController = StreamController<List<Habit>>.broadcast();
  final _routinesController = StreamController<List<Routine>>.broadcast();
  final _goalsController = StreamController<List<Goal>>.broadcast();
  final _categoriesController =
      StreamController<List<HabitCategory>>.broadcast();

  final List<Habit> _habits = [];
  final List<Routine> _routines = [];
  final List<Goal> _goals = [];
  final List<HabitCategory> _categories = [];
  final List<RoutineStep> _routineSteps = [];

  late final Future<void> _loadFuture;
  Future<void> _writeQueue = Future.value();
  bool _disposed = false;

  Future<void> _loadLocalCache() async {
    try {
      await _localPersistence.initialize();
      await _categoryUseCases.seedDefaults(buildDefaultHabitCategories());
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

  List<Habit> get habits => List.unmodifiable(_habits.map(_cloneHabit));

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
      emoji: habit.emoji,
      description: habit.description,
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

  HabitCategory _cloneCategory(HabitCategory category) {
    return HabitCategory(
      id: category.id,
      name: category.name,
      emoji: category.emoji,
      colorToken: category.colorToken,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
  }

  List<HabitCategory> _cloneCategories(List<HabitCategory> categories) {
    return categories.map(_cloneCategory).toList();
  }

  RoutineStep _cloneRoutineStep(RoutineStep step) {
    return RoutineStep(
      id: step.id,
      routineId: step.routineId,
      habitId: step.habitId,
      order: step.order,
      durationSeconds: step.durationSeconds,
      createdAt: step.createdAt,
      updatedAt: step.updatedAt,
    );
  }

  List<RoutineStep> _cloneSteps(List<RoutineStep> steps) {
    return steps.map(_cloneRoutineStep).toList();
  }
  Future<void> addHabit(Habit habit) async {
    await _ensureLoaded();
    final habitId = habit.id.isEmpty ? _generateId() : habit.id;
    final frequency = habit.frequency.isNotEmpty
        ? habit.frequency
        : HabitFormOptions.defaultFrequency;
    final normalizedCategoryId = habit.categoryId?.trim();
    final categoryId =
        normalizedCategoryId == null || normalizedCategoryId.isEmpty
            ? null
            : normalizedCategoryId;
    final normalizedHabit = Habit(
      id: habitId,
      userId: habit.userId.isEmpty ? 'local' : habit.userId,
      title: habit.title,
      frequency: frequency,
      currentStreak: habit.currentStreak,
      isCompletedToday: habit.isCompletedToday,
      categoryId: categoryId,
      emoji: habit.emoji,
      description: habit.description,
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

  Future<void> deleteHabit(Habit habit) async {
    await _ensureLoaded();
    if (habit.id.isEmpty) {
      return;
    }
    _habits.removeWhere((item) => item.id == habit.id);
    await _saveLocalState(
      persist: () => _habitUseCases.deleteById(habit.id),
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

  Future<void> addRoutineEvent({
    required RoutineEventType type,
    required String routineId,
    String? habitId,
    DateTime? timestamp,
  }) async {
    await _ensureLoaded();
    try {
      await _localStore.addRoutineEvent(
        RoutineEvent(
          id: _generateId(),
          type: type,
          routineId: routineId,
          habitId: habitId,
          timestamp: timestamp ?? DateTime.now(),
        ),
      );
    } catch (error) {
      debugPrint('Falha ao salvar evento da rotina: $error');
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

  List<HabitCategory> get categories =>
      List.unmodifiable(_categories.map(_cloneCategory));

  List<RoutineStep> routineStepsByRoutineId(String routineId) {
    final steps = _routineSteps
        .where((item) => item.routineId == routineId)
        .map(_cloneRoutineStep)
        .toList();
    steps.sort((a, b) => a.order.compareTo(b.order));
    return List.unmodifiable(steps);
  }

  Stream<List<HabitCategory>> watchCategories() async* {
    await _ensureLoaded();
    yield List.unmodifiable(_categories.map(_cloneCategory));
    yield* _categoriesController.stream;
  }

  Future<void> addCategory(HabitCategory category) async {
    await _ensureLoaded();
    final categoryId = category.id.isEmpty ? _generateId() : category.id;
    final now = DateTime.now();
    final existingIndex = _categories.indexWhere(
      (item) => item.id == categoryId,
    );
    final existing = existingIndex >= 0 ? _categories[existingIndex] : null;
    final normalizedCategory = HabitCategory(
      id: categoryId,
      name: category.name.trim(),
      emoji: category.emoji.trim(),
      colorToken: category.colorToken,
      createdAt: existing?.createdAt ?? category.createdAt ?? now,
      updatedAt: now,
    );

    if (existingIndex >= 0) {
      _categories[existingIndex] = normalizedCategory;
    } else {
      _categories.add(normalizedCategory);
    }

    await _saveLocalState(
      persist: () => _categoryUseCases.upsert(normalizedCategory),
    );
  }

  Future<void> deleteCategory(HabitCategory category) async {
    await _ensureLoaded();
    if (category.id.isEmpty) {
      return;
    }
    _categories.removeWhere((item) => item.id == category.id);

    final updatedHabits = <Habit>[];
    for (final habit in _habits) {
      if (habit.categoryId == category.id) {
        updatedHabits.add(
          Habit(
            id: habit.id,
            userId: habit.userId,
            title: habit.title,
            frequency: habit.frequency,
            currentStreak: habit.currentStreak,
            isCompletedToday: habit.isCompletedToday,
            categoryId: null,
            emoji: habit.emoji,
            description: habit.description,
          ),
        );
      }
    }

    if (updatedHabits.isNotEmpty) {
      for (final habit in updatedHabits) {
        final index = _habits.indexWhere((item) => item.id == habit.id);
        if (index >= 0) {
          _habits[index] = habit;
        }
      }
    }

    await _saveLocalState(
      persist: () async {
        await _categoryUseCases.deleteById(category.id);
        for (final habit in updatedHabits) {
          await _habitUseCases.upsert(habit);
        }
      },
    );

    _scheduleRemoteSync();
  }

  Future<void> updateRoutineSteps({
    required String routineId,
    required List<RoutineStep> steps,
  }) async {
    await _ensureLoaded();
    await _persistRoutineSteps(
      routineId: routineId,
      steps: _normalizeRoutineSteps(steps),
    );
  }

  Future<void> reorderRoutineSteps({
    required String routineId,
    required int oldIndex,
    required int newIndex,
  }) async {
    await _ensureLoaded();
    final steps = _routineSteps
        .where((item) => item.routineId == routineId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    if (oldIndex < 0 || oldIndex >= steps.length) {
      return;
    }
    if (newIndex < 0 || newIndex >= steps.length) {
      return;
    }
    if (oldIndex == newIndex) {
      return;
    }
    final moved = steps.removeAt(oldIndex);
    steps.insert(newIndex, moved);
    final now = DateTime.now();
    final reordered = List<RoutineStep>.generate(steps.length, (index) {
      final step = steps[index];
      final updatedAt =
          step.order == index ? step.updatedAt : (step.updatedAt ?? now);
      return RoutineStep(
        id: step.id,
        routineId: step.routineId,
        habitId: step.habitId,
        order: index,
        durationSeconds: step.durationSeconds,
        createdAt: step.createdAt,
        updatedAt: updatedAt,
      );
    });
    await _persistRoutineSteps(routineId: routineId, steps: reordered);
  }

  Future<bool> addRoutineStep({
    required String routineId,
    required String habitId,
    required int durationSeconds,
  }) async {
    await _ensureLoaded();
    if (durationSeconds <= 0) {
      return false;
    }
    final existingSteps = _routineSteps
        .where((item) => item.routineId == routineId)
        .toList();
    if (existingSteps.any((item) => item.habitId == habitId)) {
      return false;
    }
    final now = DateTime.now();
    final nextOrder = existingSteps.isEmpty
        ? 0
        : existingSteps.map((step) => step.order).reduce(max) + 1;
    final newStep = RoutineStep(
      id: _generateId(),
      routineId: routineId,
      habitId: habitId,
      order: nextOrder,
      durationSeconds: durationSeconds,
      createdAt: now,
      updatedAt: now,
    );
    final updatedSteps = _normalizeRoutineSteps([...existingSteps, newStep]);
    await _persistRoutineSteps(routineId: routineId, steps: updatedSteps);
    return true;
  }

  Future<bool> updateRoutineStepDuration({
    required RoutineStep step,
    required int durationSeconds,
  }) async {
    await _ensureLoaded();
    if (durationSeconds <= 0) {
      return false;
    }
    final existingSteps = _routineSteps
        .where((item) => item.routineId == step.routineId)
        .toList();
    final index = existingSteps.indexWhere((item) => item.id == step.id);
    if (index < 0) {
      return false;
    }
    final updated = RoutineStep(
      id: step.id,
      routineId: step.routineId,
      habitId: step.habitId,
      order: step.order,
      durationSeconds: durationSeconds,
      createdAt: step.createdAt,
      updatedAt: DateTime.now(),
    );
    existingSteps[index] = updated;
    await _persistRoutineSteps(
      routineId: step.routineId,
      steps: _normalizeRoutineSteps(existingSteps),
    );
    return true;
  }

  Future<void> deleteRoutineStep(RoutineStep step) async {
    await _ensureLoaded();
    final existingSteps = _routineSteps
        .where((item) => item.routineId == step.routineId)
        .toList();
    existingSteps.removeWhere((item) => item.id == step.id);
    await _persistRoutineSteps(
      routineId: step.routineId,
      steps: _normalizeRoutineSteps(existingSteps),
    );
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
        await _routineStepUseCases.replaceByRoutineId(
          routineId,
          preparedSteps,
        );
      },
    );
  }

  List<RoutineStep> _normalizeRoutineSteps(List<RoutineStep> steps) {
    final sorted = [...steps]..sort((a, b) => a.order.compareTo(b.order));
    final now = DateTime.now();
    return List<RoutineStep>.generate(sorted.length, (index) {
      final step = sorted[index];
      final updatedAt =
          step.order == index ? step.updatedAt : (step.updatedAt ?? now);
      return RoutineStep(
        id: step.id,
        routineId: step.routineId,
        habitId: step.habitId,
        order: index,
        durationSeconds: step.durationSeconds,
        createdAt: step.createdAt,
        updatedAt: updatedAt,
      );
    });
  }

  Future<void> _persistRoutineStepsFromStrings({
    required String routineId,
    required List<String> steps,
  }) async {
    final preparedSteps = <RoutineStep>[];
    final now = DateTime.now();
    if (steps.isNotEmpty) {
      for (int index = 0; index < steps.length; index++) {
        preparedSteps.add(
          RoutineStep(
            id: _generateId(),
            routineId: routineId,
            habitId: steps[index],
            order: index,
            durationSeconds: 0,
            createdAt: now,
            updatedAt: now,
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
