import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/print_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/transaction.dart' as tr;

class ReceiptDialog extends StatelessWidget {
  final tr.Transaction transaction;
  final String storeName;
  final String location;

  const ReceiptDialog({
    super.key,
    required this.transaction,
    required this.storeName,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
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
                    // Header
                    Text(
                      storeName.toUpperCase(),
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
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
                        Text(transaction.invoiceNumber, style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tgl:', style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                        Text(_formatDate(transaction.createdAt), style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pembayaran:', style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                        Text(transaction.paymentMethod, style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                      ],
                    ),
                    if (transaction.customerName != null && transaction.customerName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pelanggan:', style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                          Text(transaction.customerName!, style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                        ],
                      ),
                    ],
                    if (transaction.orderNote != null && transaction.orderNote!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Catatan:', style: GoogleFonts.ibmPlexMono(fontSize: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              transaction.orderNote!, 
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
                    ...(transaction.items ?? []).map((item) {
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${item.quantity} x ${formatRupiah(item.price)}',
                                  style: GoogleFonts.ibmPlexMono(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                Text(
                                  formatRupiah(item.subtotal),
                                  style: GoogleFonts.ibmPlexMono(fontSize: 12, fontWeight: FontWeight.w600),
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
                        Text('TOTAL', style: GoogleFonts.ibmPlexMono(fontSize: 14, fontWeight: FontWeight.w700)),
                        Text(formatRupiah(transaction.grandTotal), style: GoogleFonts.ibmPlexMono(fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TUNAI', style: GoogleFonts.ibmPlexMono(fontSize: 12, color: AppTheme.textSecondary)),
                        Text(formatRupiah(transaction.grandTotal + transaction.changeAmount), style: GoogleFonts.ibmPlexMono(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('KEMBALI', style: GoogleFonts.ibmPlexMono(fontSize: 12, color: AppTheme.textSecondary)),
                        Text(formatRupiah(transaction.changeAmount), style: GoogleFonts.ibmPlexMono(fontSize: 12, color: AppTheme.textSecondary)),
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
              child: Row(
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
                            'invoice_number': transaction.invoiceNumber,
                            'created_at': _formatDate(transaction.createdAt),
                            'payment_method': transaction.paymentMethod,
                            'customer_name': transaction.customerName,
                            'order_note': transaction.orderNote,
                            'subtotal': transaction.items?.fold<num>(0, (sum, i) => sum + i.subtotal).toInt() ?? 0,
                            'discount': 0,
                            'grand_total': transaction.grandTotal.toInt(),
                            'pay_amount': (transaction.grandTotal + transaction.changeAmount).toInt(),
                            'items': transaction.items?.map((e) => {
                              'name': e.productName,
                              'quantity': e.quantity,
                              'price': e.price.toInt(),
                              'note': e.note,
                            }).toList() ?? [],
                          };
                          
                          await PrintService().printReceipt(trxData);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nota sedang dicetak...'), backgroundColor: AppTheme.success),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
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
            ),
          ],
        ),
      ),
    );
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
