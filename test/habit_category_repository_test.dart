import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:flutter_application_1/data/local/hive_database.dart';
import 'package:flutter_application_1/data/repositories/hive_habit_category_repository.dart';
import 'package:flutter_application_1/models/habit_category.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HiveDatabase database;
  late HiveHabitCategoryRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('habit_categories_test');
    Hive.init(tempDir.path);
    database = HiveDatabase(autoInitialize: false);
    await database.initialize();
    repository = HiveHabitCategoryRepository(database);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('repository supports crud and idempotent seed', () async {
    final defaults = [
      HabitCategory(
        id: 'default-1',
        name: 'Educação',
        emoji: '📚',
        colorToken: 'secondary',
      ),
      HabitCategory(
        id: 'default-2',
        name: 'Saúde',
        emoji: '💪',
        colorToken: 'primary',
      ),
    ];

    await repository.seedDefaults(defaults);
    expect((await repository.fetchAll()).length, 2);

    await repository.seedDefaults(defaults);
    expect((await repository.fetchAll()).length, 2);

    final custom = HabitCategory(
      id: 'custom-1',
      name: 'Customizada',
      emoji: '🎯',
      colorToken: 'accent',
    );

    await repository.upsert(custom);
    final afterUpsert = await repository.fetchAll();
    expect(afterUpsert.any((item) => item.id == custom.id), isTrue);

    await repository.deleteById(custom.id);
    final afterDelete = await repository.fetchAll();
    expect(afterDelete.any((item) => item.id == custom.id), isFalse);
  });
}
