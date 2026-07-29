import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/transaction.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _api = ApiService();
  List<Product> _products = [];
  List<Category> _categories = [];
  List<CartItem> _cart = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  int? _selectedCatId;
  final _searchCtrl = TextEditingController();

  static const _emojis = ['🍜','🥤','☕','🍕','🍱','🧃','🍗','🥗','🍰','🍔','🥐','🍩'];
  static const _colors = [
    Color(0xFFEEF2FF), Color(0xFFECFEFF), Color(0xFFECFDF5),
    Color(0xFFFFFBEB), Color(0xFFFEF2F2), Color(0xFFF5F3FF),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.get('/products', queryParams: {'all': 'true'}),
        _api.get('/categories'),
      ]);
      setState(() {
        _products = (results[0]['data'] as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
        _categories = (results[1]['data'] as List)
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Product> get _filtered {
    return _products.where((p) {
      final matchSearch = _search.isEmpty ||
          p.name.toLowerCase().contains(_search.toLowerCase()) ||
          p.sku.toLowerCase().contains(_search.toLowerCase());
      final matchCat = _selectedCatId == null || p.categoryId == _selectedCatId;
      return matchSearch && matchCat;
    }).toList();
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
        _cart.add(CartItem(
          productId: product.id,
          productName: product.name,
          price: product.sellingPrice,
        ));
      }
    });
  }

  void _removeFromCart(int productId) {
    setState(() => _cart.removeWhere((c) => c.productId == productId));
  }

  void _updateQty(int productId, int qty) {
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CartBottomSheet(
        cart: List.from(_cart),
        subtotal: _subtotal,
        onRemove: _removeFromCart,
        onUpdateQty: _updateQty,
        onCheckout: _openPayment,
      ),
    );
  }

  void _openPayment(double discount) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentBottomSheet(
        subtotal: _subtotal,
        discount: discount,
        onPay: _processPayment,
      ),
    );
  }

  Future<void> _processPayment(
      String method, double payAmount, double discount) async {
    Navigator.pop(context);
    try {
      final items = _cart
          .map((c) => {'product_id': c.productId, 'quantity': c.quantity})
          .toList();

      final result = await _api.post('/transactions', {
        'items': items,
        'discount_amount': discount,
        'pay_amount': payAmount,
        'payment_method': method,
      });

      final trxData = result['data'] as Map<String, dynamic>;
      final invoiceNo = trxData['invoice_number'] as String;
      final change = double.tryParse(trxData['change_amount'].toString()) ?? 0;

      setState(() => _cart = []);
      _loadData();

      if (!mounted) return;
      _showSuccessDialog(invoiceNo, change);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
      );
    }
  }

  void _showSuccessDialog(String invoice, double change) {
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
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Transaksi Baru'),
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
      appBar: AppBar(
        title: const Text('🛒 Kasir POS'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 48, color: AppTheme.textMuted),
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    _buildSearchAndFilter(),
                    Expanded(child: _buildProductGrid()),
                  ],
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

  Widget _buildSearchAndFilter() {
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
                ..._categories.map((c) => _catChip(c.id, c.name)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _catChip(int? catId, String label) {
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

  Widget _buildProductGrid() {
    final filtered = _filtered;
    if (filtered.isEmpty) {
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
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => _buildProductCard(filtered[i]),
    );
  }

  Widget _buildProductCard(Product product) {
    final emojiIdx = product.id % _emojis.length;
    final colorIdx = product.id % _colors.length;
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
                  Container(
                    height: 56,
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

// ── Cart Bottom Sheet ──────────────────────────────────────────────────────
class _CartBottomSheet extends StatefulWidget {
  final List<CartItem> cart;
  final double subtotal;
  final void Function(int) onRemove;
  final void Function(int, int) onUpdateQty;
  final void Function(double) onCheckout;

  const _CartBottomSheet({
    required this.cart,
    required this.subtotal,
    required this.onRemove,
    required this.onUpdateQty,
    required this.onCheckout,
  });

  @override
  State<_CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<_CartBottomSheet> {
  double _discount = 0;
  final _discCtrl = TextEditingController(text: '0');

  double get _total =>
      (widget.subtotal - _discount).clamp(0, double.infinity);

  @override
  void dispose() {
    _discCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_rounded,
                    color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Keranjang',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.cart.length} item',
                    style: GoogleFonts.inter(
                        color: AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.35,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.cart.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 20, endIndent: 20),
              itemBuilder: (ctx, i) {
                final item = widget.cart[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName,
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                            Text(formatRupiah(item.price),
                                style: GoogleFonts.inter(
                                    color: AppTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _qtyBtn(Icons.remove, () {
                            widget.onUpdateQty(
                                item.productId, item.quantity - 1);
                            setState(() {});
                          }),
                          Container(
                            width: 36,
                            alignment: Alignment.center,
                            child: Text('${item.quantity}',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                          ),
                          _qtyBtn(Icons.add, () {
                            widget.onUpdateQty(
                                item.productId, item.quantity + 1);
                            setState(() {});
                          }),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              widget.onRemove(item.productId);
                              setState(() {});
                              if (widget.cart.isEmpty) {
                                Navigator.pop(ctx);
                              }
                            },
                            child: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppTheme.danger,
                                size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal',
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    Text(formatRupiah(widget.subtotal),
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Diskon (Rp)',
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    const Spacer(),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _discCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                        ),
                        onChanged: (v) => setState(
                            () => _discount = double.tryParse(v) ?? 0),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                    Text(formatRupiah(_total),
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onCheckout(_discount),
                    icon: const Icon(Icons.payment_rounded, size: 18),
                    label: Text('Bayar ${formatRupiah(_total)}',
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.bodyBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: Icon(icon, size: 14, color: AppTheme.textPrimary),
        ),
      );
}

// ── Payment Bottom Sheet ───────────────────────────────────────────────────
class _PaymentBottomSheet extends StatefulWidget {
  final double subtotal;
  final double discount;
  final void Function(String method, double pay, double discount) onPay;

  const _PaymentBottomSheet({
    required this.subtotal,
    required this.discount,
    required this.onPay,
  });

  @override
  State<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<_PaymentBottomSheet> {
  String _method = 'cash';
  double _payAmount = 0;
  final _payCtrl = TextEditingController();

  double get _total =>
      (widget.subtotal - widget.discount).clamp(0, double.infinity);
  double get _change => (_payAmount - _total).clamp(0, double.infinity);
  bool get _isValid => _payAmount >= _total;

  static const List<Map<String, dynamic>> _methods = [
    {'key': 'cash', 'label': 'Cash', 'icon': Icons.payments_outlined},
    {'key': 'qris', 'label': 'QRIS', 'icon': Icons.qr_code_scanner_rounded},
    {'key': 'transfer', 'label': 'Transfer', 'icon': Icons.account_balance_outlined},
    {'key': 'debit', 'label': 'Debit', 'icon': Icons.credit_card_outlined},
  ];

  void _setExact() {
    setState(() {
      _payAmount = _total;
      _payCtrl.text = _total.toStringAsFixed(0);
    });
  }

  @override
  void dispose() {
    _payCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.payment_rounded,
                      color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Pembayaran',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _methods.map((m) {
                  final isSelected = _method == m['key'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _method = m['key'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 6),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryLight
                              : AppTheme.bodyBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(m['icon'] as IconData,
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.textMuted,
                                size: 18),
                            const SizedBox(height: 3),
                            Text(m['label'] as String,
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bodyBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary)),
                  Text(formatRupiah(_total),
                      style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary)),
                ],
              ),
            ),
            if (_method == 'cash') ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Jumlah Bayar',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        TextButton(
                          onPressed: _setExact,
                          child: Text('Uang Pas',
                              style: GoogleFonts.inter(
                                  color: AppTheme.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _payCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        prefixStyle: GoogleFonts.inter(
                            fontSize: 16, color: AppTheme.textSecondary),
                      ),
                      onChanged: (v) => setState(
                          () => _payAmount = double.tryParse(v) ?? 0),
                    ),
                    if (_payAmount > 0 && _isValid) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.successLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Kembalian',
                                style: GoogleFonts.inter(
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(formatRupiah(_change),
                                style: GoogleFonts.inter(
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (_method != 'cash' || _isValid) &&
                          _method.isNotEmpty
                      ? () => widget.onPay(
                          _method,
                          _method == 'cash' ? _payAmount : _total,
                          widget.discount)
                      : null,
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text('Proses Pembayaran',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
