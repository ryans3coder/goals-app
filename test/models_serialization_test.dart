import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/category.dart';
import 'package:flutter_application_1/models/goal.dart';
import 'package:flutter_application_1/models/habit.dart';
import 'package:flutter_application_1/models/milestone.dart';
import 'package:flutter_application_1/models/routine.dart';
import 'package:flutter_application_1/models/routine_step.dart';

void main() {
  test('habit serializes with category', () {
    final habit = Habit(
      id: 'habit-1',
      userId: 'user-1',
      title: 'Beber água',
      frequency: const ['daily'],
      currentStreak: 2,
      isCompletedToday: true,
      categoryId: 'cat-1',
    );

    final restored = Habit.fromMap(habit.toMap());

    expect(restored.id, habit.id);
    expect(restored.categoryId, habit.categoryId);
    expect(restored.frequency, habit.frequency);
  });

  test('goal serializes smart fields', () {
    final goal = Goal(
      id: 'goal-1',
      userId: 'user-1',
      title: 'Meta',
      reason: 'Motivo',
      deadline: DateTime(2030, 1, 1),
      milestones: const [Milestone(title: 'M1', isCompleted: false)],
      specific: 'Específica',
      measurable: 'Mensurável',
      achievable: 'Alcançável',
      relevant: 'Relevante',
      timeBound: DateTime(2030, 1, 1),
      categoryId: 'cat-1',
    );

    final restored = Goal.fromMap(goal.toMap());

    expect(restored.specific, goal.specific);
    expect(restored.timeBound?.year, 2030);
    expect(restored.categoryId, goal.categoryId);
  });

  test('routine step serializes', () {
    final step = RoutineStep(
      id: 'step-1',
      routineId: 'routine-1',
      habitId: 'habit-1',
      order: 1,
      durationMinutes: 5,
    );

    final restored = RoutineStep.fromMap(step.toMap());

    expect(restored.routineId, step.routineId);
    expect(restored.habitId, step.habitId);
    expect(restored.durationMinutes, step.durationMinutes);
  });

  test('category serializes', () {
    final category = Category(
      id: 'cat-1',
      userId: 'user-1',
      title: 'Bem-estar',
      colorHex: '#FF0000',
      icon: 'heart',
    );

    final restored = Category.fromMap(category.toMap());

    expect(restored.title, category.title);
    expect(restored.colorHex, category.colorHex);
  });

  test('routine serializes with category', () {
    final routine = Routine(
      id: 'routine-1',
      userId: 'user-1',
      title: 'Manhã',
      icon: 'sun',
      triggerTime: '07:00',
      steps: const ['habit-1'],
      categoryId: 'cat-1',
    );

    final restored = Routine.fromMap(routine.toMap());

    expect(restored.categoryId, routine.categoryId);
    expect(restored.steps, routine.steps);
  });
}
