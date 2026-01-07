import '../../domain/repositories/goal_repository.dart';
import '../../models/goal.dart';
import '../local/hive_database.dart';

class HiveGoalRepository implements GoalRepository {
  HiveGoalRepository(this._database);

  final HiveDatabase _database;

  @override
  Future<List<Goal>> fetchAll() async {
    return _database.decodeGoals();
  }

  @override
  Future<void> upsert(Goal goal) async {
    await _database.goalsBox.put(goal.id, goal.toMap());
  }

  @override
  Future<void> deleteById(String id) async {
    await _database.goalsBox.delete(id);
  }
}
