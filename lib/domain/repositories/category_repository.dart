import '../../models/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> fetchAll();
  Future<void> upsert(Category category);
  Future<void> deleteById(String id);
}
