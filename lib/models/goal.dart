import 'milestone.dart';

class Goal {
  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    required this.reason,
    required this.deadline,
    required this.milestones,
  });

  final String id;
  final String userId;
  final String title;
  final String reason;
  final DateTime? deadline;
  final List<Milestone> milestones;

  factory Goal.fromMap(Map<String, dynamic> map, {String? id}) {
    return Goal(
      id: (map['id'] as String?) ?? id ?? '',
      userId: (map['userId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      reason: (map['reason'] as String?) ?? '',
      deadline: _dateTimeFromMap(map['deadline']),
      milestones: (map['milestones'] as List<dynamic>?)
              ?.map((value) => Milestone.fromMap(
                    Map<String, dynamic>.from(value as Map),
                  ))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'reason': reason,
      'deadline': deadline?.toIso8601String(),
      'milestones': milestones.map((milestone) => milestone.toMap()).toList(),
    };
  }

  static DateTime? _dateTimeFromMap(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.parse(value);
    }

    return null;
  }
}
