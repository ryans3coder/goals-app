class HabitCategory {
  HabitCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorToken,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String emoji;
  final String colorToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory HabitCategory.fromMap(Map<String, dynamic> map, {String? id}) {
    return HabitCategory(
      id: (map['id'] as String?) ?? id ?? '',
      name: (map['name'] as String?) ??
          (map['title'] as String?) ??
          '',
      emoji: (map['emoji'] as String?) ??
          (map['icon'] as String?) ??
          '',
      colorToken: (map['colorToken'] as String?) ??
          (map['colorHex'] as String?) ??
          '',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'colorToken': colorToken,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
