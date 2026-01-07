import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../models/routine.dart';
import '../models/routine_step.dart';
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
  int _currentStepIndex = 0;
  bool _isCompleted = false;
  bool _historySaved = false;
  Timer? _timer;
  Duration? _remainingTime;
  String? _activeStepId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final steps =
        context.read<DataProvider>().routineStepsByRoutineId(widget.routine.id);
    if (steps.isNotEmpty && _activeStepId == null) {
      _activeStepId = steps.first.id;
      _setupTimerForStep(steps.first);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setupTimerForStep(RoutineStep? step) {
    _timer?.cancel();
    if (step == null || step.durationSeconds <= 0) {
      if (mounted) {
        setState(() => _remainingTime = null);
      }
      return;
    }

    final duration = Duration(seconds: step.durationSeconds);
    if (mounted) {
      setState(() => _remainingTime = duration);
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
        return;
      }
      if (mounted) {
        setState(() {
          _remainingTime = _remainingTime! - const Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _completeRoutine() async {
    if (_isCompleted) {
      return;
    }
    _timer?.cancel();
    setState(() => _isCompleted = true);

    if (_historySaved) {
      return;
    }

    _historySaved = true;
    await context.read<DataProvider>().addRoutineHistory(
          routine: widget.routine,
        );
  }

  void _advanceStep(List<RoutineStep> steps) {
    if (steps.isEmpty) {
      return;
    }
    if (_currentStepIndex >= steps.length - 1) {
      _completeRoutine();
    } else {
      final nextIndex = _currentStepIndex + 1;
      setState(() => _currentStepIndex = nextIndex);
      _setupTimerForStep(steps[nextIndex]);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showAddStepSheet({
    required List<Habit> habits,
    required List<RoutineStep> existingSteps,
  }) async {
    if (habits.isEmpty) {
      _showSnack('Crie um hábito antes de adicionar um passo.');
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
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              top: AppSpacing.xl,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adicionar passo',
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
                        labelText: 'Selecione o hábito',
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
                              labelText: 'Minutos',
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
                              labelText: 'Segundos',
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
                          _showSnack('Selecione um hábito.');
                          return;
                        }
                        if (totalSeconds <= 0) {
                          _showSnack('Informe uma duração válida.');
                          return;
                        }
                        if (existingSteps.any(
                          (step) => step.habitId == selectedHabitId,
                        )) {
                          _showSnack('Este hábito já está na rotina.');
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
                          _showSnack('Não foi possível adicionar o passo.');
                          return;
                        }

                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                );
              },
            ),
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
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              top: AppSpacing.xl,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar duração',
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
                          labelText: 'Minutos',
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
                          labelText: 'Segundos',
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
                      _showSnack('Informe uma duração válida.');
                      return;
                    }

                    final updated = await context
                        .read<DataProvider>()
                        .updateRoutineStepDuration(
                          step: step,
                          durationSeconds: totalSeconds,
                        );

                    if (!updated) {
                      _showSnack('Não foi possível atualizar a duração.');
                      return;
                    }

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
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
        title: const Text('Remover passo'),
        content: const Text('Deseja remover este passo da rotina?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (result == true) {
      await context.read<DataProvider>().deleteRoutineStep(step);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDurationLabel(int durationSeconds) {
    if (durationSeconds <= 0) {
      return 'Definir duração';
    }
    final duration = Duration(seconds: durationSeconds);
    return _formatDuration(duration);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isCompleted) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  'Rotina Concluída',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Excelente! Você finalizou mais uma etapa do seu foco.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                AppPrimaryButton(
                  label: AppStrings.back,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
        ? 'Sem passos definidos'
        : '${currentHabit?.emoji.isNotEmpty == true ? currentHabit!.emoji : '•'} '
            '${currentHabit?.title ?? 'Hábito removido'}';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back,
                          color: theme.colorScheme.onSurface),
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
                  'Passos da rotina',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (!hasSteps)
                  Text(
                    'Nenhum passo adicionado.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                          '${habit?.title ?? 'Hábito removido'}';
                      return Padding(
                        key: ValueKey(step.id),
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style:
                                          theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      _formatDurationLabel(
                                        step.durationSeconds,
                                      ),
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _showEditDurationSheet(step),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Editar duração',
                              ),
                              IconButton(
                                onPressed: () => _confirmRemoveStep(step),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Remover passo',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: AppSpacing.lg),
                AppSecondaryButton(
                  label: 'Adicionar passo',
                  onPressed: () => _showAddStepSheet(
                    habits: habits,
                    existingSteps: steps,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  hasSteps
                      ? 'Passo ${safeIndex + 1} de ${steps.length}'
                      : 'Passo 0 de 0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  currentTitle,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_remainingTime != null) ...[
                  Center(
                    child: Text(
                      _formatDuration(_remainingTime!),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: AppStrings.skip,
                        onPressed: hasSteps ? () => _advanceStep(steps) : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppPrimaryButton(
                        label: AppStrings.next,
                        onPressed: hasSteps ? () => _advanceStep(steps) : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
