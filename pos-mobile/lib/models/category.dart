class Category {
  final int id;
  final String name;
  final int? productsCount;

  Category({required this.id, required this.name, this.productsCount});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as int,
        name: json['name'] as String,
        productsCount: json['products_count'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
