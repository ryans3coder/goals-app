import '../../models/routine_step.dart';
import '../repositories/routine_step_repository.dart';

class RoutineStepUseCases {
  RoutineStepUseCases(this._repository);

  final RoutineStepRepository _repository;

  Future<List<RoutineStep>> fetchAll() => _repository.fetchAll();

  Future<List<RoutineStep>> fetchByRoutineId(String routineId) =>
      _repository.fetchByRoutineId(routineId);

  Future<void> upsertAll(List<RoutineStep> steps) =>
      _repository.upsertAll(steps);

  Future<void> deleteByRoutineId(String routineId) =>
      _repository.deleteByRoutineId(routineId);
}
