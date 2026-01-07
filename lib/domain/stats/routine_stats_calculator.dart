import '../../models/routine_event.dart';
import 'routine_stats_summary.dart';
import 'xp_policy.dart';

class RoutineStatsCalculator {
  const RoutineStatsCalculator({required XpPolicy xpPolicy})
      : _xpPolicy = xpPolicy;

  final XpPolicy _xpPolicy;

  RoutineStatsSummary summarize(
    List<RoutineEvent> events, {
    DateTime? now,
  }) {
    final nowLocal = (now ?? DateTime.now()).toLocal();
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final completionDays = <String>{};
    final xpByDay = <String, int>{};
    var totalXp = 0;

    for (final event in events) {
      final localTimestamp = event.timestamp.toLocal();
      final dayKey = _dayKey(localTimestamp);
      final xp = _xpPolicy.xpForEvent(event);
      if (xp > 0) {
        xpByDay.update(dayKey, (value) => value + xp, ifAbsent: () => xp);
        totalXp += xp;
      }
      if (event.type == RoutineEventType.routineCompleted) {
        completionDays.add(dayKey);
      }
    }

    final last7DaysXp = _buildLastDaysXp(
      days: 7,
      today: today,
      xpByDay: xpByDay,
    );

    final streakDays = _calculateStreakDays(
      today: today,
      completionDays: completionDays,
    );

    final last7DaysSuccess = _buildSuccessRate(
      events: events,
      start: today.subtract(const Duration(days: 6)),
      endExclusive: today.add(const Duration(days: 1)),
    );

    final last30DaysSuccess = _buildSuccessRate(
      events: events,
      start: today.subtract(const Duration(days: 29)),
      endExclusive: today.add(const Duration(days: 1)),
    );

    return RoutineStatsSummary(
      streakDays: streakDays,
      totalXp: totalXp,
      last7DaysXp: last7DaysXp,
      last7DaysSuccess: last7DaysSuccess,
      last30DaysSuccess: last30DaysSuccess,
      hasEvents: events.isNotEmpty,
    );
  }

  List<DailyXp> _buildLastDaysXp({
    required int days,
    required DateTime today,
    required Map<String, int> xpByDay,
  }) {
    final results = <DailyXp>[];
    for (var offset = days - 1; offset >= 0; offset--) {
      final day = today.subtract(Duration(days: offset));
      final key = _dayKey(day);
      results.add(DailyXp(day: day, xp: xpByDay[key] ?? 0));
    }
    return results;
  }

  int _calculateStreakDays({
    required DateTime today,
    required Set<String> completionDays,
  }) {
    final todayKey = _dayKey(today);
    if (!completionDays.contains(todayKey)) {
      return 0;
    }

    var streak = 0;
    while (true) {
      final day = today.subtract(Duration(days: streak));
      if (completionDays.contains(_dayKey(day))) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  SuccessRateSummary _buildSuccessRate({
    required List<RoutineEvent> events,
    required DateTime start,
    required DateTime endExclusive,
  }) {
    var started = 0;
    var completed = 0;
    for (final event in events) {
      final timestamp = event.timestamp.toLocal();
      if (timestamp.isBefore(start) || !timestamp.isBefore(endExclusive)) {
        continue;
      }
      if (event.type == RoutineEventType.routineStarted) {
        started += 1;
      } else if (event.type == RoutineEventType.routineCompleted) {
        completed += 1;
      }
    }
    return SuccessRateSummary(started: started, completed: completed);
  }

  String _dayKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
