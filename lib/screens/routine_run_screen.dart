import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:provider/provider.dart';

import '../controllers/routine_run_timer_controller.dart';
import '../domain/message_bank.dart';
import '../models/habit.dart';
import '../models/routine.dart';
import '../models/routine_event.dart';
import '../models/routine_step.dart';
import '../services/data_provider.dart';
import '../services/feedback_manager.dart';
import '../services/victory_gate.dart';
import '../theme/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../widgets/victory_overlay.dart';

class RoutineRunScreen extends StatefulWidget {
  const RoutineRunScreen({super.key, required this.routine});

  final Routine routine;

  @override
  State<RoutineRunScreen> createState() => _RoutineRunScreenState();
}

class _RoutineRunScreenState extends State<RoutineRunScreen>
    with WidgetsBindingObserver {
  int _currentStepIndex = 0;
  bool _isCompleted = false;
  bool _hasStarted = false;
  bool _completionLogged = false;
  String? _activeStepId;
  final Set<String> _completedStepIds = {};
  final Set<String> _skippedStepIds = {};
  late final RoutineRunTimerController _timerController;
  bool _hasAutoStarted = false;
  bool _isHandlingStepChange = false;
  final VictoryGate _victoryGate = VictoryGate();
  late final FeedbackManager _feedbackManager;
  late final MessageBank _messageBank;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _feedbackManager = const FeedbackManager();
    _messageBank = MessageBank();
    _timerController = RoutineRunTimerController(
      onStepCompleted: () async =>
          _handleStepCompletion(triggeredByTimer: true),
    )..addListener(_handleTimerUpdated);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerController
      ..removeListener(_handleTimerUpdated)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_timerController.status == RoutineRunTimerStatus.running) {
        _pauseTimer(showSnack: true);
      }
    }
  }

  void _pauseTimer({bool showSnack = false}) {
    _timerController.pause();
    if (showSnack) {
      _showSnack(AppStrings.routineRunBackgroundPause);
    }
  }

  void _handleTimerUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _ensureRoutineStarted() async {
    if (_hasStarted) {
      return;
    }
    _hasStarted = true;
    await context.read<DataProvider>().addRoutineEvent(
          type: RoutineEventType.routineStarted,
          routineId: widget.routine.id,
        );
  }

  Future<void> _toggleRunning({
    required bool hasSteps,
    required List<RoutineStep> steps,
  }) async {
    if (!hasSteps) {
      _showSnack(AppStrings.routineRunNoStepsMessage);
      return;
    }
    if (_isCompleted) {
      return;
    }
    final status = _timerController.status;
    if (status == RoutineRunTimerStatus.running) {
      _pauseTimer();
      return;
    }
    if (status == RoutineRunTimerStatus.paused) {
      await _ensureRoutineStarted();
      _timerController.resume();
      return;
    }
    if (status == RoutineRunTimerStatus.idle && steps.isNotEmpty) {
      await _startStepAtIndex(_currentStepIndex, steps);
    }
  }

  Future<void> _handleStepCompletion({bool triggeredByTimer = false}) async {
    if (_isHandlingStepChange) {
      return;
    }
    if (_isCompleted) {
      return;
    }
    _isHandlingStepChange = true;

    try {
      final dataProvider = context.read<DataProvider>();
      final steps = dataProvider.routineStepsByRoutineId(widget.routine.id);
      if (steps.isEmpty) {
        return;
      }
      final maxIndex = steps.length - 1;
      final safeIndex = _currentStepIndex.clamp(0, maxIndex);
      final currentStep = steps[safeIndex];

      if (!_completedStepIds.contains(currentStep.id)) {
        _completedStepIds.add(currentStep.id);
        await dataProvider.addRoutineEvent(
          type: RoutineEventType.stepCompleted,
          routineId: widget.routine.id,
          habitId: currentStep.habitId,
        );
      }

      if (triggeredByTimer) {
        HapticFeedback.lightImpact();
      }

      await _advanceToNextStep(steps);
    } finally {
      _isHandlingStepChange = false;
    }
  }

  Future<void> _handleStepSkip() async {
    if (_isHandlingStepChange) {
      return;
    }
    if (_isCompleted) {
      return;
    }
    _isHandlingStepChange = true;
    try {
      final dataProvider = context.read<DataProvider>();
      final steps = dataProvider.routineStepsByRoutineId(widget.routine.id);
      if (steps.isEmpty) {
        return;
      }
      final maxIndex = steps.length - 1;
      final safeIndex = _currentStepIndex.clamp(0, maxIndex);
      final currentStep = steps[safeIndex];

      if (!_skippedStepIds.contains(currentStep.id)) {
        _skippedStepIds.add(currentStep.id);
        await dataProvider.addRoutineEvent(
          type: RoutineEventType.stepSkipped,
          routineId: widget.routine.id,
          habitId: currentStep.habitId,
        );
      }

      await _advanceToNextStep(steps);
    } finally {
      _isHandlingStepChange = false;
    }
  }

  Future<void> _advanceToNextStep(List<RoutineStep> steps) async {
    if (steps.isEmpty) {
      return;
    }
    final maxIndex = steps.length - 1;
    if (_currentStepIndex >= maxIndex) {
      await _completeRoutine();
      return;
    }

    final nextIndex = _currentStepIndex + 1;
    await _startStepAtIndex(nextIndex, steps);
  }

  Future<void> _startStepAtIndex(int index, List<RoutineStep> steps) async {
    if (index < 0 || index >= steps.length) {
      return;
    }
    final step = steps[index];
    if (mounted) {
      setState(() {
        _currentStepIndex = index;
        _activeStepId = step.id;
      });
    }
    await _ensureRoutineStarted();
    _timerController.startStep(index, step.durationSeconds);
  }

  Future<void> _completeRoutine() async {
    if (_completionLogged) {
      return;
    }
    _completionLogged = true;
    _timerController.markCompleted();
    if (mounted) {
      setState(() {
        _isCompleted = true;
      });
    }
    await context.read<DataProvider>().addRoutineEvent(
          type: RoutineEventType.routineCompleted,
          routineId: widget.routine.id,
        );
    await _showVictoryFeedback();
  }

  Future<void> _showVictoryFeedback() async {
    if (!_victoryGate.tryOpen()) {
      return;
    }
    if (!mounted) {
      return;
    }
    final dataProvider = context.read<DataProvider>();
    final message = _messageBank.routineCompletedMessage();
    final preferences = dataProvider.feedbackPreferences;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: AppStrings.routineRunCompletedTitle,
      pageBuilder: (context, _, __) => VictoryOverlay(
        message: message,
        preferences: preferences,
        feedbackManager: _feedbackManager,
        onDismiss: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      ),
    );

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _confirmSkip() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.routineRunSkipTitle),
        content: const Text(AppStrings.routineRunSkipMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.routineRunSkipAction),
          ),
        ],
      ),
    );

    if (result == true) {
      await _handleStepSkip();
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataProvider = context.watch<DataProvider>();
    final steps = dataProvider.routineStepsByRoutineId(widget.routine.id);
    final habits = dataProvider.habits;
    final habitLookup = {
      for (final habit in habits) habit.id: habit,
    };
    final hasSteps = steps.isNotEmpty;
    final maxIndex = hasSteps ? steps.length - 1 : 0;
    final safeIndex =
        hasSteps ? _currentStepIndex.clamp(0, maxIndex) : _currentStepIndex;
    final currentStep = hasSteps ? steps[safeIndex] : null;

    if (_currentStepIndex != safeIndex && hasSteps) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        await _startStepAtIndex(safeIndex, steps);
      });
    }

    if (hasSteps && !_hasAutoStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }
        _hasAutoStarted = true;
        await _startStepAtIndex(0, steps);
      });
    }

    if (!hasSteps && _activeStepId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() => _activeStepId = null);
        _timerController.reset();
        _hasAutoStarted = false;
      });
    }

    final currentHabit = currentStep != null
        ? habitLookup[currentStep.habitId]
        : null;
    final currentTitle = currentStep == null
        ? AppStrings.routineRunNoStepsTitle
        : '${currentHabit?.emoji.isNotEmpty == true ? currentHabit!.emoji : '•'} '
            '${currentHabit?.title ?? 'Hábito removido'}';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(AppStrings.routineRunTitle),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.routine.title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                hasSteps
                    ? 'Passo ${safeIndex + 1} de ${steps.length}'
                    : 'Passo 0 de 0',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                currentTitle,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xl,
                  horizontal: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.xl),
                ),
                child: Center(
                  child: Text(
                    _timerController.remaining == null
                        ? '--:--'
                        : _formatDuration(_timerController.remaining!),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppStrings.routineRunBackgroundPause,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              if (_isCompleted)
                AppPrimaryButton(
                  label: AppStrings.routineRunCompletedTitle,
                  onPressed: () => Navigator.of(context).pop(),
                )
              else ...[
                AppPrimaryButton(
                  label: _timerController.status == RoutineRunTimerStatus.running
                      ? AppStrings.routineRunPause
                      : AppStrings.routineRunResume,
                  onPressed: hasSteps
                      ? () => _toggleRunning(
                            hasSteps: hasSteps,
                            steps: steps,
                          )
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: AppStrings.skip,
                        onPressed: hasSteps ? _confirmSkip : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppPrimaryButton(
                        label: AppStrings.next,
                        onPressed: hasSteps ? _handleStepCompletion : null,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
