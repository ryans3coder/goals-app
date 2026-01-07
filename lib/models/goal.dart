import 'milestone.dart';

class Goal {
  Goal({
    required this.id,
    required this.userId,
    required this.title,
    required this.reason,
    required this.deadline,
    required List<Milestone> milestones,
  }) : milestones = List.unmodifiable(milestones);

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
      deadline: _parseDateTime(map['deadline']),
      milestones: _parseMilestones(map['milestones']),
    );
  }

  factory Goal.fromJson(Map<String, dynamic> json, {String? id}) {
    return Goal.fromMap(json, id: id);
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

  Map<String, dynamic> toJson() {
    return toMap();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<Milestone> _parseMilestones(dynamic value) {
    if (value is List) {
      return List<Milestone>.unmodifiable(
        value
            .whereType<Map>()
            .map((item) =>
                Milestone.fromMap(Map<String, dynamic>.from(item))),
      );
    }
    return const [];
  }
}
