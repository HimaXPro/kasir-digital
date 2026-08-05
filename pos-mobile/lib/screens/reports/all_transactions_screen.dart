import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../../core/providers/auth_provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction.dart' as tr;
import '../pos/widgets/receipt_dialog.dart';

class AllTransactionsScreen extends StatefulWidget {
  final String timeline;
  final bool canVoid;

  const AllTransactionsScreen({super.key, required this.timeline, this.canVoid = false});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  late String _selectedTimeline;
  int _currentPage = 0;
  final int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _selectedTimeline = widget.timeline;
  }

  @override
  Widget build(BuildContext context) {
    final fb = FirebaseService(context.read<AuthProvider>().currentUser!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Transaksi'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: _selectedTimeline,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
              underline: const SizedBox(),
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Harian')),
                DropdownMenuItem(value: 'weekly', child: Text('Mingguan')),
                DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
                DropdownMenuItem(value: 'yearly', child: Text('Tahunan')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedTimeline = val;
                    _currentPage = 0; // Reset page when timeline changes
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: fb.streamDashboardStats(isDashboard: false, timeline: _selectedTimeline),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Gagal memuat data', style: GoogleFonts.inter()));
          }

          final data = snapshot.data!;
          final allTrx = data['recent_transactions'] as List;

          if (allTrx.isEmpty) {
            return Center(
              child: Text('Belum ada transaksi', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
            );
          }

          // Calculate Pagination
          final int totalPages = (allTrx.length / _itemsPerPage).ceil();
          final int startIndex = _currentPage * _itemsPerPage;
          final int endIndex = min(startIndex + _itemsPerPage, allTrx.length);
          final paginatedTrx = allTrx.sublist(startIndex, endIndex);

          List<Widget> trxListWidgets = [];
          String? currentMonthStr;
          
          for (var trx in paginatedTrx) {
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
                      canVoid: widget.canVoid,
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
                          color: t.status == 'voided' ? AppTheme.danger.withAlpha(25) : AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                            t.status == 'voided' ? Icons.block : Icons.receipt_long_outlined,
                            color: t.status == 'voided' ? AppTheme.danger : AppTheme.primary, size: 18),
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
                            if (t.status == 'voided')
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.danger.withAlpha(25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('DIBATALKAN', 
                                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.danger)),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatRupiah(t.grandTotal),
                              style: GoogleFonts.inter(
                                  fontSize: 13, 
                                  fontWeight: FontWeight.w700,
                                  decoration: t.status == 'voided' ? TextDecoration.lineThrough : null,
                                  color: t.status == 'voided' ? AppTheme.textMuted : AppTheme.textPrimary)),
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

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: trxListWidgets,
                ),
              ),
              // Pagination Controls
              if (totalPages > 1)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        label: Text('Sebelumnya', style: GoogleFonts.inter(fontSize: 13)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          disabledForegroundColor: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        'Hal ${_currentPage + 1} dari $totalPages',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: _currentPage < totalPages - 1
                            ? () => setState(() => _currentPage++)
                            : null,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          disabledForegroundColor: AppTheme.textMuted,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Selanjutnya', style: GoogleFonts.inter(fontSize: 13)),
                            const Icon(Icons.chevron_right_rounded, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
