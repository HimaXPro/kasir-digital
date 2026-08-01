class Category {
  final String id;
  final String name;
  final int sortOrder;

  Category({required this.id, required this.name, this.sortOrder = 0});

  factory Category.fromFirestore(Map<String, dynamic> json, String docId) => Category(
        id: docId,
        name: json['name'] as String? ?? '',
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'sortOrder': sortOrder,
      };
}
