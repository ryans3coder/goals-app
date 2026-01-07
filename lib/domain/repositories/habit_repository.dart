import '../../models/habit.dart';

abstract class HabitRepository {
  Future<List<Habit>> fetchAll();
  Future<void> upsert(Habit habit);
  Future<void> deleteById(String id);
}
