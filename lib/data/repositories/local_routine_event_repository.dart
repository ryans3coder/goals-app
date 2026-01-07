import '../../models/routine_event.dart';
import '../../services/local_data_store.dart';

class LocalRoutineEventRepository {
  LocalRoutineEventRepository({required LocalDataStore localStore})
      : _localStore = localStore;

  final LocalDataStore _localStore;

  Future<void> addEvent(RoutineEvent event) {
    return _localStore.addRoutineEvent(event);
  }

  Future<void> addEventIfAbsent({
    required RoutineEvent event,
    required String dedupeKey,
  }) {
    return _localStore.addRoutineEventIfAbsent(
      event: event,
      dedupeKey: dedupeKey,
    );
  }

  List<RoutineEvent> fetchAll() {
    return _localStore.loadRoutineEvents();
  }

  List<RoutineEvent> fetchByType(RoutineEventType type) {
    return _localStore.loadRoutineEventsByType(type);
  }

  List<RoutineEvent> fetchByDateRange({
    required DateTime start,
    required DateTime end,
  }) {
    return _localStore.loadRoutineEventsByDateRange(start: start, end: end);
  }
}
