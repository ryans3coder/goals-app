import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/time_formatter.dart';
import '../models/habit.dart';
import '../models/routine.dart';
import '../models/routine_step.dart';
import '../screens/routine_run_screen.dart';
import '../services/data_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_strings.dart';
import '../widgets/app_buttons.dart';

class RoutineDetailScreen extends StatefulWidget {
  const RoutineDetailScreen({super.key, required this.routine});

  final Routine routine;

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  void _openRunMode(List<RoutineStep> steps) {
    if (steps.isEmpty) {
      _showSnack(AppStrings.routineRunNoStepsMessage);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoutineRunScreen(routine: widget.routine),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showAddStepSheet({
    required List<Habit> habits,
    required List<RoutineStep> existingSteps,
  }) async {
    if (habits.isEmpty) {
      _showSnack(AppStrings.routineStepAddHint);
      return;
    }

    final minutesController = TextEditingController();
    final secondsController = TextEditingController();
    String? selectedHabitId;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: AppSpacing.xl,
                    right: AppSpacing.xl,
                    top: AppSpacing.xl,
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.routineStepAddTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      DropdownButtonFormField<String>(
                        value: selectedHabitId,
                        items: habits
                            .map(
                              (habit) => DropdownMenuItem<String>(
                                value: habit.id,
                                child: Text(
                                  '${habit.emoji.isEmpty ? '•' : habit.emoji} '
                                  '${habit.title}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setModalState(() => selectedHabitId = value);
                        },
                        decoration: const InputDecoration(
                          labelText: AppStrings.routineStepSelectHabitLabel,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minutesController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: AppStrings.routineStepMinutesLabel,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: TextField(
                              controller: secondsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: AppStrings.routineStepSecondsLabel,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppPrimaryButton(
                        label: AppStrings.save,
                        onPressed: () async {
                          final minutes =
                              int.tryParse(minutesController.text.trim()) ?? 0;
                          final seconds =
                              int.tryParse(secondsController.text.trim()) ?? 0;
                          final totalSeconds = (minutes * 60) + seconds;

                          if (selectedHabitId == null ||
                              selectedHabitId!.isEmpty) {
                            _showSnack(AppStrings.routineStepSelectHabitError);
                            return;
                          }
                          if (totalSeconds <= 0) {
                            _showSnack(AppStrings.routineStepDurationError);
                            return;
                          }
                          if (existingSteps.any(
                            (step) => step.habitId == selectedHabitId,
                          )) {
                            _showSnack(AppStrings.routineStepDuplicateHabitError);
                            return;
                          }

                          final added = await context
                              .read<DataProvider>()
                              .addRoutineStep(
                                routineId: widget.routine.id,
                                habitId: selectedHabitId!,
                                durationSeconds: totalSeconds,
                              );

                          if (!added) {
                            _showSnack(AppStrings.routineStepAddError);
                            return;
                          }

                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      minutesController.dispose();
      secondsController.dispose();
    }
  }

  Future<void> _showEditDurationSheet(RoutineStep step) async {
    final minutes = step.durationSeconds ~/ 60;
    final seconds = step.durationSeconds % 60;
    final minutesController = TextEditingController(text: '$minutes');
    final secondsController = TextEditingController(text: '$seconds');

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
        builder: (context) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                top: AppSpacing.xl,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.routineStepEditDurationTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minutesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: AppStrings.routineStepMinutesLabel,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: TextField(
                          controller: secondsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: AppStrings.routineStepSecondsLabel,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppPrimaryButton(
                    label: AppStrings.save,
                    onPressed: () async {
                      final minutes =
                          int.tryParse(minutesController.text.trim()) ?? 0;
                      final seconds =
                          int.tryParse(secondsController.text.trim()) ?? 0;
                      final totalSeconds = (minutes * 60) + seconds;
                      if (totalSeconds <= 0) {
                        _showSnack(AppStrings.routineStepDurationError);
                        return;
                      }

                      final updated = await context
                          .read<DataProvider>()
                          .updateRoutineStepDuration(
                            step: step,
                            durationSeconds: totalSeconds,
                          );

                      if (!updated) {
                        _showSnack(AppStrings.routineStepDurationUpdateError);
                        return;
                      }

                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      minutesController.dispose();
      secondsController.dispose();
    }
  }

  Future<void> _confirmRemoveStep(RoutineStep step) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.routineStepRemoveTitle),
        content: const Text(AppStrings.routineStepRemoveMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.routineStepRemoveAction),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }
    if (result == true) {
      await context.read<DataProvider>().deleteRoutineStep(step);
    }
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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          widget.routine.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    AppStrings.routineStepsTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: hasSteps
                    ? ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        padding: EdgeInsets.zero,
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            color: Colors.transparent,
                            elevation: 6,
                            shadowColor: theme.colorScheme.shadow,
                            child: child,
                          );
                        },
                        itemCount: steps.length,
                        onReorder: (oldIndex, newIndex) async {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          await context.read<DataProvider>().reorderRoutineSteps(
                                routineId: widget.routine.id,
                                oldIndex: oldIndex,
                                newIndex: newIndex,
                              );
                        },
                        itemBuilder: (context, index) {
                          final step = steps[index];
                          final habit = habitLookup[step.habitId];
                          final title =
                              '${habit?.emoji.isNotEmpty == true ? habit!.emoji : '•'} '
                              '${habit?.title ?? AppStrings.routineRunHabitRemoved}';
                          return Padding(
                            key: ValueKey(step.id),
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: theme
                                    .colorScheme.surfaceContainerHighest,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.lg),
                              ),
                              child: Row(
                                children: [
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: Icon(
                                      Icons.drag_handle,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          formatDurationSecondsLabel(
                                            step.durationSeconds,
                                            zeroLabel:
                                                AppStrings.routineStepDurationUnset,
                                          ),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _showEditDurationSheet(step),
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip:
                                        AppStrings.routineStepEditDurationTitle,
                                  ),
                                  IconButton(
                                    onPressed: () => _confirmRemoveStep(step),
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: AppStrings.routineStepRemoveTitle,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          Text(
                            AppStrings.routineStepEmptyMessage,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSecondaryButton(
                label: AppStrings.routineStepAddAction,
                onPressed: () => _showAddStepSheet(
                  habits: habits,
                  existingSteps: steps,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                label: AppStrings.routineRunStartAction,
                onPressed: () => _openRunMode(steps),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                hasSteps
                    ? AppStrings.routineStepCountLabel(steps.length)
                    : AppStrings.routineRunNoStepsTitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
