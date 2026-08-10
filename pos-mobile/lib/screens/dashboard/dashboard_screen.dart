import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../models/transaction.dart' as tr;

import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/version_service.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onBukaKasirTap;

  const DashboardScreen({super.key, this.onBukaKasirTap});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Stream<Map<String, dynamic>> _dashboardStream;
  late Stream<List<Product>> _productsStream;

  @override
  void initState() {
    super.initState();
    final fb = FirebaseService(context.read<AuthProvider>().currentUser!);
    _dashboardStream = fb.streamDashboardStats();
    _productsStream = fb.streamProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: const [
          // Refresh button removed since it's real-time now
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _dashboardStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }

          final data = snapshot.data;
          if (data == null) {
            return _buildError('Data kosong');
          }

          return _buildContent(data);
        },
      ),
    );
  }

  Widget _buildError(String errorMsg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 56, color: AppTheme.textMuted),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat data',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(errorMsg,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _buildContent(Map<String, dynamic> data) {
    final kpi = data['kpi'] as Map<String, dynamic>;
    final chartDays = data['chart_days'] as List;
    final topProducts = data['top_products'] as List;
    final recentTrx = data['recent_transactions'] as List;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          sliver: SliverList.list(
            children: [
              _buildPageHeader(),
              const SizedBox(height: 16),
              _buildMaintenanceAlert(),
              _buildNegativeStockAlert(),
              _buildKpiGrid(kpi),
              const SizedBox(height: 16),
              _buildRevenueChart(chartDays),
              const SizedBox(height: 16),
              _buildTopProducts(topProducts),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverFillRemaining(
            hasScrollBody: false,
            child: _buildRecentTransactions(recentTrx),
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceAlert() {
    return StreamBuilder<AppConfigModel?>(
      stream: VersionService.streamAppConfig(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final config = snapshot.data!;

        if (config.isScheduled &&
            config.maintenanceStart != null &&
            config.maintenanceEnd != null) {
          try {
            final now = DateTime.now();
            final start = DateTime.parse(config.maintenanceStart!);
            final end = DateTime.parse(config.maintenanceEnd!);

            if (now.isBefore(start) && now.isBefore(end)) {
              final formatStart = DateFormat('dd MMM HH:mm').format(start);
              final formatEnd = DateFormat('HH:mm').format(end);
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  border: Border.all(color: const Color(0xFFFDE047)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFCA8A04), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INFO: Maintenance Terjadwal',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF854D0E),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Aplikasi akan terkunci otomatis pada $formatStart hingga $formatEnd.',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFA16207),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          } catch (e) {
            // ignore parse error
          }
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildNegativeStockAlert() {
    return StreamBuilder<List<Product>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final negativeProducts =
            snapshot.data!.where((p) => p.stock < 0).toList();
        if (negativeProducts.isEmpty) return const SizedBox();

        final productNames =
            negativeProducts.map((p) => '${p.name} (${p.stock})').join(', ');

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            border: Border.all(color: const Color(0xFFFCA5A5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perhatian: Ada Stok Minus',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF991B1B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Produk [$productNames] saat ini memiliki stok minus. Hal ini wajar terjadi apabila ada antrean yang dibayar saat mode Offline. Harap cek fisik barang dan lakukan penyesuaian (Adjustment) di menu Produk.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB91C1C),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageHeader() {
    final now = DateTime.now();
    final days = [
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    final dateStr =
        '${days[now.weekday]}, ${now.day} ${months[now.month]} ${now.year}';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: widget.onBukaKasirTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.point_of_sale, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text('Buka Kasir',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid(Map<String, dynamic> kpi) {
    return LayoutBuilder(builder: (context, constraints) {
      int crossAxisCount = 2;
      double childAspectRatio = 1.35;

      if (constraints.maxWidth >= 1024) {
        crossAxisCount = 4;
        childAspectRatio = 1.8;
      } else if (constraints.maxWidth >= 600) {
        crossAxisCount = 4;
        childAspectRatio = 1.2;
      }

      return GridView.count(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: childAspectRatio,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _KpiCard(
            label: 'Transaksi Hari Ini',
            value: kpi['today_sales'].toString(),
            badge: 'Transaksi Selesai',
            color: AppTheme.primary,
            lightColor: AppTheme.primaryLight,
            icon: Icons.receipt_long_outlined,
          ),
          _KpiCard(
            label: 'Omzet Hari Ini',
            value: formatRupiah(kpi['today_revenue'] as num),
            badge: 'Total Penjualan',
            color: AppTheme.accent,
            lightColor: const Color(0xFFECFEFF),
            icon: Icons.monetization_on_outlined,
            smallValue: true,
          ),
          _KpiCard(
            label: 'Laba Kotor',
            value: formatRupiah(kpi['today_profit'] as num),
            badge: 'Gross Profit',
            color: AppTheme.success,
            lightColor: AppTheme.successLight,
            icon: Icons.trending_up_rounded,
            smallValue: true,
          ),
          _KpiCard(
            label: 'Produk Terjual',
            value: kpi['items_sold_today'].toString(),
            badge: 'Total Item Terjual',
            color: AppTheme.warning,
            lightColor: AppTheme.warningLight,
            icon: Icons.inventory_2_outlined,
          ),
        ],
      );
    });
  }

  Widget _buildRevenueChart(List days) {
    if (days.isEmpty) return const SizedBox.shrink();
    final maxY = days
        .map((d) => (d['revenue'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [AppTheme.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'Omzet 6 Bulan Terakhir',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                  getDrawingHorizontalLine: (v) => const FlLine(
                    color: AppTheme.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= days.length)
                          return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            days[idx]['date'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(days.length, (i) {
                  final revenue = (days[i]['revenue'] as num).toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: revenue,
                        color: AppTheme.primary.withAlpha(200),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        width: 28,
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY * 1.2,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ],
                  );
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        formatRupiah(rod.toY),
                        GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(List products) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [AppTheme.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'Produk Terlaris (Hari Ini)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...products.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value as Map<String, dynamic>;
            final color =
                AppTheme.chartPalette[i % AppTheme.chartPalette.length];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.inter(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p['product_name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${p['total_qty']} terjual',
                      style: GoogleFonts.inter(
                        color: AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(List transactions) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [AppTheme.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('🧾', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  'Transaksi Terbaru (Hari Ini)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Text('🧾', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada transaksi hari ini',
                      style: GoogleFonts.inter(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ...transactions.map((trx) {
              final t = trx as tr.Transaction;
              String dateStr = t.createdAt;
              try {
                final dt = DateTime.parse(t.createdAt);
                dateStr = DateFormat('dd/MM/yyyy HH:mm').format(dt);
              } catch (_) {}

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.invoiceNumber,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${t.cashierName ?? "Kasir"} • $dateStr',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatRupiah(t.grandTotal),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            t.paymentMethod,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── KPI Card Widget ─────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String badge;
  final Color color;
  final Color lightColor;
  final IconData icon;
  final bool smallValue;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.badge,
    required this.color,
    required this.lightColor,
    required this.icon,
    this.smallValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
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
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: smallValue ? 14 : 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: lightColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
