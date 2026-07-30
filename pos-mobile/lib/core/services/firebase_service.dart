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
      
      final sevenDaysAgo = now.subtract(const Duration(days: 6));
      final sevenDaysAgoStr = "${sevenDaysAgo.year}-${sevenDaysAgo.month.toString().padLeft(2, '0')}-${sevenDaysAgo.day.toString().padLeft(2, '0')}";

      final txSnapshot = await _db
          .collection('transactions')
          .where('created_at', isGreaterThanOrEqualTo: sevenDaysAgoStr)
          .get();

      double todayRevenue = 0;
      int todaySales = 0;
      int productsSold = 0;
      
      Map<String, double> revenueByDate = {};
      Map<String, int> qtyByProduct = {};

      for (var doc in txSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['created_at'] as String;
        final dateOnly = createdAt.split('T')[0];
        
        final grandTotal = double.tryParse(data['grand_total'].toString()) ?? 0;
        
        // Populate chart data
        revenueByDate[dateOnly] = (revenueByDate[dateOnly] ?? 0) + grandTotal;

        if (dateOnly == todayStr) {
          todaySales++;
          todayRevenue += grandTotal;
          final items = data['items'] as List?;
          if (items != null) {
            for (var item in items) {
              productsSold += (item['quantity'] as int? ?? 1);
            }
          }
        }
        
        // Top products calculation
        final items = data['items'] as List?;
        if (items != null) {
          for (var item in items) {
            final pName = item['product_name'] as String? ?? 'Unknown';
            final qty = item['quantity'] as int? ?? 1;
            qtyByProduct[pName] = (qtyByProduct[pName] ?? 0) + qty;
          }
        }
      }

      final prodSnapshot = await _db.collection('products').get();
      int totalProducts = prodSnapshot.docs.length;

      // Format chart_days
      List<Map<String, dynamic>> chartDays = [];
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final dStr = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        chartDays.add({
          'date': '${d.day}/${d.month}',
          'revenue': revenueByDate[dStr] ?? 0.0,
        });
      }
      
      // Format top products
      var sortedProducts = qtyByProduct.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
        
      List<Map<String, dynamic>> topProducts = sortedProducts.take(5).map((e) => {
        'product_name': e.key,
        'total_qty': e.value,
      }).toList();

      // Recent transactions
      final recentTrxQuery = await _db
          .collection('transactions')
          .orderBy('created_at', descending: true)
          .limit(5)
          .get();
      
      List<Map<String, dynamic>> recentTransactions = recentTrxQuery.docs.map((d) {
         final data = d.data();
         // format date slightly if needed, or return as is
         return {
            'invoice_number': data['invoice_number'],
            'created_at': data['created_at'],
            'grand_total': data['grand_total'],
            'payment_method': data['payment_method'],
         };
      }).toList();

      return {
        'kpi': {
          'today_sales': todaySales,
          'today_revenue': todayRevenue,
          'today_profit': todayRevenue * 0.3, // Mock profit 30%
          'items_sold_today': productsSold,
          'total_products': totalProducts,
        },
        'chart_days': chartDays,
        'top_products': topProducts,
        'recent_transactions': recentTransactions,
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {
        'kpi': {
          'today_sales': 0, 'today_revenue': 0, 'today_profit': 0, 'items_sold_today': 0, 'total_products': 0
        },
        'chart_days': [],
        'top_products': [],
        'recent_transactions': [],
      };
    }
  }
}
