import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/image_helper.dart';
import '../../core/services/print_service.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/transaction.dart' as tr;

import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/payment_service.dart';
import 'widgets/receipt_dialog.dart';
import 'widgets/qris_dialog.dart';
import 'cart_screen.dart';
import 'payment_screen.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  FirebaseService get _fb => FirebaseService(context.read<AuthProvider>().currentUser!);
  List<tr.CartItem> _cart = [];
  String _search = '';
  String? _selectedCatId;
  final _searchCtrl = TextEditingController();

  static const _emojis = ['🍜','🥤','☕','🍕','🍱','🧃','🍗','🥗','🍰','🍔','🥐','🍩'];
  static const _colors = [
    Color(0xFFEEF2FF), Color(0xFFECFEFF), Color(0xFFECFDF5),
    Color(0xFFFFFBEB), Color(0xFFFEF2F2), Color(0xFFF5F3FF),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    if (product.stock <= 0) return;
    HapticFeedback.lightImpact();
    setState(() {
      final idx = _cart.indexWhere((c) => c.productId == product.id);
      if (idx >= 0) {
        if (_cart[idx].quantity < product.stock) {
          _cart[idx].quantity++;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stok ${product.name} hanya ${product.stock} unit'),
            ),
          );
        }
      } else {
        _cart.add(tr.CartItem(
          productId: product.id,
          productName: product.name,
          price: product.sellingPrice,
          costPrice: product.costPrice,
          imageUrl: product.imageUrl,
        ));
      }
    });
  }

  void _removeFromCart(String productId) {
    setState(() => _cart.removeWhere((c) => c.productId == productId));
  }

  void _updateQty(String productId, int qty) {
    setState(() {
      final idx = _cart.indexWhere((c) => c.productId == productId);
      if (idx >= 0) {
        if (qty <= 0) {
          _cart.removeAt(idx);
        } else {
          _cart[idx].quantity = qty;
        }
      }
    });
  }

  double get _subtotal => _cart.fold(0, (sum, c) => sum + c.subtotal);
  int get _cartCount => _cart.fold(0, (sum, c) => sum + c.quantity);

  void _openCart() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang masih kosong')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          cart: _cart,
          onRemove: _removeFromCart,
          onUpdateQty: _updateQty,
          onUpdateItemNote: (id, note) {
            final idx = _cart.indexWhere((c) => c.productId == id);
            if (idx >= 0) _cart[idx].note = note;
          },
          onCheckout: _openPayment,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _openPayment(double discount) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          subtotal: _subtotal,
          discount: discount,
          onPay: _processPayment,
        ),
      ),
    );
  }

  Future<void> _processPayment(
      String method, double payAmount, double discount, String customerName, String orderNote) async {
    Navigator.popUntil(context, (route) => route.isFirst);
    try {
      final now = DateTime.now();
      final invoice = 'INV-${now.millisecondsSinceEpoch}';
      
      final changeAmount = (payAmount - (_subtotal - discount)).clamp(0, double.infinity).toDouble();

      final transaction = tr.Transaction(
        id: '',
        invoiceNumber: invoice,
        paymentMethod: method,
        grandTotal: _subtotal - discount,
        changeAmount: changeAmount,
        createdAt: now.toIso8601String(),
        items: List.from(_cart),
        customerName: customerName.isNotEmpty ? customerName : null,
        orderNote: orderNote.isNotEmpty ? orderNote : null,
      );

      final addedTrx = await _fb.addTransaction(transaction);
      
      final trxData = transaction.toFirestore();
      trxData['id'] = addedTrx.id;
      
      if (method == 'qris') {
        if (!mounted) return;
        // Tampilkan loading dialog atau ubah state
        final paymentService = PaymentService();
        final qrisResult = await paymentService.generateQris(
          transactionId: addedTrx.id,
          amount: _subtotal - discount,
          items: _cart.map((e) => {
            'product_name': e.productName,
            'quantity': e.quantity,
            'price': e.price,
          }).toList(),
        );

        if (qrisResult['success'] == true) {
          if (!mounted) return;
          final bool? isPaid = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => QrisDialog(
              transactionId: addedTrx.id,
              qrString: qrisResult['qrString'],
              amount: _subtotal - discount,
              fbService: _fb,
            ),
          );

          if (isPaid != true) {
            // Jika dibatalkan atau gagal, jangan lanjutkan cetak
            return;
          }
        } else {
          throw Exception('Gagal mendapatkan QR Code dari server');
        }
      }

      setState(() => _cart = []);

      if (!mounted) return;
      _showSuccessDialog(transaction, trxData);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
      );
    }
  }

  void _showSuccessDialog(tr.Transaction transaction, Map<String, dynamic> trxData) {
    final invoice = trxData['invoice_number'] as String;
    final change = double.tryParse(trxData['change_amount'].toString()) ?? 0;
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 40),
              ),
              const SizedBox(height: 16),
              Text('Transaksi Berhasil!',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(invoice,
                  style: GoogleFonts.inter(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.bodyBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kembalian',
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    Text(formatRupiah(change),
                        style: GoogleFonts.inter(
                            color: AppTheme.success,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final user = context.read<AuthProvider>().currentUser;
                    showDialog(
                      context: context,
                      builder: (_) => ReceiptDialog(
                        transaction: transaction,
                        storeName: 'KASIR DIGITAL', // Can be fetched from settings if we had them
                        location: '${user?.cityId} - ${user?.provinceId}'.toUpperCase(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('Lihat Nota (Struk)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Transaksi Baru'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('🛒 Kasir POS'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      body: StreamBuilder<List<Category>>(
        stream: _fb.streamCategories(),
        builder: (context, catSnapshot) {
          final categories = catSnapshot.data ?? [];
          return StreamBuilder<List<Product>>(
            stream: _fb.streamProducts(),
            builder: (context, prodSnapshot) {
              if (prodSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
              }

              var products = prodSnapshot.data ?? [];

              // Local Filtering
              if (_search.isNotEmpty) {
                products = products
                    .where((p) => p.name.toLowerCase().contains(_search.toLowerCase()) || 
                                  p.sku.toLowerCase().contains(_search.toLowerCase()))
                    .toList();
              }
              if (_selectedCatId != null) {
                products = products.where((p) => p.categoryId == _selectedCatId).toList();
              }

              return Column(
                children: [
                  _buildSearchAndFilter(categories),
                  Expanded(child: _buildProductGrid(products)),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: _cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCart,
              backgroundColor: AppTheme.primary,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart_rounded, color: Colors.white),
                  if (_cartCount > 0)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppTheme.danger,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_cartCount',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
              label: Text(
                formatRupiah(_subtotal),
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ),
    );
  }

  Widget _buildSearchAndFilter(List<Category> categories) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Cari nama produk atau SKU…',
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 18, color: AppTheme.textMuted),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _catChip(null, 'Semua'),
                ...categories.map((c) => _catChip(c.id, c.name)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _catChip(String? catId, String label) {
    final isSelected = _selectedCatId == catId;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCatId = catId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.border),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text('Produk tidak ditemukan',
                style: GoogleFonts.inter(
                    color: AppTheme.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: products.length,
      itemBuilder: (ctx, i) => _buildProductCard(products[i]),
    );
  }

  Widget _buildProductCard(Product product) {
    final emojiIdx = product.name.length % _emojis.length;
    final colorIdx = product.name.length % _colors.length;
    final cartItems = _cart.where((c) => c.productId == product.id);
    final inCart = cartItems.isNotEmpty;
    final cartQty = inCart ? cartItems.first.quantity : 0;
    final isOutOfStock = product.stock <= 0;

    return GestureDetector(
      onTap: () => _addToCart(product),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: inCart ? AppTheme.primary : AppTheme.border,
            width: inCart ? 2 : 1,
          ),
          boxShadow: const [AppTheme.shadowSm],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                    Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: getImageProvider(product.imageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _colors[colorIdx],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(_emojis[emojiIdx],
                            style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatRupiah(product.sellingPrice),
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: product.stock > 10
                              ? AppTheme.success
                              : product.stock > 0
                                  ? AppTheme.warning
                                  : AppTheme.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOutOfStock ? 'Habis' : 'Stok: ${product.stock}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: product.stock > 10
                              ? AppTheme.success
                              : product.stock > 0
                                  ? AppTheme.warning
                                  : AppTheme.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isOutOfStock)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(160),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('HABIS',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ),
            if (inCart && !isOutOfStock)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('$cartQty',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

