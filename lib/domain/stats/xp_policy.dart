import '../../models/routine_event.dart';

class XpPolicy {
  const XpPolicy();

  static const int routineCompletionXp = 20;

  int xpForEvent(RoutineEvent event) {
    if (event.type == RoutineEventType.routineCompleted) {
      return routineCompletionXp;
    }
    return 0;
  }
}
