import 'category.dart';

class Product {
  final int id;
  final int? categoryId;
  final String name;
  final String sku;
  final double costPrice;
  final double sellingPrice;
  final int stock;
  final Category? category;

  Product({
    required this.id,
    this.categoryId,
    required this.name,
    required this.sku,
    required this.costPrice,
    required this.sellingPrice,
    required this.stock,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        categoryId: json['category_id'] as int?,
        name: json['name'] as String,
        sku: json['sku'] as String,
        costPrice: (json['cost_price'] as num).toDouble(),
        sellingPrice: (json['selling_price'] as num).toDouble(),
        stock: (json['stock'] as num).toInt(),
        category: json['category'] != null
            ? Category.fromJson(json['category'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'category_id': categoryId,
        'name': name,
        'sku': sku,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'stock': stock,
      };

  Product copyWith({
    int? id,
    int? categoryId,
    String? name,
    String? sku,
    double? costPrice,
    double? sellingPrice,
    int? stock,
    Category? category,
  }) =>
      Product(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        name: name ?? this.name,
        sku: sku ?? this.sku,
        costPrice: costPrice ?? this.costPrice,
        sellingPrice: sellingPrice ?? this.sellingPrice,
        stock: stock ?? this.stock,
        category: category ?? this.category,
      );
}
