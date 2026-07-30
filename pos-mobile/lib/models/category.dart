class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromFirestore(Map<String, dynamic> json, String docId) => Category(
        id: docId,
        name: json['name'] as String? ?? '',
      );

  Map<String, dynamic> toFirestore() => {
        'name': name,
      };
}
