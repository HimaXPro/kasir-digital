class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final String type; // 'IN', 'OUT', 'ADJ'
  final int quantity; // Absolute quantity that moved
  final String note;
  final String createdAt;

  StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.note,
    required this.createdAt,
  });

  factory StockMovement.fromFirestore(Map<String, dynamic> json, String docId) {
    return StockMovement(
      id: docId,
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      type: json['type'] as String? ?? 'OUT',
      quantity: json['quantity'] as int? ?? 0,
      note: json['note'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'product_id': productId,
      'product_name': productName,
      'type': type,
      'quantity': quantity,
      'note': note,
      'created_at': createdAt,
    };
  }
}
