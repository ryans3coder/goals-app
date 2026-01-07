import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/backup_snapshot.dart';
import 'package:flutter_application_1/models/feedback_preferences.dart';
import 'package:flutter_application_1/models/goal.dart';
import 'package:flutter_application_1/models/habit.dart';
import 'package:flutter_application_1/models/habit_category.dart';
import 'package:flutter_application_1/models/milestone.dart';
import 'package:flutter_application_1/models/routine.dart';
import 'package:flutter_application_1/models/routine_event.dart';
import 'package:flutter_application_1/models/routine_step.dart';

void main() {
  test('backup snapshot serializes schema version and roundtrip', () {
    final snapshot = BackupSnapshot(
      schemaVersion: BackupSnapshot.currentSchemaVersion,
      timestamp: DateTime(2024, 5, 1, 10, 30),
      habits: [
        Habit(
          id: 'habit-1',
          userId: 'user-1',
          title: 'Beber água',
          frequency: const ['daily'],
          currentStreak: 2,
          isCompletedToday: true,
          categoryId: 'cat-1',
        ),
      ],
      routines: [
        Routine(
          id: 'routine-1',
          userId: 'user-1',
          title: 'Manhã',
          icon: 'sun',
          triggerTime: '07:00',
          steps: const ['habit-1'],
          categoryId: 'cat-1',
        ),
      ],
      routineSteps: [
        RoutineStep(
          id: 'step-1',
          routineId: 'routine-1',
          habitId: 'habit-1',
          order: 0,
          durationSeconds: 60,
          createdAt: DateTime(2024, 5, 1),
          updatedAt: DateTime(2024, 5, 2),
        ),
      ],
      goals: [
        Goal(
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
        ),
      ],
      categories: [
        HabitCategory(
          id: 'cat-1',
          name: 'Bem-estar',
          emoji: '🌿',
          colorToken: 'primary',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        ),
      ],
      feedbackPreferences: const FeedbackPreferences(
        soundEnabled: false,
        animationsEnabled: true,
        hapticEnabled: false,
      ),
      routineEvents: [
        RoutineEvent(
          id: 'event-1',
          type: RoutineEventType.stepCompleted,
          routineId: 'routine-1',
          executionId: 'run-1',
          habitId: 'habit-1',
          stepIndex: 0,
          metadata: const {'eventContract': 'step_completed'},
          timestamp: DateTime(2024, 5, 1, 8, 0),
        ),
      ],
    );

    final restored = BackupSnapshot.fromMap(snapshot.toMap());

    expect(restored.schemaVersion, BackupSnapshot.currentSchemaVersion);
    expect(restored.timestamp, snapshot.timestamp);
    expect(restored.habits.first.id, snapshot.habits.first.id);
    expect(restored.routineSteps.first.durationSeconds, 60);
    expect(restored.goals.first.title, snapshot.goals.first.title);
    expect(restored.categories.first.name, snapshot.categories.first.name);
    expect(restored.feedbackPreferences.hapticEnabled, isFalse);
    expect(restored.routineEvents.first.id, snapshot.routineEvents.first.id);
  });
}
