class RoutineStatsSummary {
  const RoutineStatsSummary({
    required this.streakDays,
    required this.totalXp,
    required this.last7DaysXp,
    required this.last7DaysSuccess,
    required this.last30DaysSuccess,
    required this.hasEvents,
  });

  final int streakDays;
  final int totalXp;
  final List<DailyXp> last7DaysXp;
  final SuccessRateSummary last7DaysSuccess;
  final SuccessRateSummary last30DaysSuccess;
  final bool hasEvents;
}

class DailyXp {
  const DailyXp({required this.day, required this.xp});

  final DateTime day;
  final int xp;
}

class SuccessRateSummary {
  const SuccessRateSummary({required this.started, required this.completed});

  final int started;
  final int completed;

  double get rate {
    if (started <= 0) {
      return 0;
    }
    return completed / started;
  }
}
