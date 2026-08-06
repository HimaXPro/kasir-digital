import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/stock_movement.dart';
import '../../models/transaction.dart' as tr;
import '../pos/widgets/receipt_dialog.dart';
import 'all_transactions_screen.dart';
import 'all_stock_movements_screen.dart';

import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  FirebaseService get _fb => FirebaseService(context.read<AuthProvider>().currentUser!);
  String _timeline = 'daily'; // daily, weekly, monthly, yearly
  late Stream<Map<String, dynamic>> _reportsStream;

  String _getTimelineTitle() {
    switch (_timeline) {
      case 'daily': return 'Harian';
      case 'weekly': return 'Mingguan';
      case 'monthly': return 'Bulanan';
      case 'yearly': return 'Tahunan';
      default: return 'Harian';
    }
  }

  @override
  void initState() {
    super.initState();
    _updateStream();
  }

  void _updateStream() {
    final fb = FirebaseService(context.read<AuthProvider>().currentUser!);
    _reportsStream = fb.streamDashboardStats(
      isDashboard: false,
      timeline: _timeline,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Pilih Rentang Waktu',
            onSelected: (val) {
              setState(() {
                _timeline = val;
                _updateStream();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'daily', child: Text('Harian (Hari Ini)')),
              const PopupMenuItem(value: 'weekly', child: Text('Mingguan (7 Hari)')),
              const PopupMenuItem(value: 'monthly', child: Text('Bulanan (30 Hari)')),
              const PopupMenuItem(value: 'yearly', child: Text('Tahunan (365 Hari)')),
            ],
          ),
          // Refresh button removed since it's real-time now
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primary,
              tabs: [
                Tab(text: 'Transaksi'),
                Tab(text: 'Pergerakan Stok'),
              ],
            ),
            Expanded(
              child: StreamBuilder<Map<String, dynamic>>(
                stream: _reportsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                  }
                  if (snapshot.hasError) {
                    return _buildError(snapshot.error.toString());
                  }
                  
                  final data = snapshot.data;
                  if (data == null) {
                    return _buildError('Data kosong');
                  }
                  
                  return TabBarView(
                    children: [
                      _buildContent(data),
                      _buildStockMovementsTab(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockMovementsTab() {
    return StreamBuilder<List<StockMovement>>(
      stream: _fb.streamStockMovements(timeline: _timeline),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        final movements = snapshot.data ?? [];
        if (movements.isEmpty) {
          return Center(
            child: Text('Belum ada riwayat pergerakan stok',
                style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          );
        }

        final displayMovements = movements.take(9).toList();
        List<Widget> listWidgets = [];

        for (int i = 0; i < displayMovements.length; i++) {
          final m = displayMovements[i];
          final isOut = m.type == 'OUT';
          final color = isOut ? AppTheme.danger : AppTheme.success;
          final icon = isOut ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
          final sign = isOut ? '-' : '+';
          
          String dateStr = m.createdAt;
          String monthHeader = '';
          try {
            final dt = DateTime.parse(m.createdAt);
            dateStr = DateFormat('dd MMM yyyy, HH:mm').format(dt);
            monthHeader = DateFormat('MMMM yyyy').format(dt);
          } catch (_) {}

          bool showHeader = false;
          if (i == 0) {
            showHeader = true;
          } else {
            try {
              final prevDt = DateTime.parse(displayMovements[i-1].createdAt);
              final prevMonthHeader = DateFormat('MMMM yyyy').format(prevDt);
              if (monthHeader != prevMonthHeader) showHeader = true;
            } catch (_) {}
          }

          final movementCard = Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
              boxShadow: const [AppTheme.shadowSm],
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.productName,
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(m.note,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(dateStr,
                          style: GoogleFonts.inter(
                              fontSize: 10, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Text('$sign${m.quantity}',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          );

          if (showHeader && monthHeader.isNotEmpty) {
            listWidgets.add(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (i > 0) const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 4),
                  child: Text(
                    monthHeader.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMuted),
                  ),
                ),
                movementCard,
                if (i < displayMovements.length - 1) const SizedBox(height: 8),
              ],
            ));
          } else {
            listWidgets.add(Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: movementCard,
            ));
          }
        }

        if (movements.length > 9) {
          listWidgets.add(
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AllStockMovementsScreen(timeline: _timeline),
                    ));
                  },
                  child: Text('Lihat Semua (${movements.length})', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: listWidgets,
        );
      },
    );
  }

  Widget _buildError(String errorMsg) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text('Gagal memuat laporan',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(errorMsg,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );

  Widget _buildContent(Map<String, dynamic> data) {
    final kpi = data['kpi'] as Map<String, dynamic>;
    final chartDays = data['chart_days'] as List;
    final topProducts = data['top_products'] as List;
    final recentTrx = data['recent_transactions'] as List;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Today Summary
        Text('📈 Laporan Transaksi ${_getTimelineTitle()}',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _buildSummaryGrid(kpi),
        const SizedBox(height: 16),

        // Revenue Chart
        _buildCard(
          title: '📊 Omzet ${_getTimelineTitle()}',
          child: SizedBox(
            height: 180,
            child: _buildBarChart(chartDays),
          ),
        ),
        const SizedBox(height: 12),

        // Top Products
        if (topProducts.isNotEmpty) ...[
          _buildCard(
            title: '🏆 Produk Terlaris',
            child: Column(
              children: topProducts.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value as Map<String, dynamic>;
                final color = AppTheme.chartPalette[i % AppTheme.chartPalette.length];
                final maxQty = (topProducts.first as Map)['total_qty'] as int;
                final qty = p['total_qty'] as int;
                final ratio = maxQty > 0 ? qty / maxQty : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: color.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text('${i + 1}',
                                  style: GoogleFonts.inter(
                                      color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(p['product_name'] as String,
                                style: GoogleFonts.inter(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text('${p['total_qty']} terjual',
                              style: GoogleFonts.inter(
                                  color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: color.withAlpha(30),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Recent Transactions
        _buildCard(
          title: '🧾 History Transaksi',
          child: recentTrx.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text('Belum ada transaksi',
                        style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: () {
                    List<Widget> trxListWidgets = [];
                    String? currentMonthStr;
                    
                    for (var trx in recentTrx.take(5)) {
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
                            padding: const EdgeInsets.only(top: 12, bottom: 4),
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
                                location: user?.storeName.toUpperCase() ?? '',
                                canVoid: true,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
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

                    if (recentTrx.length > 5) {
                      trxListWidgets.add(
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => AllTransactionsScreen(
                                    timeline: _timeline,
                                    canVoid: true,
                                  ),
                                ));
                              },
                              child: Text('Lihat Semua (${recentTrx.length})', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      );
                    }

                    return trxListWidgets;
                  }(),
                ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSummaryGrid(Map<String, dynamic> kpi) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(
          label: 'Transaksi', value: kpi['today_sales'].toString(),
          color: AppTheme.primary, lightColor: AppTheme.primaryLight,
          icon: Icons.receipt_long_outlined,
        ),
        _SummaryCard(
          label: 'Omzet', value: formatRupiah(kpi['today_revenue'] as num),
          color: AppTheme.accent, lightColor: const Color(0xFFECFEFF),
          icon: Icons.monetization_on_outlined, smallValue: true,
        ),
        _SummaryCard(
          label: 'Laba Kotor', value: formatRupiah(kpi['today_profit'] as num),
          color: AppTheme.success, lightColor: AppTheme.successLight,
          icon: Icons.trending_up_rounded, smallValue: true,
        ),
        _SummaryCard(
          label: 'Produk Terjual', value: kpi['items_sold_today'].toString(),
          color: AppTheme.warning, lightColor: AppTheme.warningLight,
          icon: Icons.inventory_2_outlined,
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [AppTheme.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildBarChart(List days) {
    if (days.isEmpty) return const SizedBox.shrink();
    final maxY = days.map((d) => (d['revenue'] as num).toDouble()).reduce((a, b) => a > b ? a : b);

    return BarChart(BarChartData(
      maxY: maxY * 1.2,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.border, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(days[idx]['date'] as String,
                    style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textSecondary)),
              );
            },
          ),
        ),
      ),
      barGroups: List.generate(days.length, (i) {
        final revenue = (days[i]['revenue'] as num).toDouble();
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: revenue,
            color: AppTheme.primary.withAlpha(200),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            width: 28,
            backDrawRodData: BackgroundBarChartRodData(
              show: true, toY: maxY * 1.2, color: AppTheme.primaryLight,
            ),
          ),
        ]);
      }),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
            formatRupiah(rod.toY),
            GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ));
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color lightColor;
  final IconData icon;
  final bool smallValue;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.lightColor,
    required this.icon,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [AppTheme.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted, letterSpacing: 0.2)),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(7)),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const Spacer(),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: smallValue ? 13 : 20, fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary, letterSpacing: -0.5),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
