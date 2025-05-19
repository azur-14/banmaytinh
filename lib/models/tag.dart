class Tag {
  final String id;
  final String name;
  final String? description;

  Tag({
    required this.id,
    required this.name,
    this.description,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}
