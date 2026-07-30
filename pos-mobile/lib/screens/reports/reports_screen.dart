import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Reuse dashboard endpoint for report stats
      final result = await _api.get('/dashboard');
      setState(() => _data = result['data'] as Map<String, dynamic>);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      Text('Gagal memuat laporan',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primary,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildContent() {
    final kpi = _data!['kpi'] as Map<String, dynamic>;
    final chartDays = _data!['chart_days'] as List;
    final topProducts = _data!['top_products'] as List;
    final recentTrx = _data!['recent_transactions'] as List;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Today Summary
        Text('📈 Ringkasan Hari Ini',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _buildSummaryGrid(kpi),
        const SizedBox(height: 16),

        // Revenue Chart
        _buildCard(
          title: '📊 Omzet 7 Hari Terakhir',
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
                  children: recentTrx.map((trx) {
                    final t = trx as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
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
                                Text(t['invoice_number'] as String,
                                    style: GoogleFonts.inter(
                                        fontSize: 13, fontWeight: FontWeight.w700,
                                        color: AppTheme.primary)),
                                Text(t['created_at'] as String,
                                    style: GoogleFonts.inter(
                                        fontSize: 11, color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formatRupiah(t['grand_total'] as num),
                                  style: GoogleFonts.inter(
                                      fontSize: 13, fontWeight: FontWeight.w700)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(t['payment_method'] as String,
                                    style: GoogleFonts.inter(
                                        fontSize: 10, fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
