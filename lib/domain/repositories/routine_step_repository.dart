import '../../models/routine_step.dart';

abstract class RoutineStepRepository {
  Future<List<RoutineStep>> fetchAll();
  Future<List<RoutineStep>> fetchByRoutineId(String routineId);
  Future<void> upsertAll(List<RoutineStep> steps);
  Future<void> replaceByRoutineId(String routineId, List<RoutineStep> steps);
  Future<void> deleteById(String id);
  Future<void> deleteByRoutineId(String routineId);
}
