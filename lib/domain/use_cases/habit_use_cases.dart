import '../../models/habit.dart';
import '../repositories/habit_repository.dart';

class HabitUseCases {
  HabitUseCases(this._repository);

  final HabitRepository _repository;

  Future<List<Habit>> fetchAll() => _repository.fetchAll();

  Habit updateCompletion({
    required Habit habit,
    required bool isCompletedToday,
  }) {
    var updatedStreak = habit.currentStreak;
    if (isCompletedToday && !habit.isCompletedToday) {
      updatedStreak += 1;
    } else if (!isCompletedToday && habit.isCompletedToday) {
      updatedStreak = updatedStreak > 0 ? updatedStreak - 1 : 0;
    }
    return Habit(
      id: habit.id,
      userId: habit.userId,
      title: habit.title,
      frequency: habit.frequency,
      currentStreak: updatedStreak,
      isCompletedToday: isCompletedToday,
      emoji: habit.emoji,
      description: habit.description,
      category: habit.category,
    );
  }

  Future<void> upsert(Habit habit) => _repository.upsert(habit);

  Future<void> deleteById(String id) => _repository.deleteById(id);
}
