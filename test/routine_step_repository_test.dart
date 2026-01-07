import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:flutter_application_1/data/local/hive_database.dart';
import 'package:flutter_application_1/data/repositories/hive_routine_step_repository.dart';
import 'package:flutter_application_1/models/routine_step.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HiveDatabase database;
  late HiveRoutineStepRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('routine_steps_test');
    Hive.init(tempDir.path);
    database = HiveDatabase(autoInitialize: false);
    await database.initialize();
    repository = HiveRoutineStepRepository(database);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('repository supports add, ordered fetch, and duration update', () async {
    final steps = [
      RoutineStep(
        id: 'step-2',
        routineId: 'routine-1',
        habitId: 'habit-2',
        order: 1,
        durationSeconds: 420,
      ),
      RoutineStep(
        id: 'step-1',
        routineId: 'routine-1',
        habitId: 'habit-1',
        order: 0,
        durationSeconds: 300,
      ),
    ];

    await repository.upsertAll(steps);

    final ordered = await repository.fetchByRoutineId('routine-1');
    expect(ordered.length, 2);
    expect(ordered.first.id, 'step-1');
    expect(ordered.first.order, 0);
    expect(ordered.last.id, 'step-2');

    final updated = RoutineStep(
      id: 'step-1',
      routineId: 'routine-1',
      habitId: 'habit-1',
      order: 0,
      durationSeconds: 600,
    );
    await repository.upsertAll([updated]);

    final refreshed = await repository.fetchByRoutineId('routine-1');
    expect(refreshed.first.durationSeconds, 600);
  });
}
