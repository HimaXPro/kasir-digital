import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/image_helper.dart';
import '../../models/transaction.dart' as tr;

class CartScreen extends StatefulWidget {
  final List<tr.CartItem> cart;
  final void Function(String) onRemove;
  final void Function(String, int) onUpdateQty;
  final void Function(String, String) onUpdateItemNote;
  final void Function(double) onCheckout;
  final VoidCallback onClearCart;

  const CartScreen({
    super.key,
    required this.cart,
    required this.onRemove,
    required this.onUpdateQty,
    required this.onUpdateItemNote,
    required this.onCheckout,
    required this.onClearCart,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double _discount = 0;
  final _discCtrl = TextEditingController(text: '0');

  double get _currentSubtotal =>
      widget.cart.fold(0, (sum, c) => sum + c.subtotal);

  double get _total =>
      (_currentSubtotal - _discount).clamp(0, double.infinity);

  void _showQuantityDialog(tr.CartItem item) {
    final ctrl = TextEditingController(text: item.quantity.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Atur Jumlah: ${item.productName}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Masukkan jumlah',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(ctrl.text) ?? 0;
              widget.onUpdateQty(item.productId, val);
              setState(() {});
              Navigator.pop(ctx);
              if (widget.cart.isEmpty) {
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _discCtrl.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Row(
          children: [
            const Icon(Icons.shopping_cart_rounded,
                color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('Keranjang Belanja',
                style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.cart.length} item',
                style: GoogleFonts.inter(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
            if (widget.cart.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: AppTheme.danger),
                tooltip: 'Hapus Semua',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Hapus Keranjang', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      content: const Text('Anda yakin ingin menghapus semua produk di keranjang?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                          onPressed: () {
                            Navigator.pop(ctx);
                            widget.onClearCart();
                            Navigator.pop(context);
                          },
                          child: const Text('Hapus Semua', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: widget.cart.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 20, endIndent: 20),
              itemBuilder: (ctx, i) {
                final item = widget.cart[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image(
                            image: getImageProvider(item.imageUrl!), 
                            width: 50, 
                            height: 50, 
                            fit: BoxFit.cover
                          ),
                        ),
                        const SizedBox(width: 12),
                      ] else ...[
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.textMuted),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName,
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                            Text(formatRupiah(item.price),
                                style: GoogleFonts.inter(
                                    color: AppTheme.textMuted, fontSize: 13)),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: item.note,
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Tambah catatan (opsional)...',
                                hintStyle: GoogleFonts.inter(
                                    fontSize: 12, color: AppTheme.textMuted),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: AppTheme.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: AppTheme.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: AppTheme.primary),
                                ),
                              ),
                              onChanged: (val) =>
                                  widget.onUpdateItemNote(item.productId, val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          _qtyBtn(Icons.remove, () {
                            widget.onUpdateQty(
                                item.productId, item.quantity - 1);
                            setState(() {});
                          }),
                          GestureDetector(
                            onTap: () => _showQuantityDialog(item),
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${item.quantity}',
                                  style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                          _qtyBtn(Icons.add, () {
                            widget.onUpdateQty(
                                item.productId, item.quantity + 1);
                            setState(() {});
                          }),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              widget.onRemove(item.productId);
                              setState(() {});
                              if (widget.cart.isEmpty) {
                                Navigator.pop(context);
                              }
                            },
                            child: const Icon(Icons.delete_outline_rounded,
                                color: AppTheme.danger, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal',
                          style: GoogleFonts.inter(
                              color: AppTheme.textSecondary, fontSize: 14)),
                      Text(formatRupiah(_currentSubtotal),
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Diskon (Rp)',
                          style: GoogleFonts.inter(
                              color: AppTheme.textSecondary, fontSize: 14)),
                      const Spacer(),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _discCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppTheme.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: AppTheme.border),
                            ),
                          ),
                          onChanged: (v) => setState(
                              () => _discount = double.tryParse(v) ?? 0),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary)),
                      Text(formatRupiah(_total),
                          style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: widget.cart.isEmpty ? null : () => widget.onCheckout(_discount),
                      icon: const Icon(Icons.payment_rounded, size: 20),
                      label: Text('Lanjut Pembayaran',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
