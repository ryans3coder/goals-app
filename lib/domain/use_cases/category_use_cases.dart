import '../../models/category.dart';
import '../repositories/category_repository.dart';

class CategoryUseCases {
  CategoryUseCases(this._repository);

  final CategoryRepository _repository;

  Future<List<Category>> fetchAll() => _repository.fetchAll();

  Future<void> upsert(Category category) => _repository.upsert(category);

  Future<void> deleteById(String id) => _repository.deleteById(id);
}
