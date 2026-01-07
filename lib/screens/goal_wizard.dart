import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/goal.dart';
import '../models/milestone.dart';
import '../services/data_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_strings.dart';
import '../widgets/app_buttons.dart';

class GoalWizard extends StatefulWidget {
  const GoalWizard({super.key});

  @override
  State<GoalWizard> createState() => _GoalWizardState();
}

class _GoalWizardState extends State<GoalWizard> {
  final _titleController = TextEditingController();
  final _reasonController = TextEditingController();
  final List<TextEditingController> _milestoneControllers = [];
  int _currentStep = 0;
  DateTime? _deadline;

  @override
  void dispose() {
    _titleController.dispose();
    _reasonController.dispose();
    for (final controller in _milestoneControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addMilestoneField() {
    setState(() {
      _milestoneControllers.add(TextEditingController());
    });
  }

  void _removeMilestoneField(int index) {
    setState(() {
      _milestoneControllers[index].dispose();
      _milestoneControllers.removeAt(index);
    });
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (selected != null) {
      setState(() {
        _deadline = selected;
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

    final milestones = _milestoneControllers
        .map((controller) => controller.text.trim())
        .where((title) => title.isNotEmpty)
        .map((title) => Milestone(title: title, isCompleted: false))
        .toList();

    final goal = Goal(
      id: '',
      userId: '',
      title: title,
      reason: _reasonController.text.trim(),
      deadline: _deadline,
      milestones: milestones,
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
                    _formatDeadline(_deadline),
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
            if (_milestoneControllers.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nenhuma milestone adicionada.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            for (int index = 0; index < _milestoneControllers.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _milestoneControllers[index],
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
              'Prazo: ${_formatDeadline(_deadline)}',
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
            ..._milestoneControllers
                .map((controller) => controller.text.trim())
                .where((title) => title.isNotEmpty)
                .map(
                  (title) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      '• $title',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
            if (_milestoneControllers
                .map((controller) => controller.text.trim())
                .where((title) => title.isNotEmpty)
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
            AppStrings.addGoalTitle,
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
