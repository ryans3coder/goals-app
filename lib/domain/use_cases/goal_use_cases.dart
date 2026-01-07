import '../../models/goal.dart';
import '../repositories/goal_repository.dart';

class GoalUseCases {
  GoalUseCases(this._repository);

  final GoalRepository _repository;

  Future<List<Goal>> fetchAll() => _repository.fetchAll();

  Future<void> upsert(Goal goal) => _repository.upsert(goal);

  Future<void> deleteById(String id) => _repository.deleteById(id);
}
