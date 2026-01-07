import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../models/routine.dart';
import '../models/routine_event.dart';
import '../models/routine_step.dart';
import '../services/data_provider.dart';
import '../theme/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_buttons.dart';

class RoutineRunScreen extends StatefulWidget {
  const RoutineRunScreen({super.key, required this.routine});

  final Routine routine;

  @override
  State<RoutineRunScreen> createState() => _RoutineRunScreenState();
}

class _RoutineRunScreenState extends State<RoutineRunScreen>
    with WidgetsBindingObserver {
  int _currentStepIndex = 0;
  bool _isRunning = false;
  bool _isCompleted = false;
  bool _hasStarted = false;
  bool _completionLogged = false;
  Timer? _timer;
  Duration? _remainingTime;
  String? _activeStepId;
  final Set<String> _completedStepIds = {};
  final Set<String> _skippedStepIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_isRunning) {
        _pauseTimer(showSnack: true);
      }
    }
  }

  void _pauseTimer({bool showSnack = false}) {
    _timer?.cancel();
    if (mounted) {
      setState(() => _isRunning = false);
      if (showSnack) {
        _showSnack(AppStrings.routineRunBackgroundPause);
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_remainingTime == null || _remainingTime!.inSeconds <= 0) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime == null) {
        timer.cancel();
        return;
      }
      if (_remainingTime!.inSeconds <= 1) {
        if (mounted) {
          setState(() => _remainingTime = Duration.zero);
        }
        timer.cancel();
        unawaited(_handleStepCompletion(triggeredByTimer: true));
        return;
      }
      if (mounted) {
        setState(() {
          _remainingTime = _remainingTime! - const Duration(seconds: 1);
        });
      }
    });
  }

  void _setupTimerForStep(RoutineStep? step) {
    _timer?.cancel();
    if (step == null || step.durationSeconds <= 0) {
      if (mounted) {
        setState(() => _remainingTime = null);
      }
      return;
    }
    if (mounted) {
      setState(() {
        _remainingTime = Duration(seconds: step.durationSeconds);
      });
    }
  }

  Future<void> _toggleRunning({required bool hasSteps}) async {
    if (!hasSteps) {
      _showSnack(AppStrings.routineRunNoStepsMessage);
      return;
    }
    if (_isCompleted) {
      return;
    }
    if (_isRunning) {
      _pauseTimer();
      return;
    }

    if (!_hasStarted) {
      _hasStarted = true;
      await context.read<DataProvider>().addRoutineEvent(
            type: RoutineEventType.routineStarted,
            routineId: widget.routine.id,
          );
    }

    if (mounted) {
      setState(() => _isRunning = true);
    }
    _startTimer();
  }

  Future<void> _handleStepCompletion({bool triggeredByTimer = false}) async {
    if (_isCompleted) {
      return;
    }

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

    await _advanceToNextStep(steps, keepRunning: _isRunning);
  }

  Future<void> _handleStepSkip() async {
    if (_isCompleted) {
      return;
    }
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

    await _advanceToNextStep(steps, keepRunning: _isRunning);
  }

  Future<void> _advanceToNextStep(
    List<RoutineStep> steps, {
    required bool keepRunning,
  }) async {
    if (steps.isEmpty) {
      return;
    }
    final maxIndex = steps.length - 1;
    if (_currentStepIndex >= maxIndex) {
      await _completeRoutine();
      return;
    }

    final nextIndex = _currentStepIndex + 1;
    if (mounted) {
      setState(() => _currentStepIndex = nextIndex);
    }
    _setupTimerForStep(steps[nextIndex]);
    if (keepRunning) {
      _startTimer();
    }
  }

  Future<void> _completeRoutine() async {
    if (_completionLogged) {
      return;
    }
    _completionLogged = true;
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _isRunning = false;
        _isCompleted = true;
      });
    }
    await context.read<DataProvider>().addRoutineEvent(
          type: RoutineEventType.routineCompleted,
          routineId: widget.routine.id,
        );
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() => _currentStepIndex = safeIndex);
      });
    }

    if (_activeStepId != currentStep?.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _activeStepId = currentStep?.id;
        _setupTimerForStep(currentStep);
      });
    }

    if (!hasSteps && _activeStepId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _activeStepId = null;
        _setupTimerForStep(null);
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
                    _remainingTime == null
                        ? '--:--'
                        : _formatDuration(_remainingTime!),
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
                  label: _isRunning
                      ? AppStrings.routineRunPause
                      : (_hasStarted
                          ? AppStrings.routineRunResume
                          : AppStrings.routineRunStart),
                  onPressed: hasSteps ? () => _toggleRunning(hasSteps: hasSteps) : null,
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
