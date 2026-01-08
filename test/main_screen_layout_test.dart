import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/data/local/hive_database.dart';
import 'package:flutter_application_1/data/local/local_persistence.dart';
import 'package:flutter_application_1/models/habit.dart';
import 'package:flutter_application_1/screens/main_screen.dart';
import 'package:flutter_application_1/services/data_provider.dart';
import 'package:flutter_application_1/services/local_data_store.dart';
import 'package:flutter_application_1/services/remote_sync_service.dart';

void main() {
  testWidgets(
    'MainScreen renderiza sem exceções e permite scroll em viewport pequeno',
    (tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final tempDir = await Directory.systemTemp.createTemp(
        'main_screen_layout_test',
      );
      Hive.init(tempDir.path);

      final database = HiveDatabase(hive: Hive, autoInitialize: false);
      await database.initialize();

      final habits = List<Habit>.generate(20, (index) {
        return Habit(
          id: 'habit-$index',
          userId: 'user-1',
          title: 'Hábito $index',
          frequency: const ['mon'],
          currentStreak: 0,
          isCompletedToday: false,
        );
      });

      for (final habit in habits) {
        await database.habitsBox.put(habit.id, habit.toMap());
      }

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
      await binding.setSurfaceSize(const Size(320, 480));
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
          child: const MaterialApp(home: MainScreen()),
        ),
      );
      await tester.pumpAndSettle();

      final scrollableFinder = find.byType(Scrollable);
      expect(scrollableFinder, findsOneWidget);

      final scrollable = tester.state<ScrollableState>(scrollableFinder);
      final startOffset = scrollable.position.pixels;

      await tester.drag(scrollableFinder, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(scrollable.position.pixels, greaterThan(startOffset));
      expect(flutterError, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
