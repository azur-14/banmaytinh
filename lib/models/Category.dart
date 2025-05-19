class Category {
  final String? id;
  final String name;
  final String? description;
  final DateTime createdAt;

  Category({
    this.id,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String?,
    name: json['name'] as String,
    description: json['description'] as String?,
    createdAt: DateTime.parse(json['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
  };
}
