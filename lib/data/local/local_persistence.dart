import '../../domain/repositories/habit_category_repository.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/repositories/routine_repository.dart';
import '../../domain/repositories/routine_step_repository.dart';
import '../../services/local_data_store.dart';
import '../repositories/hive_habit_category_repository.dart';
import '../repositories/hive_goal_repository.dart';
import '../repositories/hive_habit_repository.dart';
import '../repositories/hive_routine_repository.dart';
import '../repositories/hive_routine_step_repository.dart';
import 'hive_database.dart';

class LocalPersistence {
  factory LocalPersistence({
    HiveDatabase? database,
    LocalDataStore? legacyStore,
  }) {
    final resolvedDatabase = database ?? HiveDatabase();
    final resolvedLegacy = legacyStore ?? LocalDataStore();
    return LocalPersistence._(
      resolvedDatabase,
      resolvedLegacy,
      HiveHabitRepository(resolvedDatabase),
      HiveRoutineRepository(resolvedDatabase),
      HiveRoutineStepRepository(resolvedDatabase),
      HiveGoalRepository(resolvedDatabase),
      HiveHabitCategoryRepository(resolvedDatabase),
    );
  }

  LocalPersistence._(
    this._database,
    this._legacyStore,
    this._habitRepository,
    this._routineRepository,
    this._routineStepRepository,
    this._goalRepository,
    this._categoryRepository,
  );

  final HiveDatabase _database;
  final LocalDataStore _legacyStore;
  final HabitRepository _habitRepository;
  final RoutineRepository _routineRepository;
  final RoutineStepRepository _routineStepRepository;
  final GoalRepository _goalRepository;
  final HabitCategoryRepository _categoryRepository;

  HabitRepository get habits => _habitRepository;
  RoutineRepository get routines => _routineRepository;
  RoutineStepRepository get routineSteps => _routineStepRepository;
  GoalRepository get goals => _goalRepository;
  HabitCategoryRepository get categories => _categoryRepository;

  Future<void> initialize() async {
    await _database.initialize();
    await _database.migrateFromLegacy(_legacyStore);
  }
}
