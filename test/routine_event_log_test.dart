import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/data/repositories/local_routine_event_repository.dart';
import 'package:flutter_application_1/models/routine_event.dart';
import 'package:flutter_application_1/services/local_data_store.dart';

void main() {
  test('event log mantém ordem e evita duplicações na execução', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = LocalDataStore(preferences: preferences);
    final repository = LocalRoutineEventRepository(localStore: store);

    const routineId = 'routine-1';
    const executionId = 'run-1';

    Future<void> addEvent(
      RoutineEventType type, {
      String? habitId,
      int? stepIndex,
    }) async {
      final event = RoutineEvent(
        id: '${RoutineEvent.encodeType(type)}-${stepIndex ?? 'none'}',
        type: type,
        routineId: routineId,
        executionId: executionId,
        habitId: habitId,
        stepIndex: stepIndex,
        timestamp: DateTime(2024, 1, 1, 8, 0),
      );
      final dedupeKey = [
        RoutineEvent.encodeType(type),
        routineId,
        habitId ?? '',
        stepIndex?.toString() ?? '',
        executionId,
      ].join('|');
      await repository.addEventIfAbsent(
        event: event,
        dedupeKey: dedupeKey,
      );
    }

    await addEvent(RoutineEventType.routineStarted);
    await addEvent(
      RoutineEventType.stepCompleted,
      habitId: 'habit-1',
      stepIndex: 0,
    );
    await addEvent(
      RoutineEventType.stepCompleted,
      habitId: 'habit-2',
      stepIndex: 1,
    );
    await addEvent(RoutineEventType.routineCompleted);

    await addEvent(
      RoutineEventType.stepCompleted,
      habitId: 'habit-2',
      stepIndex: 1,
    );
    await addEvent(RoutineEventType.routineCompleted);

    final events = repository.fetchAll();

    expect(events, hasLength(4));
    expect(events[0].type, RoutineEventType.routineStarted);
    expect(events[1].type, RoutineEventType.stepCompleted);
    expect(events[1].stepIndex, 0);
    expect(events[2].type, RoutineEventType.stepCompleted);
    expect(events[2].stepIndex, 1);
    expect(events[3].type, RoutineEventType.routineCompleted);
  });
}
