import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/goal.dart';
import '../models/habit.dart';
import '../models/milestone.dart';
import '../models/routine.dart';
import '../services/auth_service.dart';
import '../services/data_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_strings.dart';
import 'goal_wizard.dart';
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

  void _showCreateModal({required _CreationType initialType}) {
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
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
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
                            content: Text('Informe um nome para continuar.'),
                          ),
                        );
                        return;
                      }

                      if (selectedType == _CreationType.habit) {
                        await dataProvider.addHabit(
                          Habit(
                            id: '',
                            userId: '',
                            title: title,
                            frequency: const ['daily'],
                            currentStreak: 0,
                            isCompletedToday: false,
                          ),
                        );
                      } else {
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
      },
    ).whenComplete(titleController.dispose);
  }

  void _showGoalWizard() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          theme.bottomSheetTheme.modalBackgroundColor ?? theme.cardColor,
      shape: theme.bottomSheetTheme.shape,
      builder: (context) => const GoalWizard(),
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
    return StreamBuilder<List<Habit>>(
      stream: context.read<DataProvider>().watchHabits(),
      builder: (context, snapshot) {
        final habits = snapshot.data ?? const [];
        final theme = Theme.of(context);

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (habits.isEmpty) {
          return _buildEmptyState(
            icon: Icons.self_improvement,
            title: 'Sem hábitos por enquanto.',
            message: 'Comece criando seu primeiro hábito diário.',
            actionLabel: AppStrings.createHabit,
            onAction: () => _showCreateModal(
              initialType: _CreationType.habit,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.page),
          itemCount: habits.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
          itemBuilder: (context, index) {
            final habit = habits[index];
            final isCompleted = habit.isCompletedToday;

            return AppCard(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: isCompleted ? 0.7 : 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        habit.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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
                                    theme.colorScheme.tertiary.withValues(
                                      alpha: 0.18,
                                    ),
                                borderRadius:
                                    BorderRadius.circular(AppRadii.sm),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: AppSizes.iconSmall,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(AppStrings.done),
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
                              label: AppStrings.check,
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
            title: 'Sem rotinas por enquanto.',
            message: 'Crie uma rotina para manter o foco no dia.',
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
                        color: AppColors.textMuted,
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
            title: 'Sem metas por enquanto.',
            message: 'Defina uma meta e acompanhe seu progresso.',
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
            final totalMilestones = goal.milestones.length;
            final completedMilestones = goal.milestones
                .where((milestone) => milestone.isCompleted)
                .length;
            final progress = totalMilestones == 0
                ? 0.0
                : completedMilestones / totalMilestones;

            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    goal.reason.isEmpty ? 'Sem propósito' : goal.reason,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppProgressBar(value: progress),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '$completedMilestones de $totalMilestones milestones concluídas',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (goal.milestones.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    ...goal.milestones.asMap().entries.map(
                      (entry) {
                        final milestone = entry.value;
                        return Row(
                          children: [
                            Checkbox(
                              value: milestone.isCompleted,
                              onChanged: (value) async {
                                final updatedMilestones = [
                                  for (final item in goal.milestones)
                                    Milestone(
                                      title: item.title,
                                      isCompleted: item.isCompleted,
                                    ),
                                ];
                                updatedMilestones[entry.key] = Milestone(
                                  title: milestone.title,
                                  isCompleted: value ?? false,
                                );
                                await context
                                    .read<DataProvider>()
                                    .updateGoalMilestones(
                                      goal: Goal(
                                        id: goal.id,
                                        userId: goal.userId,
                                        title: goal.title,
                                        reason: goal.reason,
                                        deadline: goal.deadline,
                                        milestones: updatedMilestones,
                                      ),
                                    );
                              },
                            ),
                            Expanded(
                              child: Text(
                                milestone.title,
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
    final user = context.watch<firebase_auth.User?>();
    final authService = context.read<AuthService>();

    if (user == null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proteja seus dados',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Faça login para salvar seu progresso e sincronizar em todos os dispositivos.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.page),
              AppPrimaryButton(
                label: AppStrings.signInGoogle,
                icon: const Icon(Icons.login),
                onPressed: () async {
                  try {
                    await authService.signInWithGoogle();
                  } on StateError catch (error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.message)),
                      );
                    }
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Não foi possível autenticar agora.'),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.displayName ?? 'Usuário conectado',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              user.email ?? 'Email não informado',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.page),
            AppSecondaryButton(
              label: AppStrings.signOut,
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await authService.signOut();
              },
            ),
          ],
        ),
      ),
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
          message: 'Em breve você verá seus dados aqui.',
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
