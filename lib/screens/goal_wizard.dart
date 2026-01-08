import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/goal.dart';
import '../models/milestone.dart';
import '../services/data_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_strings.dart';
import '../widgets/app_buttons.dart';

class GoalWizard extends StatefulWidget {
  const GoalWizard({super.key, this.goal});

  final Goal? goal;

  @override
  State<GoalWizard> createState() => _GoalWizardState();
}

class _GoalWizardState extends State<GoalWizard> {
  final _titleController = TextEditingController();
  final _reasonController = TextEditingController();
  final List<_MilestoneDraft> _milestones = [];
  int _currentStep = 0;
  DateTime? _targetDate;
  late final DateTime _createdAt;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    if (goal != null) {
      _titleController.text = goal.title;
      _reasonController.text = goal.reason;
      _targetDate = goal.targetDate;
      _createdAt = goal.createdAt;
      final sortedMilestones = goal.milestones.toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      for (final milestone in sortedMilestones) {
        _milestones.add(
          _MilestoneDraft.fromMilestone(milestone),
        );
      }
    } else {
      _createdAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _reasonController.dispose();
    for (final milestone in _milestones) {
      milestone.dispose();
    }
    super.dispose();
  }

  void _addMilestoneField() {
    setState(() {
      _milestones.add(_MilestoneDraft.create());
    });
  }

  void _removeMilestoneField(int index) {
    setState(() {
      _milestones[index].dispose();
      _milestones.removeAt(index);
    });
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (selected != null) {
      setState(() {
        _targetDate = selected;
      });
    }
  }

  Future<void> _saveGoal() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o título da meta.')),
      );
      return;
    }

    final milestones = <Milestone>[];
    var order = 0;
    for (final draft in _milestones) {
      final text = draft.controller.text.trim();
      if (text.isEmpty) {
        continue;
      }
      milestones.add(
        Milestone(
          id: draft.id,
          goalId: widget.goal?.id ?? '',
          text: text,
          order: order,
          isCompleted: draft.isCompleted,
          completedAt: draft.completedAt,
        ),
      );
      order += 1;
    }

    final goal = Goal(
      id: widget.goal?.id ?? '',
      userId: widget.goal?.userId ?? '',
      title: title,
      reason: _reasonController.text.trim(),
      createdAt: _createdAt,
      targetDate: _targetDate,
      status: widget.goal?.status ?? GoalStatus.active,
      milestones: milestones,
      specific: title,
      measurable: widget.goal?.measurable ?? '',
      achievable: widget.goal?.achievable ?? '',
      relevant: _reasonController.text.trim(),
      timeBound: _targetDate,
      categoryId: widget.goal?.categoryId ?? '',
    );

    await context.read<DataProvider>().addGoal(goal);

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  bool _canContinue() {
    if (_currentStep == 0) {
      return _titleController.text.trim().isNotEmpty;
    }
    return true;
  }

  String _formatDeadline(DateTime? deadline) {
    if (deadline == null) {
      return 'Sem prazo definido';
    }
    return '${deadline.day.toString().padLeft(2, '0')}/'
        '${deadline.month.toString().padLeft(2, '0')}/'
        '${deadline.year}';
  }

  List<Step> _buildSteps() {
    final theme = Theme.of(context);
    return [
      Step(
        title: const Text('Defina a Meta'),
        isActive: _currentStep >= 0,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Prazo',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDeadline(_targetDate),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickDeadline,
                  icon: const Icon(Icons.date_range),
                  label: const Text('Escolher'),
                ),
              ],
            ),
          ],
        ),
      ),
      Step(
        title: const Text('O Propósito'),
        isActive: _currentStep >= 1,
        content: TextField(
          controller: _reasonController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Porquê',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      Step(
        title: const Text('Milestones'),
        isActive: _currentStep >= 2,
        content: Column(
          children: [
            if (_milestones.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nenhuma milestone adicionada.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            if (_milestones.isNotEmpty)
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _milestones.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final milestone = _milestones.removeAt(oldIndex);
                    _milestones.insert(newIndex, milestone);
                  });
                },
                itemBuilder: (context, index) {
                  final milestone = _milestones[index];
                  return Padding(
                    key: ValueKey(milestone.id),
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_indicator),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: milestone.controller,
                            decoration: InputDecoration(
                              labelText: 'Milestone ${index + 1}',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          onPressed: () => _removeMilestoneField(index),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  );
                },
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addMilestoneField,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar milestone'),
              ),
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Revisão'),
        isActive: _currentStep >= 3,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titleController.text.trim().isEmpty
                  ? 'Sem título'
                  : _titleController.text.trim(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Prazo: ${_formatDeadline(_targetDate)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Porquê',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _reasonController.text.trim().isEmpty
                  ? 'Sem descrição'
                  : _reasonController.text.trim(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Milestones',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._milestones
                .map((milestone) => milestone.controller.text.trim())
                .where((text) => text.isNotEmpty)
                .map(
                  (text) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      '• $text',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
            if (_milestones
                .map((milestone) => milestone.controller.text.trim())
                .where((text) => text.isNotEmpty)
                .isEmpty)
              Text(
                'Nenhuma milestone definida.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.goal == null
                ? AppStrings.addGoalTitle
                : AppStrings.editGoalTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Flexible(
            child: Stepper(
              currentStep: _currentStep,
              steps: _buildSteps(),
              controlsBuilder: (context, details) {
                final isLastStep = _currentStep == _buildSteps().length - 1;
                return Row(
                  children: [
                    AppPrimaryButton(
                      label: isLastStep ? AppStrings.save : AppStrings.advance,
                      isFullWidth: false,
                      onPressed: _canContinue()
                          ? () {
                              if (isLastStep) {
                                _saveGoal();
                              } else {
                                setState(() {
                                  _currentStep += 1;
                                });
                              }
                            }
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    if (_currentStep > 0)
                      AppSecondaryButton(
                        label: AppStrings.back,
                        isFullWidth: false,
                        onPressed: () {
                          setState(() {
                            _currentStep -= 1;
                          });
                        },
                      ),
                  ],
                );
              },
              onStepTapped: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneDraft {
  _MilestoneDraft({
    required this.id,
    required this.controller,
    required this.isCompleted,
    required this.completedAt,
  });

  final String id;
  final TextEditingController controller;
  final bool isCompleted;
  final DateTime? completedAt;

  factory _MilestoneDraft.create() {
    return _MilestoneDraft(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      controller: TextEditingController(),
      isCompleted: false,
      completedAt: null,
    );
  }

  factory _MilestoneDraft.fromMilestone(Milestone milestone) {
    return _MilestoneDraft(
      id: milestone.id.isEmpty
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : milestone.id,
      controller: TextEditingController(text: milestone.text),
      isCompleted: milestone.isCompleted,
      completedAt: milestone.completedAt,
    );
  }

  void dispose() {
    controller.dispose();
  }
}
