import '../../domain/repositories/routine_repository.dart';
import '../../models/routine.dart';
import '../local/hive_database.dart';

class HiveRoutineRepository implements RoutineRepository {
  HiveRoutineRepository(this._database);

  final HiveDatabase _database;

  @override
  Future<List<Routine>> fetchAll() async {
    return _database.decodeRoutines();
  }

  @override
  Future<void> upsert(Routine routine) async {
    await _database.routinesBox.put(routine.id, routine.toMap());
  }

  @override
  Future<void> deleteById(String id) async {
    await _database.routinesBox.delete(id);
  }
}
