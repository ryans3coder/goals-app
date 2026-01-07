import '../../models/habit_category.dart';
import '../repositories/habit_category_repository.dart';

class HabitCategoryUseCases {
  HabitCategoryUseCases(this._repository);

  final HabitCategoryRepository _repository;

  Future<List<HabitCategory>> fetchAll() => _repository.fetchAll();

  Future<void> upsert(HabitCategory category) => _repository.upsert(category);

  Future<void> deleteById(String id) => _repository.deleteById(id);

  Future<void> seedDefaults(List<HabitCategory> defaults) =>
      _repository.seedDefaults(defaults);
}
