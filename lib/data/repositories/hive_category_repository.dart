import '../../domain/repositories/category_repository.dart';
import '../../models/category.dart';
import '../local/hive_database.dart';

class HiveCategoryRepository implements CategoryRepository {
  HiveCategoryRepository(this._database);

  final HiveDatabase _database;

  @override
  Future<List<Category>> fetchAll() async {
    return _database.decodeCategories();
  }

  @override
  Future<void> upsert(Category category) async {
    await _database.categoriesBox.put(category.id, category.toMap());
  }

  @override
  Future<void> deleteById(String id) async {
    await _database.categoriesBox.delete(id);
  }
}
