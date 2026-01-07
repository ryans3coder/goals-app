class Routine {
  Routine({
    required this.id,
    required this.userId,
    required this.title,
    required this.icon,
    required this.triggerTime,
    required List<String> steps,
    this.categoryId = '',
  }) : steps = List.unmodifiable(steps);

  final String id;
  final String userId;
  final String title;
  final String icon;
  final String triggerTime;
  final List<String> steps;
  final String categoryId;

  factory Routine.fromMap(Map<String, dynamic> map, {String? id}) {
    return Routine(
      id: (map['id'] as String?) ?? id ?? '',
      userId: (map['userId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      icon: (map['icon'] as String?) ?? '',
      triggerTime: (map['triggerTime'] as String?) ?? '',
      steps: _parseSteps(map['steps']),
      categoryId: (map['categoryId'] as String?) ?? '',
    );
  }

  factory Routine.fromJson(Map<String, dynamic> json, {String? id}) {
    return Routine.fromMap(json, id: id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'icon': icon,
      'triggerTime': triggerTime,
      'steps': steps,
      'categoryId': categoryId,
    };
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  static List<String> _parseSteps(dynamic value) {
    if (value is List) {
      return List<String>.unmodifiable(
        value.map((item) => item.toString()),
      );
    }
    return const [];
  }
}
