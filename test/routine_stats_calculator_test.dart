import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/domain/stats/routine_stats_calculator.dart';
import 'package:flutter_application_1/domain/stats/xp_policy.dart';
import 'package:flutter_application_1/models/routine_event.dart';

void main() {
  test('calculates streak and xp from completion events', () {
    final now = DateTime(2024, 5, 10, 12, 0);
    final events = [
      RoutineEvent(
        id: '1',
        type: RoutineEventType.routineCompleted,
        routineId: 'r1',
        timestamp: DateTime(2024, 5, 8, 9, 0),
      ),
      RoutineEvent(
        id: '2',
        type: RoutineEventType.routineCompleted,
        routineId: 'r2',
        timestamp: DateTime(2024, 5, 9, 10, 0),
      ),
      RoutineEvent(
        id: '3',
        type: RoutineEventType.routineCompleted,
        routineId: 'r3',
        timestamp: DateTime(2024, 5, 10, 8, 0),
      ),
      RoutineEvent(
        id: '4',
        type: RoutineEventType.routineStarted,
        routineId: 'r4',
        timestamp: DateTime(2024, 5, 10, 11, 0),
      ),
    ];

    const calculator = RoutineStatsCalculator(xpPolicy: XpPolicy());

    final summary = calculator.summarize(events, now: now);

    expect(summary.streakDays, 3);
    expect(summary.totalXp, XpPolicy.routineCompletionXp * 3);
  });
}
