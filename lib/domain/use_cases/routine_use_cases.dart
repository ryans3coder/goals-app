import '../../models/routine.dart';
import '../repositories/routine_repository.dart';

class RoutineUseCases {
  RoutineUseCases(this._repository);

  final RoutineRepository _repository;

  Future<List<Routine>> fetchAll() => _repository.fetchAll();

  Future<void> upsert(Routine routine) => _repository.upsert(routine);

  Future<void> deleteById(String id) => _repository.deleteById(id);
}
