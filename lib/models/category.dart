class Category {
  const Category({
    required this.id,
    required this.userId,
    required this.title,
    this.colorHex = '',
    this.icon = '',
  });

  final String id;
  final String userId;
  final String title;
  final String colorHex;
  final String icon;

  factory Category.fromMap(Map<String, dynamic> map, {String? id}) {
    return Category(
      id: (map['id'] as String?) ?? id ?? '',
      userId: (map['userId'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      colorHex: (map['colorHex'] as String?) ?? '',
      icon: (map['icon'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'colorHex': colorHex,
      'icon': icon,
    };
  }
}
