import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/goal.dart';
import '../models/habit.dart';
import '../models/milestone.dart';
import '../models/routine.dart';
import '../services/auth_service.dart';
import '../services/data_provider.dart';
import '../theme/app_theme.dart';
import 'goal_wizard.dart';
import 'routine_detail_screen.dart';
import '../widgets/neuro_card.dart';

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

  void _showCreateModal() {
    final dataProvider = context.read<DataProvider>();
    final titleController = TextEditingController();
    var selectedType = _CreationType.habit;
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
                left: 24,
                right: 24,
                top: 24,
                bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Criar novo',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    children: [
                      ChoiceChip(
                        label: const Text('Hábito'),
                        selected: selectedType == _CreationType.habit,
                        onSelected: (_) {
                          setModalState(() {
                            selectedType = _CreationType.habit;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Rotina'),
                        selected: selectedType == _CreationType.routine,
                        onSelected: (_) {
                          setModalState(() {
                            selectedType = _CreationType.routine;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
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
                      child: const Text('Salvar'),
                    ),
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
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
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
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: habits.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final habit = habits[index];
            final isCompleted = habit.isCompletedToday;

            return NeuroCard(
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
                    const SizedBox(width: 16),
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
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle, size: 18),
                                  SizedBox(width: 8),
                                  Text('Feito'),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              key: const ValueKey('check'),
                              onPressed: () async {
                                await context
                                    .read<DataProvider>()
                                    .updateHabitCompletion(
                                      habit: habit,
                                      isCompletedToday: true,
                                    );
                              },
                              child: const Text('Check'),
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
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: routines.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final routine = routines[index];
            return NeuroCard(
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
                    const SizedBox(height: 8),
                    Text(
                      routine.triggerTime,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
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
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: goals.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final goal = goals[index];
            final totalMilestones = goal.milestones.length;
            final completedMilestones = goal.milestones
                .where((milestone) => milestone.isCompleted)
                .length;
            final progress = totalMilestones == 0
                ? 0.0
                : completedMilestones / totalMilestones;

            return NeuroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    goal.reason.isEmpty ? 'Sem propósito' : goal.reason,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor:
                          theme.colorScheme.onSurface.withOpacity(0.12),
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$completedMilestones de $totalMilestones milestones concluídas',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedText,
                    ),
                  ),
                  if (goal.milestones.isNotEmpty) ...[
                    const SizedBox(height: 12),
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
                                          .withOpacity(0.6)
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
        padding: const EdgeInsets.all(20),
        child: NeuroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proteja seus dados',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Faça login para salvar seu progresso e sincronizar em todos os dispositivos.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
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
                            content:
                                Text('Não foi possível autenticar agora.'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Entrar com Google'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: NeuroCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.displayName ?? 'Usuário conectado',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.email ?? 'Email não informado',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await authService.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
              ),
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
              onPressed: _currentIndex == _goalsTabIndex
                  ? _showGoalWizard
                  : _showCreateModal,
              child: const Icon(Icons.add, size: 32),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TabData {
  const _TabData(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum _CreationType { habit, routine }
