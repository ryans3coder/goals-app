import '../../domain/repositories/routine_step_repository.dart';
import '../../models/routine_step.dart';
import '../local/hive_database.dart';

class HiveRoutineStepRepository implements RoutineStepRepository {
  HiveRoutineStepRepository(this._database);

  final HiveDatabase _database;

  @override
  Future<List<RoutineStep>> fetchAll() async {
    return _database.decodeRoutineSteps();
  }

  @override
  Future<List<RoutineStep>> fetchByRoutineId(String routineId) async {
    return _database.decodeRoutineSteps().where((step) {
      return step.routineId == routineId;
    }).toList();
  }

  @override
  Future<void> upsertAll(List<RoutineStep> steps) async {
    for (final step in steps) {
      await _database.routineStepsBox.put(step.id, step.toMap());
    }
  }

  @override
  Future<void> deleteById(String id) async {
    await _database.routineStepsBox.delete(id);
  }

  @override
  Future<void> deleteByRoutineId(String routineId) async {
    final ids = _database.routineStepsBox.values
        .where((item) =>
            (item['routineId'] as String?)?.toString() == routineId)
        .map((item) => (item['id'] as String?)?.toString())
        .whereType<String>()
        .toList();
    for (final id in ids) {
      await _database.routineStepsBox.delete(id);
    }
  }
}
