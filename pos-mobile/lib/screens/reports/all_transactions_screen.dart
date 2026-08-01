import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction.dart' as tr;
import '../pos/widgets/receipt_dialog.dart';

class AllTransactionsScreen extends StatelessWidget {
  final String timeline;

  const AllTransactionsScreen({super.key, required this.timeline});

  @override
  Widget build(BuildContext context) {
    final fb = FirebaseService(context.read<AuthProvider>().currentUser!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Transaksi'),
        elevation: 0,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: fb.streamDashboardStats(isDashboard: false, timeline: timeline),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Gagal memuat data', style: GoogleFonts.inter()));
          }

          final data = snapshot.data!;
          final recentTrx = data['recent_transactions'] as List;

          if (recentTrx.isEmpty) {
            return Center(
              child: Text('Belum ada transaksi', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
            );
          }

          List<Widget> trxListWidgets = [];
          String? currentMonthStr;
          
          for (var trx in recentTrx) {
            final t = trx as tr.Transaction;
            String dateStr = t.createdAt;
            String monthHeader = '';
            try {
              final dt = DateTime.parse(t.createdAt);
              dateStr = DateFormat('dd/MM/yyyy HH:mm').format(dt);
              monthHeader = DateFormat('MMMM yyyy').format(dt);
            } catch (_) {}

            if (monthHeader.isNotEmpty && monthHeader != currentMonthStr) {
              trxListWidgets.add(
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    monthHeader.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted),
                  ),
                ),
              );
              currentMonthStr = monthHeader;
            }

            trxListWidgets.add(
              InkWell(
                onTap: () {
                  final user = context.read<AuthProvider>().currentUser;
                  showDialog(
                    context: context,
                    builder: (_) => ReceiptDialog(
                      transaction: t,
                      storeName: 'KASIR DIGITAL',
                      location: '${user?.cityId} - ${user?.provinceId}'.toUpperCase(),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long_outlined,
                            color: AppTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.invoiceNumber,
                                style: GoogleFonts.inter(
                                    fontSize: 13, fontWeight: FontWeight.w700,
                                    color: AppTheme.primary)),
                            Text('${t.cashierName ?? "Kasir"} • $dateStr',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatRupiah(t.grandTotal),
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(t.paymentMethod,
                                style: GoogleFonts.inter(
                                    fontSize: 10, fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: trxListWidgets,
          );
        },
      ),
    );
  }
}
