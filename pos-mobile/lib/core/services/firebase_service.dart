import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/transaction.dart' as tr;

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // === CATEGORIES ===
  Stream<List<Category>> streamCategories() {
    return _db.collection('categories').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => Category.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<void> addCategory(Category category) async {
    await _db.collection('categories').add(category.toFirestore());
  }

  Future<void> updateCategory(Category category) async {
    await _db
        .collection('categories')
        .doc(category.id)
        .update(category.toFirestore());
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection('categories').doc(id).delete();
  }

  // === PRODUCTS ===
  Stream<List<Product>> streamProducts() {
    return _db.collection('products').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromFirestore(doc.data(), doc.id)).toList());
  }

  Future<void> addProduct(Product product) async {
    await _db.collection('products').add(product.toFirestore());
  }

  Future<void> updateProduct(Product product) async {
    await _db
        .collection('products')
        .doc(product.id)
        .update(product.toFirestore());
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  // === TRANSACTIONS ===
  Stream<List<tr.Transaction>> streamTransactions() {
    return _db
        .collection('transactions')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => tr.Transaction.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> addTransaction(tr.Transaction transaction) async {
    await _db.collection('transactions').add(transaction.toFirestore());
    
    // Decrease stock for each item
    for (var item in transaction.items ?? []) {
      final productRef = _db.collection('products').doc(item.productId);
      _db.runTransaction((tx) async {
        final snapshot = await tx.get(productRef);
        if (!snapshot.exists) return;
        final currentStock = snapshot.data()?['stock'] ?? 0;
        tx.update(productRef, {'stock': currentStock - item.quantity});
      });
    }
  }

  // === DASHBOARD STATS ===
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      final txSnapshot = await _db
          .collection('transactions')
          .where('created_at', isGreaterThanOrEqualTo: todayStr)
          .get();

      double todayRevenue = 0;
      int todaySales = txSnapshot.docs.length;
      int productsSold = 0;

      for (var doc in txSnapshot.docs) {
        final data = doc.data();
        todayRevenue += (double.tryParse(data['grand_total'].toString()) ?? 0);
        final items = data['items'] as List?;
        if (items != null) {
          for (var item in items) {
            productsSold += (item['quantity'] as int? ?? 1);
          }
        }
      }

      final prodSnapshot = await _db.collection('products').get();
      int totalProducts = prodSnapshot.docs.length;

      return {
        'today_sales': todaySales,
        'today_revenue': todayRevenue,
        'products_sold': productsSold,
        'total_products': totalProducts,
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {
        'today_sales': 0,
        'today_revenue': 0,
        'products_sold': 0,
        'total_products': 0,
      };
    }
  }
}
