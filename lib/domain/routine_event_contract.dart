class RoutineEventContract {
  const RoutineEventContract._();

  /// Routine execution started when the first step begins or resumes.
  static const String routineStarted = 'routine_started';

  /// Step completion emitted when the user advances or the timer completes.
  static const String stepCompleted = 'step_completed';

  /// Step skip emitted only when the user explicitly skips.
  static const String stepSkipped = 'step_skipped';

  /// Routine completion emitted once after the final step finishes.
  static const String routineCompleted = 'routine_completed';
}
