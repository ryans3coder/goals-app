class Milestone {
  const Milestone({
    required this.id,
    required this.goalId,
    required this.text,
    required this.order,
    required this.isCompleted,
    this.completedAt,
  });

  final String id;
  final String goalId;
  final String text;
  final int order;
  final bool isCompleted;
  final DateTime? completedAt;

  factory Milestone.fromMap(
    Map<String, dynamic> map, {
    int? fallbackOrder,
  }) {
    return Milestone(
      id: (map['id'] as String?) ?? '',
      goalId: (map['goalId'] as String?) ?? '',
      text: (map['text'] as String?) ?? (map['title'] as String?) ?? '',
      order: (map['order'] as int?) ?? fallbackOrder ?? 0,
      isCompleted: (map['isCompleted'] as bool?) ?? false,
      completedAt: _parseDateTime(map['completedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'text': text,
      'order': order,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
