class Subcategory {
  final String id;
  final String name;
  final String categoryId;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Subcategory({
    required this.id,
    required this.name,
    required this.categoryId,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'],
      name: json['name'],
      categoryId: json['category_id'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Subcategory(id: $id, name: $name, categoryId: $categoryId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subcategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
