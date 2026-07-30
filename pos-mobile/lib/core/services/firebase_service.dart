import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/app_user.dart';
import '../../models/transaction.dart' as tr;
import '../../models/stock_movement.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AppUser user;

  FirebaseService(this.user);

  CollectionReference<Map<String, dynamic>> _cityRef(String collectionName) {
    return _db
        .collection('provinces')
        .doc(user.provinceId)
        .collection('cities')
        .doc(user.cityId)
        .collection(collectionName);
  }

  // === CATEGORIES ===
  Stream<List<Category>> streamCategories() {
    return _cityRef('categories').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => Category.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<void> addCategory(Category category) async {
    await _cityRef('categories').add(category.toFirestore());
  }

  Future<void> updateCategory(Category category) async {
    await _cityRef('categories')
        .doc(category.id)
        .update(category.toFirestore());
  }

  Future<void> deleteCategory(String id) async {
    await _cityRef('categories').doc(id).delete();
  }

  // === PRODUCTS ===
  Stream<List<Product>> streamProducts() {
    return _cityRef('products').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromFirestore(doc.data(), doc.id)).toList());
  }

  Future<void> addProduct(Product product) async {
    final ref = await _cityRef('products').add(product.toFirestore());
    if (product.stock > 0) {
      final movement = StockMovement(
        id: '',
        productId: ref.id,
        productName: product.name,
        type: 'IN',
        quantity: product.stock,
        note: 'Stok awal',
        createdAt: DateTime.now().toIso8601String(),
      );
      await _cityRef('stock_movements').add(movement.toFirestore());
    }
  }

  Future<void> updateProduct(Product product) async {
    final ref = _cityRef('products').doc(product.id);
    final snapshot = await ref.get();
    
    if (snapshot.exists) {
      final oldStock = snapshot.data()?['stock'] ?? 0;
      final diff = product.stock - (oldStock as num).toInt();
      
      if (diff != 0) {
        final movement = StockMovement(
          id: '',
          productId: product.id,
          productName: product.name,
          type: diff > 0 ? 'IN' : 'ADJ',
          quantity: diff.abs(),
          note: diff > 0 ? 'Penambahan stok manual' : 'Penyesuaian stok manual',
          createdAt: DateTime.now().toIso8601String(),
        );
        await _cityRef('stock_movements').add(movement.toFirestore());
      }
    }
    await ref.update(product.toFirestore());
  }

  Future<void> deleteProduct(String id) async {
    await _cityRef('products').doc(id).delete();
  }

  // === TRANSACTIONS ===
  Stream<tr.Transaction?> streamTransaction(String id) {
    return _cityRef('transactions')
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? tr.Transaction.fromFirestore(doc.data()!, doc.id) : null);
  }

  Stream<List<tr.Transaction>> streamTransactions() {
    return _cityRef('transactions')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => tr.Transaction.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<DocumentReference> addTransaction(tr.Transaction transaction) async {
    final docRef = await _cityRef('transactions').add(transaction.toFirestore());
    
    // Decrease stock for each item
    for (var item in transaction.items ?? []) {
      final productRef = _cityRef('products').doc(item.productId);
      _db.runTransaction((tx) async {
        final snapshot = await tx.get(productRef);
        if (!snapshot.exists) return;
        final currentStock = snapshot.data()?['stock'] ?? 0;
        tx.update(productRef, {'stock': currentStock - item.quantity});
      });

      final movement = StockMovement(
        id: '',
        productId: item.productId,
        productName: item.productName,
        type: 'OUT',
        quantity: item.quantity,
        note: 'Penjualan #${transaction.invoiceNumber}',
        createdAt: DateTime.now().toIso8601String(),
      );
      await _cityRef('stock_movements').add(movement.toFirestore());
    }
    return docRef;
  }

  // === STOCK MOVEMENTS ===
  Stream<List<StockMovement>> streamStockMovements() {
    return _cityRef('stock_movements')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StockMovement.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // === DASHBOARD STATS ===
  Future<Map<String, dynamic>> getDashboardStats({
    bool isDashboard = true,
    String timeline = 'monthly', // daily, weekly, monthly, yearly
  }) async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      DateTime chartStartDate;
      
      // Determine Start Dates
      if (isDashboard) {
        // Dashboard KPI & Products & History: Today
        startDate = DateTime(now.year, now.month, now.day);
        // Dashboard Chart: Last 6 months (Monthly)
        chartStartDate = DateTime(now.year, now.month - 5, 1);
        timeline = 'monthly'; // Force chart grouping to monthly
      } else {
        // Reports: follows timeline
        switch (timeline) {
          case 'daily':
            startDate = DateTime(now.year, now.month, now.day);
            chartStartDate = now.subtract(const Duration(days: 6)); // 7 days chart
            break;
          case 'weekly':
            startDate = now.subtract(const Duration(days: 7));
            chartStartDate = now.subtract(const Duration(days: 27)); // 4 weeks chart
            break;
          case 'monthly':
            startDate = now.subtract(const Duration(days: 30));
            chartStartDate = DateTime(now.year, now.month - 5, 1); // 6 months chart
            break;
          case 'yearly':
            startDate = now.subtract(const Duration(days: 365));
            chartStartDate = DateTime(now.year - 4, 1, 1); // 5 years chart
            break;
          default:
            startDate = DateTime(now.year, now.month, now.day);
            chartStartDate = now.subtract(const Duration(days: 6));
        }
      }

      final earliestDate = startDate.isBefore(chartStartDate) ? startDate : chartStartDate;
      final startStr = earliestDate.toIso8601String();

      final txSnapshot = await _cityRef('transactions')
          .where('created_at', isGreaterThanOrEqualTo: startStr)
          .get();

      double totalRevenue = 0;
      double totalProfit = 0;
      int totalSales = 0;
      int productsSold = 0;
      
      Map<String, double> revenueGroup = {};
      Map<String, int> qtyByProduct = {};
      List<tr.Transaction> recentTransactions = [];

      for (var doc in txSnapshot.docs) {
        final data = doc.data();
        final createdAt = data['created_at'] as String;
        final txDate = DateTime.parse(createdAt);
        final grandTotal = double.tryParse(data['grand_total'].toString()) ?? 0;
        
        // 1. Chart Data Grouping
        if (!txDate.isBefore(chartStartDate)) {
          String groupKey;
          if (timeline == 'daily') {
            groupKey = "${txDate.year}-${txDate.month.toString().padLeft(2, '0')}-${txDate.day.toString().padLeft(2, '0')}";
          } else if (timeline == 'weekly') {
            groupKey = "W${((txDate.day - 1) / 7).floor() + 1} ${txDate.month}";
          } else if (timeline == 'monthly') {
            groupKey = "${txDate.year}-${txDate.month.toString().padLeft(2, '0')}";
          } else { // yearly
            groupKey = "${txDate.year}";
          }
          revenueGroup[groupKey] = (revenueGroup[groupKey] ?? 0) + grandTotal;
        }

        // 2. KPI & Top Products & Recent Transactions Data
        if (!txDate.isBefore(startDate)) {
          totalSales++;
          totalRevenue += grandTotal;
          recentTransactions.add(tr.Transaction.fromFirestore(data, doc.id));
          
          final items = data['items'] as List?;
          if (items != null) {
            for (var item in items) {
              final qty = item['quantity'] as int? ?? 1;
              final sell = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
              final cost = double.tryParse(item['cost_price']?.toString() ?? '0') ?? 0;
              
              productsSold += qty;
              totalProfit += (sell - cost) * qty;
              
              final pName = item['product_name'] as String? ?? 'Unknown';
              qtyByProduct[pName] = (qtyByProduct[pName] ?? 0) + qty;
            }
          }
        }
      }

      // Format chart_days based on timeline
      List<Map<String, dynamic>> chartDays = [];
      if (timeline == 'daily') {
        for (int i = 6; i >= 0; i--) {
          final d = now.subtract(Duration(days: i));
          final key = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
          chartDays.add({'date': '${d.day}/${d.month}', 'revenue': revenueGroup[key] ?? 0.0});
        }
      } else if (timeline == 'weekly') {
        for (int i = 3; i >= 0; i--) {
          final d = now.subtract(Duration(days: i * 7));
          final key = "W${((d.day - 1) / 7).floor() + 1} ${d.month}";
          chartDays.add({'date': 'Mgg ${(3-i)+1}', 'revenue': revenueGroup[key] ?? 0.0});
        }
      } else if (timeline == 'monthly') {
        for (int i = 5; i >= 0; i--) {
          int m = now.month - i;
          int y = now.year;
          if (m <= 0) { m += 12; y -= 1; }
          final key = "$y-${m.toString().padLeft(2, '0')}";
          const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
          chartDays.add({'date': months[m-1], 'revenue': revenueGroup[key] ?? 0.0});
        }
      } else if (timeline == 'yearly') {
        for (int i = 4; i >= 0; i--) {
          final y = now.year - i;
          final key = "$y";
          chartDays.add({'date': key, 'revenue': revenueGroup[key] ?? 0.0});
        }
      }

      // Sort recent transactions
      recentTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (isDashboard) {
         recentTransactions = recentTransactions.take(5).toList();
      }

      // Top products
      var sortedProducts = qtyByProduct.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      List<Map<String, dynamic>> topProducts = sortedProducts.take(5).map((e) => {
        'product_name': e.key,
        'total_qty': e.value,
      }).toList();

      final prodSnapshot = await _cityRef('products').get();
      int totalProducts = prodSnapshot.docs.length;

      return {
        'kpi': {
          'today_sales': totalSales,
          'today_revenue': totalRevenue,
          'today_profit': totalProfit,
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
