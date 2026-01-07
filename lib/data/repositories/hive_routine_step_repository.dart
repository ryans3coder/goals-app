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
    final steps = _database.decodeRoutineSteps().where((step) {
      return step.routineId == routineId;
    }).toList();
    steps.sort((a, b) => a.order.compareTo(b.order));
    return steps;
  }

  @override
  Future<void> upsertAll(List<RoutineStep> steps) async {
    if (steps.isEmpty) {
      return;
    }
    final payload = <String, Map<String, dynamic>>{};
    for (final step in steps) {
      payload[step.id] = step.toMap();
    }
    await _database.routineStepsBox.putAll(payload);
  }

  @override
  Future<void> replaceByRoutineId(
    String routineId,
    List<RoutineStep> steps,
  ) async {
    final box = _database.routineStepsBox;
    final idsToDelete = box.values
        .where((item) =>
            (item['routineId'] as String?)?.toString() == routineId)
        .map((item) => (item['id'] as String?)?.toString())
        .whereType<String>()
        .toList();
    if (idsToDelete.isNotEmpty) {
      await box.deleteAll(idsToDelete);
    }
    if (steps.isNotEmpty) {
      final payload = <String, Map<String, dynamic>>{};
      for (final step in steps) {
        payload[step.id] = step.toMap();
      }
      await box.putAll(payload);
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
