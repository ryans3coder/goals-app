import 'package:flutter/foundation.dart' hide Category;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/category.dart';
import '../../models/goal.dart';
import '../../models/habit.dart';
import '../../models/routine.dart';
import '../../models/routine_step.dart';
import '../../services/local_data_store.dart';

class HiveDatabase {
  HiveDatabase({HiveInterface? hive}) : _hive = hive ?? Hive;

  static const String habitsBoxName = 'habits';
  static const String routinesBoxName = 'routines';
  static const String routineStepsBoxName = 'routine_steps';
  static const String goalsBoxName = 'goals';
  static const String categoriesBoxName = 'categories';
  static const String metadataBoxName = 'metadata';
  static const String migratedKey = 'migrated_from_shared_prefs';

  final HiveInterface _hive;

  Box<Map>? _habitsBox;
  Box<Map>? _routinesBox;
  Box<Map>? _routineStepsBox;
  Box<Map>? _goalsBox;
  Box<Map>? _categoriesBox;
  Box? _metadataBox;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await Hive.initFlutter();
    _habitsBox = await _hive.openBox<Map>(habitsBoxName);
    _routinesBox = await _hive.openBox<Map>(routinesBoxName);
    _routineStepsBox = await _hive.openBox<Map>(routineStepsBoxName);
    _goalsBox = await _hive.openBox<Map>(goalsBoxName);
    _categoriesBox = await _hive.openBox<Map>(categoriesBoxName);
    _metadataBox = await _hive.openBox(metadataBoxName);
    _initialized = true;
  }

  Box<Map> get habitsBox => _habitsBox!;
  Box<Map> get routinesBox => _routinesBox!;
  Box<Map> get routineStepsBox => _routineStepsBox!;
  Box<Map> get goalsBox => _goalsBox!;
  Box<Map> get categoriesBox => _categoriesBox!;
  Box get metadataBox => _metadataBox!;

  Future<void> migrateFromLegacy(LocalDataStore legacyStore) async {
    if (!_initialized) {
      await initialize();
    }
    final migrated = metadataBox.get(migratedKey, defaultValue: false) as bool;
    if (migrated) {
      return;
    }

    final hasData = habitsBox.isNotEmpty ||
        routinesBox.isNotEmpty ||
        routineStepsBox.isNotEmpty ||
        goalsBox.isNotEmpty ||
        categoriesBox.isNotEmpty;
    if (hasData) {
      await metadataBox.put(migratedKey, true);
      return;
    }

    try {
      final snapshot = await legacyStore.loadSnapshot();
      for (final habit in snapshot.habits) {
        await habitsBox.put(habit.id, habit.toMap());
      }
      for (final routine in snapshot.routines) {
        await routinesBox.put(routine.id, routine.toMap());
      }
      for (final goal in snapshot.goals) {
        await goalsBox.put(goal.id, goal.toMap());
      }
      await metadataBox.put(migratedKey, true);
    } catch (error) {
      debugPrint('Falha ao migrar dados locais: $error');
    }
  }

  List<Habit> decodeHabits() {
    return habitsBox.values
        .map((item) => Habit.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<Routine> decodeRoutines() {
    return routinesBox.values
        .map((item) => Routine.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<RoutineStep> decodeRoutineSteps() {
    return routineStepsBox.values
        .map((item) => RoutineStep.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<Goal> decodeGoals() {
    return goalsBox.values
        .map((item) => Goal.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<Category> decodeCategories() {
    return categoriesBox.values
        .map((item) => Category.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }
}
