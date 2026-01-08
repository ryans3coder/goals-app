import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/goal.dart';
import 'package:flutter_application_1/models/milestone.dart';

void main() {
  test('milestone reorder preserves order after persistence', () {
    final initialMilestones = [
      const Milestone(
        id: 'm1',
        goalId: 'g1',
        text: 'Aprender',
        order: 0,
        isCompleted: false,
      ),
      const Milestone(
        id: 'm2',
        goalId: 'g1',
        text: 'Praticar',
        order: 1,
        isCompleted: false,
      ),
      const Milestone(
        id: 'm3',
        goalId: 'g1',
        text: 'Compartilhar',
        order: 2,
        isCompleted: false,
      ),
    ];

    final reordered = [
      initialMilestones[2],
      initialMilestones[0],
      initialMilestones[1],
    ].asMap().entries.map((entry) {
      final milestone = entry.value;
      return Milestone(
        id: milestone.id,
        goalId: milestone.goalId,
        text: milestone.text,
        order: entry.key,
        isCompleted: milestone.isCompleted,
        completedAt: milestone.completedAt,
      );
    }).toList();

    final goal = Goal(
      id: 'g1',
      userId: 'user-1',
      title: 'Meta',
      reason: 'Motivo',
      createdAt: DateTime(2024, 1, 1),
      targetDate: DateTime(2024, 12, 31),
      status: GoalStatus.active,
      milestones: reordered,
      specific: 'Específica',
      relevant: 'Relevante',
    );

    final restored = Goal.fromMap(goal.toMap());

    expect(restored.milestones.map((item) => item.text).toList(), [
      'Compartilhar',
      'Aprender',
      'Praticar',
    ]);
    expect(restored.milestones.map((item) => item.order).toList(), [0, 1, 2]);
  });
}
