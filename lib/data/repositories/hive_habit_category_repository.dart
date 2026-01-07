import '../../domain/repositories/habit_category_repository.dart';
import '../../models/habit_category.dart';
import '../local/hive_database.dart';

class HiveHabitCategoryRepository implements HabitCategoryRepository {
  HiveHabitCategoryRepository(this._database);

  final HiveDatabase _database;
  static const String _seedKey = 'habit_categories_seeded';

  @override
  Future<List<HabitCategory>> fetchAll() async {
    return _database.decodeCategories();
  }

  @override
  Future<void> upsert(HabitCategory category) async {
    await _database.categoriesBox.put(category.id, category.toMap());
  }

  @override
  Future<void> deleteById(String id) async {
    await _database.categoriesBox.delete(id);
  }

  @override
  Future<void> seedDefaults(List<HabitCategory> defaults) async {
    final alreadySeeded =
        _database.metadataBox.get(_seedKey, defaultValue: false) as bool;
    if (alreadySeeded) {
      return;
    }

    final existingIds = _database.categoriesBox.keys
        .map((key) => key.toString())
        .toSet();
    for (final category in defaults) {
      if (!existingIds.contains(category.id)) {
        await _database.categoriesBox.put(category.id, category.toMap());
      }
    }
    await _database.metadataBox.put(_seedKey, true);
  }
}
