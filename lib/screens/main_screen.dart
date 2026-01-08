import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/goal.dart';
import '../models/habit.dart';
import '../models/milestone.dart';
import '../models/routine.dart';
import '../domain/habits/habit_form_options.dart';
import '../services/data_provider.dart';
import '../services/feedback_manager.dart';
import '../theme/app_theme.dart';
import '../theme/app_strings.dart';
import 'backup_screen.dart';
import 'goal_wizard.dart';
import 'habit_categories_screen.dart';
import 'habit_form_screen.dart';
import 'stats_screen.dart';
import 'routine_detail_screen.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_card.dart';
import '../widgets/app_progress_bar.dart';
import '../widgets/app_segmented_control.dart';
import '../widgets/empty_state_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final FeedbackManager _feedbackManager;

  @override
  void initState() {
    super.initState();
    _feedbackManager = const FeedbackManager();
  }

  static const _habitsTabIndex = 0;
  static const _routinesTabIndex = 1;
  static const _goalsTabIndex = 2;
  static const _profileTabIndex = 3;
  static const _tabs = [
    _TabData('Hábitos', Icons.check_circle_outline),
    _TabData('Rotinas', Icons.schedule),
    _TabData('Metas', Icons.flag),
    _TabData('Perfil', Icons.person_outline),
  ];

  static const _creationOptions = [
    SegmentedOption(
      value: _CreationType.habit,
      label: AppStrings.habitLabel,
      icon: Icons.check_circle_outline,
    ),
    SegmentedOption(
      value: _CreationType.routine,
      label: AppStrings.routineLabel,
      icon: Icons.schedule,
    ),
  ];

  void _openHabitForm({Habit? habit}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HabitFormScreen(habit: habit),
      ),
    );
  }

  void _showCreateModal({required _CreationType initialType}) {
    if (initialType == _CreationType.habit) {
      _openHabitForm();
      return;
    }

    final dataProvider = context.read<DataProvider>();
    final titleController = TextEditingController();
    var selectedType = initialType;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.bottomSheetTheme.modalBackgroundColor ??
          theme.colorScheme.surface,
      shape: theme.bottomSheetTheme.shape,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                top: AppSpacing.xl,
                bottom: AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.createNew,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppSegmentedControl<_CreationType>(
                    options: _creationOptions,
                    selected: selectedType,
                    onChanged: (value) {
                      setModalState(() {
                        selectedType = value;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (selectedType == _CreationType.habit) ...[
                    Text(
                      AppStrings.habitCreateHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textBody,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppPrimaryButton(
                      label: AppStrings.habitCreateAction,
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openHabitForm();
                      },
                    ),
                  ] else ...[
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.nameLabel,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppPrimaryButton(
                      label: AppStrings.save,
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(AppStrings.nameRequired),
                            ),
                          );
                          return;
                        }

                        await dataProvider.addRoutine(
                          Routine(
                            id: '',
                            userId: '',
                            title: title,
                            icon: '',
                            triggerTime: '',
                            steps: const [],
                          ),
                        );

                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(titleController.dispose);
  }

  void _showGoalWizard({Goal? goal}) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          theme.bottomSheetTheme.modalBackgroundColor ?? theme.cardColor,
      shape: theme.bottomSheetTheme.shape,
      builder: (context) => GoalWizard(goal: goal),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return EmptyStateWidget(
      icon: icon,
      title: title,
      description: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  Widget _buildHabitsTab() {
    final categories = context.watch<DataProvider>().categories;
    final categoryLookup = {
      for (final category in categories) category.id: category,
    };
    return StreamBuilder<List<Habit>>(
      stream: context.read<DataProvider>().watchHabits(),
      builder: (context, snapshot) {
        final habits = snapshot.data ?? const [];
        final theme = Theme.of(context);

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildEmptyState(
            icon: Icons.self_improvement,
            title: AppStrings.habitLoadErrorTitle,
            message: AppStrings.habitLoadErrorMessage,
            actionLabel: AppStrings.createHabit,
            onAction: _openHabitForm,
          );
        }

        if (habits.isEmpty) {
          return _buildEmptyState(
            icon: Icons.self_improvement,
            title: AppStrings.habitEmptyTitle,
            message: AppStrings.habitEmptyMessage,
            actionLabel: AppStrings.createHabit,
            onAction: _openHabitForm,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.page),
          itemCount: habits.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
          itemBuilder: (context, index) {
            final habit = habits[index];
            final isCompleted = habit.isCompletedToday;
            final emoji = habit.emoji.isNotEmpty
                ? habit.emoji
                : HabitFormOptions.fallbackEmoji;
            final categoryId = habit.categoryId;
            final category = categoryId != null
                ? categoryLookup[categoryId]
                : null;
            final categoryLabel = category != null
                ? '${category.emoji} ${category.name}'
                : (categoryId != null && categoryId.isNotEmpty
                    ? categoryId
                    : AppStrings.habitNoCategory);

            return AppCard(
              onTap: () => _openHabitForm(habit: habit),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: isCompleted ? 0.7 : 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            emoji,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  categoryLabel,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textBody,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: isCompleted
                          ? Container(
                              key: const ValueKey('done'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.secondary.withValues(
                                      alpha: 0.18,
                                    ),
                                borderRadius:
                                    BorderRadius.circular(AppRadii.input),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: AppSizes.iconSmall,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(AppStrings.completed),
                                ],
                              ),
                            )
                          : AppPrimaryButton(
                              key: const ValueKey('check'),
                              onPressed: () async {
                                await context
                                    .read<DataProvider>()
                                    .updateHabitCompletion(
                                      habit: habit,
                                      isCompletedToday: true,
                                    );
                              },
                              label: AppStrings.complete,
                              isFullWidth: false,
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoutinesTab() {
    return StreamBuilder<List<Routine>>(
      stream: context.read<DataProvider>().watchRoutines(),
      builder: (context, snapshot) {
        final routines = snapshot.data ?? const [];
        final theme = Theme.of(context);

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (routines.isEmpty) {
          return _buildEmptyState(
            icon: Icons.nights_stay_outlined,
            title: AppStrings.routineEmptyTitle,
            message: AppStrings.routineEmptyMessage,
            actionLabel: AppStrings.createRoutine,
            onAction: () => _showCreateModal(
              initialType: _CreationType.routine,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.page),
          itemCount: routines.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
          itemBuilder: (context, index) {
            final routine = routines[index];
            return AppCard(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RoutineDetailScreen(routine: routine),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (routine.triggerTime.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      routine.triggerTime,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGoalsTab() {
    return StreamBuilder<List<Goal>>(
      stream: context.read<DataProvider>().watchGoals(),
      builder: (context, snapshot) {
        final goals = snapshot.data ?? const [];
        final theme = Theme.of(context);

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (goals.isEmpty) {
          return _buildEmptyState(
            icon: Icons.emoji_events_outlined,
            title: AppStrings.goalEmptyTitle,
            message: AppStrings.goalEmptyMessage,
            actionLabel: AppStrings.createGoal,
            onAction: _showGoalWizard,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.page),
          itemCount: goals.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
          itemBuilder: (context, index) {
            final goal = goals[index];
            final orderedMilestones = goal.milestones.toList()
              ..sort((a, b) => a.order.compareTo(b.order));
            final totalMilestones = orderedMilestones.length;
            final completedMilestones = orderedMilestones
                .where((milestone) => milestone.isCompleted)
                .length;
            final progress = totalMilestones == 0
                ? 0.0
                : completedMilestones / totalMilestones;
            final progressLabel = (progress * 100).round();

            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goal.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showGoalWizard(goal: goal),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    goal.reason.isEmpty ? AppStrings.goalNoReason : goal.reason,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppProgressBar(value: progress),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.goalProgressSummary(
                      percent: progressLabel,
                      completed: completedMilestones,
                      total: totalMilestones,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                  if (orderedMilestones.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    ...orderedMilestones.asMap().entries.map(
                      (entry) {
                        final milestone = entry.value;
                        return Row(
                          children: [
                            Checkbox(
                              value: milestone.isCompleted,
                              onChanged: (value) async {
                                final updatedMilestones = [
                                  for (final item in orderedMilestones)
                                    Milestone(
                                      id: item.id,
                                      goalId: item.goalId,
                                      text: item.text,
                                      order: item.order,
                                      isCompleted: item.isCompleted,
                                      completedAt: item.completedAt,
                                    ),
                                ];
                                final isCompleted = value ?? false;
                                updatedMilestones[entry.key] = Milestone(
                                  id: milestone.id,
                                  goalId: milestone.goalId,
                                  text: milestone.text,
                                  order: milestone.order,
                                  isCompleted: isCompleted,
                                  completedAt:
                                      isCompleted ? DateTime.now() : null,
                                );
                                final isGoalCompleted = updatedMilestones
                                    .every((item) => item.isCompleted);
                                await context
                                    .read<DataProvider>()
                                    .updateGoalMilestones(
                                      goal: Goal(
                                        id: goal.id,
                                        userId: goal.userId,
                                        title: goal.title,
                                        reason: goal.reason,
                                        createdAt: goal.createdAt,
                                        targetDate: goal.targetDate,
                                        status: goal.status,
                                        milestones: updatedMilestones,
                                        specific: goal.specific,
                                        measurable: goal.measurable,
                                        achievable: goal.achievable,
                                        relevant: goal.relevant,
                                        timeBound: goal.timeBound,
                                        categoryId: goal.categoryId,
                                      ),
                                    );
                                if (isGoalCompleted &&
                                    goal.status != GoalStatus.completed) {
                                  await _feedbackManager.triggerVictoryFeedback(
                                    context
                                        .read<DataProvider>()
                                        .feedbackPreferences,
                                  );
                                }
                              },
                            ),
                            Expanded(
                              child: Text(
                                milestone.text,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: milestone.isCompleted
                                      ? theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6)
                                  : theme.colorScheme.onSurface,
                                  decoration: milestone.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab() {
    final theme = Theme.of(context);
    final dataProvider = context.watch<DataProvider>();
    final feedbackPreferences = dataProvider.feedbackPreferences;

    final sections = <Widget>[];

    sections.add(
      AppCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            AppStrings.habitCategoryManageLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            AppStrings.habitCategoryManageHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textBody,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HabitCategoriesScreen(),
              ),
            );
          },
        ),
      ),
    );

    sections.add(
      AppCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            AppStrings.backupTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            AppStrings.backupHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textBody,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BackupScreen(),
              ),
            );
          },
        ),
      ),
    );

    sections.add(
      AppCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            AppStrings.statsTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            AppStrings.statsShortcutHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textBody,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const StatsScreen(),
              ),
            );
          },
        ),
      ),
    );

    sections.add(
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.feedbackPreferencesTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.feedbackPreferencesHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textBody,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.feedbackSoundLabel),
              value: feedbackPreferences.soundEnabled,
              onChanged: (value) {
                dataProvider.updateFeedbackPreferences(
                  feedbackPreferences.copyWith(soundEnabled: value),
                );
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.feedbackAnimationsLabel),
              value: feedbackPreferences.animationsEnabled,
              onChanged: (value) {
                dataProvider.updateFeedbackPreferences(
                  feedbackPreferences.copyWith(animationsEnabled: value),
                );
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.feedbackHapticLabel),
              value: feedbackPreferences.hapticEnabled,
              onChanged: (value) {
                dataProvider.updateFeedbackPreferences(
                  feedbackPreferences.copyWith(hapticEnabled: value),
                );
              },
            ),
          ],
        ),
      ),
    );

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.page),
      itemCount: sections.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) => sections[index],
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = _tabs[_currentIndex];
    final showFab = _currentIndex == _habitsTabIndex ||
        _currentIndex == _routinesTabIndex ||
        _currentIndex == _goalsTabIndex;

    Widget body;
    switch (_currentIndex) {
      case _habitsTabIndex:
        body = _buildHabitsTab();
        break;
      case _routinesTabIndex:
        body = _buildRoutinesTab();
        break;
      case _goalsTabIndex:
        body = _buildGoalsTab();
        break;
      case _profileTabIndex:
        body = _buildProfileTab();
        break;
      default:
        body = _buildEmptyState(
          icon: activeTab.icon,
          title: activeTab.label,
          message: AppStrings.placeholderEmptyMessage,
          actionLabel: AppStrings.createHabit,
          onAction: () => _showCreateModal(
            initialType: _CreationType.habit,
          ),
        );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          activeTab.label,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
      body: body,
      floatingActionButton: showFab
          ? FloatingActionButton.large(
              onPressed: () {
                if (_supportsHaptics()) {
                  HapticFeedback.lightImpact();
                }
                if (_currentIndex == _goalsTabIndex) {
                  _showGoalWizard();
                  return;
                }
                _showCreateModal(
                  initialType: _currentIndex == _routinesTabIndex
                      ? _CreationType.routine
                      : _CreationType.habit,
                );
              },
              child: const Icon(Icons.add, size: AppSizes.iconFab),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: _tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }

  bool _supportsHaptics() {
    if (kIsWeb) {
      return false;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return false;
    }
  }
}

class _TabData {
  const _TabData(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum _CreationType { habit, routine }
