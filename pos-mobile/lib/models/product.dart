import 'category.dart';

class Product {
  final String id;
  final String? categoryId;
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

  factory Product.fromFirestore(Map<String, dynamic> json, String docId, {Category? category}) => Product(
        id: docId,
        categoryId: json['category_id'] as String?,
        name: json['name'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        costPrice: double.tryParse(json['cost_price'].toString()) ?? 0,
        sellingPrice: double.tryParse(json['selling_price'].toString()) ?? 0,
        stock: int.tryParse(json['stock'].toString()) ?? 0,
        category: category,
      );

  Map<String, dynamic> toFirestore() => {
        'category_id': categoryId,
        'name': name,
        'sku': sku,
        'cost_price': costPrice,
        'selling_price': sellingPrice,
        'stock': stock,
      };

  Product copyWith({
    String? id,
    String? categoryId,
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
