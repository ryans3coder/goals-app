import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/data/local/hive_database.dart';
import 'package:flutter_application_1/data/local/local_persistence.dart';
import 'package:flutter_application_1/models/habit.dart';
import 'package:flutter_application_1/models/routine.dart';
import 'package:flutter_application_1/models/routine_step.dart';
import 'package:flutter_application_1/screens/routine_detail_screen.dart';
import 'package:flutter_application_1/services/data_provider.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_application_1/services/remote_sync_service.dart';

void main() {
  testWidgets(
    'RoutineDetailScreen renderiza sem overflow em viewport pequeno',
    (tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final tempDir = await Directory.systemTemp.createTemp(
        'routine_detail_screen_test',
      );
      Hive.init(tempDir.path);

      final database = HiveDatabase(hive: Hive, autoInitialize: false);
      await database.initialize();

      final habit = Habit(
        id: 'habit-1',
        userId: 'user-1',
        title: 'Hábito de teste',
        frequency: const ['mon'],
        currentStreak: 0,
        isCompletedToday: false,
      );
      await database.habitsBox.put(habit.id, habit.toMap());

      final steps = List<RoutineStep>.generate(25, (index) {
        return RoutineStep(
          id: 'step-$index',
          routineId: 'routine-1',
          habitId: habit.id,
          order: index,
          durationSeconds: 30,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );
      });
      for (final step in steps) {
        await database.routineStepsBox.put(step.id, step.toMap());
      }

      final routine = Routine(
        id: 'routine-1',
        userId: 'user-1',
        title: 'Rotina longa',
        icon: '',
        triggerTime: '08:00',
        steps: steps.map((step) => step.habitId).toList(),
      );
      await database.routinesBox.put(routine.id, routine.toMap());

      final localStore = LocalDataStore(preferences: preferences);
      final persistence = LocalPersistence(
        database: database,
        legacyStore: localStore,
      );
      final dataProvider = DataProvider(
        localPersistence: persistence,
        localStore: localStore,
        remoteSync: NoopRemoteSyncService(),
      );

      addTearDown(() async {
        dataProvider.dispose();
        await Hive.close();
        await tempDir.delete(recursive: true);
      });

      final binding = tester.binding;
      await binding.setSurfaceSize(const Size(320, 400));
      addTearDown(() => binding.setSurfaceSize(null));

      FlutterErrorDetails? flutterError;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        flutterError = details;
      };
      addTearDown(() {
        FlutterError.onError = originalOnError;
      });

      await tester.pumpWidget(
        ChangeNotifierProvider<DataProvider>.value(
          value: dataProvider,
          child: MaterialApp(
            home: RoutineDetailScreen(routine: routine),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(flutterError, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
