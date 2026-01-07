class Milestone {
  const Milestone({
    required this.title,
    required this.isCompleted,
  });

  final String title;
  final bool isCompleted;

  factory Milestone.fromMap(Map<String, dynamic> map) {
    return Milestone(
      title: (map['title'] as String?) ?? '',
      isCompleted: (map['isCompleted'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isCompleted': isCompleted,
    };
  }
}
