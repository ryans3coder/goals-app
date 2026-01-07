import '../../domain/repositories/habit_repository.dart';
import '../../models/habit.dart';
import '../local/hive_database.dart';

class HiveHabitRepository implements HabitRepository {
  HiveHabitRepository(this._database);

  final HiveDatabase _database;

  @override
  Future<List<Habit>> fetchAll() async {
    return _database.decodeHabits();
  }

  @override
  Future<void> upsert(Habit habit) async {
    await _database.habitsBox.put(habit.id, habit.toMap());
  }

  @override
  Future<void> deleteById(String id) async {
    await _database.habitsBox.delete(id);
  }
}
