class CartItem {
  final int productId;
  final String productName;
  final double price;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    this.quantity = 1,
  });

  double get subtotal => price * quantity;
}

class Transaction {
  final int id;
  final String invoiceNumber;
  final String paymentMethod;
  final double grandTotal;
  final double changeAmount;
  final String createdAt;

  Transaction({
    required this.id,
    required this.invoiceNumber,
    required this.paymentMethod,
    required this.grandTotal,
    required this.changeAmount,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as int,
        invoiceNumber: json['invoice_number'] as String,
        paymentMethod: json['payment_method'] as String,
        grandTotal: double.tryParse(json['grand_total'].toString()) ?? 0,
        changeAmount: double.tryParse(json['change_amount'].toString()) ?? 0,
        createdAt: json['created_at'] as String,
      );
}
