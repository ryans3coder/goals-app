import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/habit_category.dart';
import 'package:flutter_application_1/models/goal.dart';
import 'package:flutter_application_1/models/habit.dart';
import 'package:flutter_application_1/models/feedback_preferences.dart';
import 'package:flutter_application_1/models/milestone.dart';
import 'package:flutter_application_1/models/routine.dart';
import 'package:flutter_application_1/models/routine_event.dart';
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

  test('habit serializes without category', () {
    final habit = Habit(
      id: 'habit-2',
      userId: 'user-2',
      title: 'Meditar',
      frequency: const ['daily'],
      currentStreak: 0,
      isCompletedToday: false,
    );

    final restored = Habit.fromMap(habit.toMap());

    expect(restored.id, habit.id);
    expect(restored.categoryId, isNull);
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
      durationSeconds: 300,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    final restored = RoutineStep.fromMap(step.toMap());

    expect(restored.routineId, step.routineId);
    expect(restored.habitId, step.habitId);
    expect(restored.durationSeconds, step.durationSeconds);
    expect(restored.createdAt?.year, 2024);
    expect(restored.updatedAt?.day, 2);
  });

  test('habit category serializes', () {
    final category = HabitCategory(
      id: 'cat-1',
      name: 'Bem-estar',
      emoji: '🌿',
      colorToken: 'primary',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    final restored = HabitCategory.fromMap(category.toMap());

    expect(restored.name, category.name);
    expect(restored.emoji, category.emoji);
    expect(restored.colorToken, category.colorToken);
    expect(restored.createdAt?.year, 2024);
    expect(restored.updatedAt?.day, 2);
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

  test('routine event serializes', () {
    final event = RoutineEvent(
      id: 'event-1',
      type: RoutineEventType.stepCompleted,
      routineId: 'routine-1',
      habitId: 'habit-1',
      stepIndex: 2,
      metadata: const {'executionId': 'run-1'},
      timestamp: DateTime(2024, 1, 1, 8, 0),
    );

    final restored = RoutineEvent.fromMap(event.toMap());

    expect(restored.id, event.id);
    expect(restored.type, RoutineEventType.stepCompleted);
    expect(restored.routineId, event.routineId);
    expect(restored.habitId, event.habitId);
    expect(restored.stepIndex, event.stepIndex);
    expect(restored.metadata?['executionId'], 'run-1');
    expect(restored.timestamp.year, 2024);
  });

  test('feedback preferences serializes', () {
    const preferences = FeedbackPreferences(
      soundEnabled: false,
      animationsEnabled: true,
      hapticEnabled: false,
    );

    final restored = FeedbackPreferences.fromMap(preferences.toMap());

    expect(restored.soundEnabled, isFalse);
    expect(restored.animationsEnabled, isTrue);
    expect(restored.hapticEnabled, isFalse);
  });
}
