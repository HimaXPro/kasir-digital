class CartItem {
  final String productId;
  final String productName;
  final double price;
  final double costPrice;
  int quantity;
  String? note;
  String? imageUrl;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    this.costPrice = 0,
    this.quantity = 1,
    this.note,
    this.imageUrl,
  });

  double get subtotal => price * quantity;
  double get totalCost => costPrice * quantity;

  Map<String, dynamic> toFirestore() => {
        'product_id': productId,
        'product_name': productName,
        'price': price,
        'cost_price': costPrice,
        'quantity': quantity,
        'note': note,
        if (imageUrl != null) 'image_url': imageUrl,
      };

  factory CartItem.fromFirestore(Map<String, dynamic> json) => CartItem(
        productId: json['product_id'] as String,
        productName: json['product_name'] as String,
        price: double.tryParse(json['price'].toString()) ?? 0,
        costPrice: double.tryParse(json['cost_price']?.toString() ?? '0') ?? 0,
        quantity: json['quantity'] as int? ?? 1,
        note: json['note'] as String?,
        imageUrl: json['image_url'] as String?,
      );
}

class Transaction {
  final String id;
  final String invoiceNumber;
  final String paymentMethod;
  final double grandTotal;
  final double changeAmount;
  final String createdAt;
  final List<CartItem>? items;
  final String? customerName;
  final String? orderNote;

  Transaction({
    required this.id,
    required this.invoiceNumber,
    required this.paymentMethod,
    required this.grandTotal,
    required this.changeAmount,
    required this.createdAt,
    this.items,
    this.customerName,
    this.orderNote,
  });

  factory Transaction.fromFirestore(Map<String, dynamic> json, String docId) {
    List<CartItem> itemsList = [];
    if (json['items'] != null) {
      itemsList = (json['items'] as List)
          .map((item) => CartItem.fromFirestore(item as Map<String, dynamic>))
          .toList();
    }
    
    return Transaction(
      id: docId,
      invoiceNumber: json['invoice_number'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? '',
      grandTotal: double.tryParse(json['grand_total'].toString()) ?? 0,
      changeAmount: double.tryParse(json['change_amount'].toString()) ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      items: itemsList,
      customerName: json['customer_name'] as String?,
      orderNote: json['order_note'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'invoice_number': invoiceNumber,
        'payment_method': paymentMethod,
        'grand_total': grandTotal,
        'change_amount': changeAmount,
        'created_at': createdAt,
        'items': items?.map((item) => item.toFirestore()).toList() ?? [],
        if (customerName != null) 'customer_name': customerName,
        if (orderNote != null) 'order_note': orderNote,
      };
}
