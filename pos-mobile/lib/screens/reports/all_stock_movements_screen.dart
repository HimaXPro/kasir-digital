import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../../core/providers/auth_provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/stock_movement.dart';

class AllStockMovementsScreen extends StatefulWidget {
  final String timeline;

  const AllStockMovementsScreen({super.key, required this.timeline});

  @override
  State<AllStockMovementsScreen> createState() => _AllStockMovementsScreenState();
}

class _AllStockMovementsScreenState extends State<AllStockMovementsScreen> {
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
        title: const Text('Semua Pergerakan Stok'),
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
      body: StreamBuilder<List<StockMovement>>(
        stream: fb.streamStockMovements(timeline: _selectedTimeline),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          final allMovements = snapshot.data ?? [];
          if (allMovements.isEmpty) {
            return Center(
              child: Text('Belum ada riwayat pergerakan stok',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary)),
            );
          }

          // Calculate Pagination
          final int totalPages = (allMovements.length / _itemsPerPage).ceil();
          final int startIndex = _currentPage * _itemsPerPage;
          final int endIndex = min(startIndex + _itemsPerPage, allMovements.length);
          final paginatedMovements = allMovements.sublist(startIndex, endIndex);

          List<Widget> listWidgets = [];
          for (int i = 0; i < paginatedMovements.length; i++) {
            final m = paginatedMovements[i];
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
                final prevDt = DateTime.parse(paginatedMovements[i-1].createdAt);
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
                  if (i < paginatedMovements.length - 1) const SizedBox(height: 8),
                ],
              ));
            } else {
              listWidgets.add(Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: movementCard,
              ));
            }
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: listWidgets,
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
