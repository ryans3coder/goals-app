import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../models/routine.dart';
import '../services/auth_service.dart';
import '../services/data_provider.dart';
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

  static const _tabs = [
    _TabData('Hábitos', Icons.check_circle_outline),
    _TabData('Rotinas', Icons.schedule),
    _TabData('Metas', Icons.flag),
    _TabData('Estatísticas', Icons.bar_chart),
  ];

  void _showCreateModal() {
    final dataProvider = context.read<DataProvider>();
    final titleController = TextEditingController();
    var selectedType = _CreationType.habit;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
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

  Widget _buildPlaceholder(String label) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: NeuroCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Em breve você verá seus dados aqui.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
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

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (habits.isEmpty) {
          return _buildPlaceholder('Sem hábitos por enquanto.');
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
                        style: GoogleFonts.inter(
                          fontSize: 18,
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
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: const [
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

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (routines.isEmpty) {
          return _buildPlaceholder('Sem rotinas por enquanto.');
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
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (routine.triggerTime.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      routine.triggerTime,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white70,
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

  @override
  Widget build(BuildContext context) {
    final activeTab = _tabs[_currentIndex];
    final showFab =
        _currentIndex == _habitsTabIndex || _currentIndex == _routinesTabIndex;

    Widget body;
    switch (_currentIndex) {
      case _habitsTabIndex:
        body = _buildHabitsTab();
        break;
      case _routinesTabIndex:
        body = _buildRoutinesTab();
        break;
      default:
        body = _buildPlaceholder(activeTab.label);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(activeTab.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: body,
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: _showCreateModal,
              child: const Icon(Icons.add),
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
