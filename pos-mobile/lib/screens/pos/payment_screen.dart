// halo
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class PaymentScreen extends StatefulWidget {
  final double subtotal;
  final double discount;
  final void Function(String method, double pay, double discount,
      String customerName, String orderNote) onPay;

  const PaymentScreen({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.onPay,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'cash';
  double _payAmount = 0;
  final _payCtrl = TextEditingController();
  final _customerNameCtrl = TextEditingController();
  final _orderNoteCtrl = TextEditingController();

  double get _total =>
      (widget.subtotal - widget.discount).clamp(0, double.infinity);
  double get _change => (_payAmount - _total).clamp(0, double.infinity);
  bool get _isValid => _method != 'cash' || _payAmount >= _total;

  static const List<Map<String, dynamic>> _methods = [
    {'key': 'cash', 'label': 'Cash', 'icon': Icons.payments_outlined},
    {'key': 'qris', 'label': 'QRIS', 'icon': Icons.qr_code_scanner_rounded},
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
    _customerNameCtrl.dispose();
    _orderNoteCtrl.dispose();
    super.dispose();
  }

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
            const Icon(Icons.payment_rounded,
                color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('Pembayaran',
                style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: _methods.map((m) {
                        final isSelected = _method == m['key'];
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (m['key'] == 'qris') {
                                final user = context.read<AuthProvider>().currentUser;
                                final qrisBaseString = user?.qrisBaseString;
                                if (qrisBaseString == null || qrisBaseString.isEmpty) {
                                  ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                                    const SnackBar(
                                      content: Text('QRIS belum diatur. Silakan tambahkan QRIS di Pengaturan terlebih dahulu.'),
                                      backgroundColor: AppTheme.danger,
                                    ),
                                  );
                                  return;
                                }
                              }
                              setState(() => _method = m['key'] as String);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                                      size: 20),
                                  const SizedBox(height: 6),
                                  Text(m['label'] as String,
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
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
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        TextField(
                          controller: _customerNameCtrl,
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Nama Pelanggan (Opsional)',
                            labelStyle: GoogleFonts.inter(
                                fontSize: 13, color: AppTheme.textMuted),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _orderNoteCtrl,
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Keterangan Pesanan (Opsional)',
                            labelStyle: GoogleFonts.inter(
                                fontSize: 13, color: AppTheme.textMuted),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary)),
                        Text(formatRupiah(_total),
                            style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary)),
                      ],
                    ),
                  ),
                  if (_method == 'cash') ...[
                    const SizedBox(height: 16),
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
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              TextButton(
                                onPressed: _setExact,
                                child: Text('Uang Pas',
                                    style: GoogleFonts.inter(
                                        color: AppTheme.accent,
                                        fontSize: 13,
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
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (v) => setState(
                                () => _payAmount = double.tryParse(v) ?? 0),
                          ),
                          if (_payAmount > 0 && _isValid) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
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
                                          fontSize: 14)),
                                  Text(formatRupiah(_change),
                                      style: GoogleFonts.inter(
                                          color: AppTheme.success,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isValid
                      ? () => widget.onPay(
                          _method,
                          _method == 'cash' ? _payAmount : _total,
                          widget.discount,
                          _customerNameCtrl.text.trim(),
                          _orderNoteCtrl.text.trim())
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
          ),
        ],
      ),
    );
  }
}
