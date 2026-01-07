import '../../models/habit_category.dart';

abstract class HabitCategoryRepository {
  Future<List<HabitCategory>> fetchAll();
  Future<void> upsert(HabitCategory category);
  Future<void> deleteById(String id);
  Future<void> seedDefaults(List<HabitCategory> defaults);
}
