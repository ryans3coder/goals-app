import '../../models/routine.dart';

abstract class RoutineRepository {
  Future<List<Routine>> fetchAll();
  Future<void> upsert(Routine routine);
  Future<void> deleteById(String id);
}
