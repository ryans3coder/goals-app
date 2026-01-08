import 'milestone.dart';

enum GoalStatus {
  active,
  completed,
}

extension GoalStatusCodec on GoalStatus {
  String get value => switch (this) {
        GoalStatus.active => 'active',
        GoalStatus.completed => 'completed',
      };

  static GoalStatus fromValue(String? value) {
    return switch (value) {
      'completed' => GoalStatus.completed,
      _ => GoalStatus.active,
    };
  }
}

class Goal {
  Goal({
    required this.id,
    required this.userId,
    required this.title,
    required this.reason,
    required this.createdAt,
    required this.targetDate,
    required this.status,
    required List<Milestone> milestones,
    this.specific = '',
    this.measurable = '',
    this.achievable = '',
    this.relevant = '',
    this.timeBound,
    this.categoryId = '',
  }) : milestones = List.unmodifiable(milestones);

  final String id;
  final String userId;
  final String title;
  final String reason;
  final DateTime createdAt;
  final DateTime? targetDate;
  final GoalStatus status;
  final List<Milestone> milestones;
  final String specific;
  final String measurable;
  final String achievable;
  final String relevant;
  final DateTime? timeBound;
  final String categoryId;

  factory Goal.fromMap(Map<String, dynamic> map, {String? id}) {
    final fallbackTargetDate = _parseDateTime(map['deadline']);
    final createdAt =
        _parseDateTime(map['createdAt']) ?? DateTime.now().toUtc();
    return Goal(
      id: (map['id'] as String?) ?? id ?? '',
      userId: (map['userId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      reason: (map['reason'] as String?) ?? '',
      createdAt: createdAt,
      targetDate: _parseDateTime(map['targetDate']) ?? fallbackTargetDate,
      status: GoalStatusCodec.fromValue(map['status'] as String?),
      milestones: _parseMilestones(map['milestones']),
      specific: (map['specific'] as String?) ?? '',
      measurable: (map['measurable'] as String?) ?? '',
      achievable: (map['achievable'] as String?) ?? '',
      relevant: (map['relevant'] as String?) ?? '',
      timeBound: _parseDateTime(map['timeBound']),
      categoryId: (map['categoryId'] as String?) ?? '',
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
      'createdAt': createdAt.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'status': status.value,
      'milestones': milestones.map((milestone) => milestone.toMap()).toList(),
      'specific': specific,
      'measurable': measurable,
      'achievable': achievable,
      'relevant': relevant,
      'timeBound': timeBound?.toIso8601String(),
      'categoryId': categoryId,
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
      final milestones = <Milestone>[];
      var index = 0;
      for (final item in value) {
        if (item is Map) {
          milestones.add(
            Milestone.fromMap(
              Map<String, dynamic>.from(item),
              fallbackOrder: index,
            ),
          );
          index += 1;
        }
      }
      milestones.sort((a, b) => a.order.compareTo(b.order));
      return List<Milestone>.unmodifiable(milestones);
    }
    return const [];
  }
}
