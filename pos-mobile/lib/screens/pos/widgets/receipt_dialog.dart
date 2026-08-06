import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/print_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/transaction.dart' as tr;
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/firebase_service.dart';

class ReceiptDialog extends StatefulWidget {
  final tr.Transaction transaction;
  final String storeName;
  final String location;
  final bool canVoid;

  const ReceiptDialog({
    super.key,
    required this.transaction,
    required this.storeName,
    required this.location,
    this.canVoid = false,
  });

  @override
  State<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<ReceiptDialog> {
  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Receipt Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (t.status == 'voided')
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'TRANSAKSI DIBATALKAN',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.danger,
                          ),
                        ),
                      ),
                    // Header
                    Text(
                      widget.storeName.toUpperCase(),
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.location,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _dashLine(),
                    const SizedBox(height: 16),
                    
                    // Meta
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('No:', style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                        Text(t.invoiceNumber, style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tgl:', style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                        Text(_formatDate(t.createdAt), style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pembayaran:', style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                        Text(t.paymentMethod, style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kasir:', style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                        Text(t.cashierName ?? 'Kasir', style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                      ],
                    ),
                    if (t.customerName != null && t.customerName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pelanggan:', style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                          Text(t.customerName!, style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                        ],
                      ),
                    ],
                    if (t.orderNote != null && t.orderNote!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Catatan:', style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.orderNote!, 
                              style: GoogleFonts.ibmPlexMono(fontSize: 12),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    _dashLine(),
                    const SizedBox(height: 16),
                    
                    // Items
                    ...(t.items ?? []).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            if (item.note != null && item.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '* ${item.note}',
                                  style: GoogleFonts.ibmPlexMono(fontSize: 10, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.quantity} x ${formatRupiah(item.price)}',
                                    style: GoogleFonts.ibmPlexMono(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formatRupiah(item.subtotal),
                                  style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 4),
                    _dashLine(),
                    const SizedBox(height: 16),
                    
                    // Totals
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TOTAL:', style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w700)),
                        Text(formatRupiah(t.grandTotal), style: GoogleFonts.ibmPlexMono(fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('BAYAR:', style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                        Text(formatRupiah(t.grandTotal + t.changeAmount), style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('KEMBALI:', style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                        Text(formatRupiah(t.changeAmount), style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    Text(
                      'TERIMA KASIH',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: Colors.grey.withAlpha(30))),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Tutup', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            try {
                              final trxData = {
                                'invoice_number': t.invoiceNumber,
                                'created_at': _formatDate(t.createdAt),
                                'payment_method': t.paymentMethod,
                                'customer_name': t.customerName,
                                'cashier_name': t.cashierName,
                                'order_note': t.orderNote,
                                'subtotal': t.items?.fold<num>(0, (sum, i) => sum + i.subtotal).toInt() ?? 0,
                                'discount': 0,
                                'grand_total': t.grandTotal.toInt(),
                                'pay_amount': (t.grandTotal + t.changeAmount).toInt(),
                                'items': t.items?.map((e) => {
                                  'name': e.productName,
                                  'quantity': e.quantity,
                                  'price': e.price.toInt(),
                                  'note': e.note,
                                }).toList() ?? [],
                              };
                              
                              await PrintService().printReceipt(trxData);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                                const SnackBar(content: Text('Nota sedang dicetak...'), backgroundColor: AppTheme.success),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
                                SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.print_rounded, size: 16, color: Colors.white),
                          label: Text('Cetak', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  if (widget.canVoid && t.status != 'voided') ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _handleVoid(context),
                        icon: const Icon(Icons.block, size: 16),
                        label: Text('Batalkan Transaksi', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.danger,
                          side: const BorderSide(color: AppTheme.danger),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleVoid(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Batalkan Transaksi?', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.danger)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pendapatan akan dikurangi dan stok barang akan dikembalikan. Proses ini tidak dapat dibatalkan.', 
                style: GoogleFonts.inter(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Alasan Pembatalan (Wajib)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kembali'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Alasan pembatalan harus diisi'), backgroundColor: AppTheme.danger),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Batalkan Transaksi'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final user = context.read<AuthProvider>().currentUser;
        if (user != null) {
          final fb = FirebaseService(user);
          await fb.voidTransaction(widget.transaction, reasonCtrl.text.trim());
          if (!context.mounted) return;
          Navigator.pop(context); // Close receipt dialog
          ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil dibatalkan'), backgroundColor: AppTheme.success),
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(content: Text('Gagal: ${e.toString()}'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Widget _dashLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey)),
            );
          }),
        );
      },
    );
  }

  String _formatDate(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr);
      return DateFormat('dd/MM/yy HH:mm').format(dt);
    } catch (_) {
      return isoStr;
    }
  }
}
