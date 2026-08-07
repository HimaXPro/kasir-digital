import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/app_user.dart';
import '../../models/transaction.dart' as tr;
import '../../models/stock_movement.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AppUser user;

  FirebaseService(this.user);

  CollectionReference<Map<String, dynamic>> _storeRef(String collectionName) {
    return _db
        .collection('stores')
        .doc(user.storeId)
        .collection(collectionName);
  }

  Future<String> uploadImage(File imageFile, String folder) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance
        .ref()
        .child('stores/${user.storeId}/$folder/$fileName');
    
    final uploadTask = ref.putFile(imageFile);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  // === QRIS CONFIG ===
  Future<void> saveQrisBaseString(String qrisString) async {
    await _db.collection('users').doc(user.uid).update({
      'qris_base_string': qrisString,
    });
  }

  // === CATEGORIES ===
  Stream<List<Category>> streamCategories() {
    return _storeRef('categories').snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Category.fromFirestore(doc.data(), doc.id))
          .toList();
      // Sort locally so that categories without sortOrder (default 0) are still returned
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  Future<void> addCategory(Category category) async {
    final snapshot = await _storeRef('categories').orderBy('sortOrder', descending: true).limit(1).get();
    int nextOrder = 0;
    if (snapshot.docs.isNotEmpty) {
      final lastCategory = Category.fromFirestore(snapshot.docs.first.data(), snapshot.docs.first.id);
      nextOrder = lastCategory.sortOrder + 1;
    }
    final newCategory = Category(id: '', name: category.name, sortOrder: nextOrder);
    await _storeRef('categories').add(newCategory.toFirestore());
  }

  Future<void> updateCategory(Category category) async {
    await _storeRef('categories')
        .doc(category.id)
        .update(category.toFirestore());
  }

  Future<void> deleteCategory(String id) async {
    await _storeRef('categories').doc(id).delete();
  }

  Future<void> reorderCategories(List<Category> categories) async {
    final batch = _db.batch();
    for (int i = 0; i < categories.length; i++) {
      final ref = _storeRef('categories').doc(categories[i].id);
      batch.update(ref, {'sortOrder': i});
    }
    await batch.commit();
  }

  // === PRODUCTS ===
  Stream<List<Product>> streamProducts() {
    return _storeRef('products').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromFirestore(doc.data(), doc.id)).toList());
  }

  Future<void> addProduct(Product product) async {
    final ref = await _storeRef('products').add(product.toFirestore());
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
      final movementData = movement.toFirestore();
      movementData['expires_at'] = Timestamp.fromDate(DateTime.now().add(const Duration(days: 365)));
      await _storeRef('stock_movements').add(movementData);
    }
  }

  Future<void> updateProduct(Product product) async {
    final ref = _storeRef('products').doc(product.id);
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
        final movementData = movement.toFirestore();
        movementData['expires_at'] = Timestamp.fromDate(DateTime.now().add(const Duration(days: 365)));
        await _storeRef('stock_movements').add(movementData);
      }
    }
    await ref.update(product.toFirestore());
  }

  Future<void> deleteProduct(String id) async {
    await _storeRef('products').doc(id).delete();
  }

  // === TRANSACTIONS ===
  Stream<tr.Transaction?> streamTransaction(String id) {
    return _storeRef('transactions')
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? tr.Transaction.fromFirestore(doc.data()!, doc.id) : null);
  }

  Stream<List<tr.Transaction>> streamTransactions() {
    return _storeRef('transactions')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => tr.Transaction.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<DocumentReference> addTransaction(tr.Transaction transaction) async {
    final txData = transaction.toFirestore();
    txData['expires_at'] = Timestamp.fromDate(DateTime.now().add(const Duration(days: 365)));
    
    // Gunakan .doc() lalu .set() tanpa await agar bisa langsung selesai (offline mode)
    final docRef = _storeRef('transactions').doc();
    docRef.set(txData); // Tidak di-await
    
    // Decrease stock for each item using FieldValue.increment to support offline mode
    for (var item in transaction.items ?? []) {
      final productRef = _storeRef('products').doc(item.productId);
      productRef.update({'stock': FieldValue.increment(-item.quantity)});

      final movement = StockMovement(
        id: '',
        productId: item.productId,
        productName: item.productName,
        type: 'OUT',
        quantity: item.quantity,
        note: 'Terjual (Kasir: ${transaction.cashierName})',
        createdAt: DateTime.now().toIso8601String(),
      );
      final movData = movement.toFirestore();
      movData['expires_at'] = Timestamp.fromDate(DateTime.now().add(const Duration(days: 365)));
      
      _storeRef('stock_movements').doc().set(movData); // Tidak di-await
    }
    
    return docRef;
  }

  Future<void> voidTransaction(tr.Transaction transaction, String reason) async {
    // 1. Update Transaction Status
    final txRef = _storeRef('transactions').doc(transaction.id);
    await txRef.update({
      'status': 'voided',
      'void_reason': reason,
      'voided_at': DateTime.now().toIso8601String(),
    });

    // 2. Return Stock
    for (var item in transaction.items ?? []) {
      final productRef = _storeRef('products').doc(item.productId);
      productRef.update({'stock': FieldValue.increment(item.quantity)});

      // 3. Log Stock Movement IN
      final movement = StockMovement(
        id: '',
        productId: item.productId,
        productName: item.productName,
        type: 'IN',
        quantity: item.quantity,
        note: 'Pembatalan Transaksi (Void)',
        createdAt: DateTime.now().toIso8601String(),
      );
      final movData = movement.toFirestore();
      movData['expires_at'] = Timestamp.fromDate(DateTime.now().add(const Duration(days: 365)));
      
      _storeRef('stock_movements').doc().set(movData);
    }
  }

  Stream<List<StockMovement>> streamStockMovements({String timeline = 'monthly'}) {
    final now = DateTime.now();
    DateTime startDate;
    switch (timeline) {
      case 'daily':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'weekly':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'monthly':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'yearly':
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }
    
    return _storeRef('stock_movements')
        .where('created_at', isGreaterThanOrEqualTo: startDate.toIso8601String())
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

      final txSnapshot = await _storeRef('transactions')
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
        final status = data['status'] as String? ?? 'completed';
        final createdAt = data['created_at'] as String;
        final txDate = DateTime.parse(createdAt);
        final grandTotal = double.tryParse(data['grand_total'].toString()) ?? 0;
        
        // Add to recentTransactions regardless of status
        if (!txDate.isBefore(startDate)) {
          recentTransactions.add(tr.Transaction.fromFirestore(data, doc.id));
        }

        // If voided, skip KPI calculations
        if (status == 'voided') continue;

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

        // 2. KPI & Top Products Data
        if (!txDate.isBefore(startDate)) {
          totalSales++;
          totalRevenue += grandTotal;
          
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

      final prodSnapshot = await _storeRef('products').get();
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

  Stream<Map<String, dynamic>> streamDashboardStats({
    bool isDashboard = true,
    String timeline = 'monthly',
  }) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime chartStartDate;
    
    if (isDashboard) {
      startDate = DateTime(now.year, now.month, now.day);
      chartStartDate = DateTime(now.year, now.month - 5, 1);
      timeline = 'monthly';
    } else {
      switch (timeline) {
        case 'daily':
          startDate = DateTime(now.year, now.month, now.day);
          chartStartDate = now.subtract(const Duration(days: 6));
          break;
        case 'weekly':
          startDate = now.subtract(const Duration(days: 7));
          chartStartDate = now.subtract(const Duration(days: 27));
          break;
        case 'monthly':
          startDate = now.subtract(const Duration(days: 30));
          chartStartDate = DateTime(now.year, now.month - 5, 1);
          break;
        case 'yearly':
          startDate = now.subtract(const Duration(days: 365));
          chartStartDate = DateTime(now.year - 4, 1, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
          chartStartDate = now.subtract(const Duration(days: 6));
      }
    }

    final earliestDate = startDate.isBefore(chartStartDate) ? startDate : chartStartDate;
    final startStr = earliestDate.toIso8601String();

    return _storeRef('transactions')
        .where('created_at', isGreaterThanOrEqualTo: startStr)
        .snapshots()
        .asyncMap((txSnapshot) async {
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
            final status = data['status'] as String? ?? 'completed';
            
            if (!txDate.isBefore(chartStartDate)) {
              String groupKey;
              if (timeline == 'daily') {
                groupKey = "${txDate.year}-${txDate.month.toString().padLeft(2, '0')}-${txDate.day.toString().padLeft(2, '0')}";
              } else if (timeline == 'weekly') {
                groupKey = "W${((txDate.day - 1) / 7).floor() + 1} ${txDate.month}";
              } else if (timeline == 'monthly') {
                groupKey = "${txDate.year}-${txDate.month.toString().padLeft(2, '0')}";
              } else {
                groupKey = "${txDate.year}";
              }
              if (status != 'voided') {
                revenueGroup[groupKey] = (revenueGroup[groupKey] ?? 0) + grandTotal;
              }
            }

            if (!txDate.isBefore(startDate)) {
              recentTransactions.add(tr.Transaction.fromFirestore(data, doc.id));
              
              if (status != 'voided') {
                totalSales++;
                totalRevenue += grandTotal;
                
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
          }

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

          recentTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (isDashboard) {
             recentTransactions = recentTransactions.take(5).toList();
          }

          var sortedProducts = qtyByProduct.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          List<Map<String, dynamic>> topProducts = sortedProducts.take(5).map((e) => {
            'product_name': e.key,
            'total_qty': e.value,
          }).toList();

          final prodSnapshot = await _storeRef('products').get();
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
        });
  }
}
