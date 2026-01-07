import '../../models/goal.dart';

abstract class GoalRepository {
  Future<List<Goal>> fetchAll();
  Future<void> upsert(Goal goal);
  Future<void> deleteById(String id);
}
