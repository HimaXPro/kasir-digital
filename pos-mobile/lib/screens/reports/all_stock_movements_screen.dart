import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/stock_movement.dart';

class AllStockMovementsScreen extends StatelessWidget {
  final String timeline;

  const AllStockMovementsScreen({super.key, required this.timeline});

  @override
  Widget build(BuildContext context) {
    final fb = FirebaseService(context.read<AuthProvider>().currentUser!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Pergerakan Stok'),
        elevation: 0,
      ),
      body: StreamBuilder<List<StockMovement>>(
        stream: fb.streamStockMovements(timeline: timeline),
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

          List<Widget> listWidgets = [];
          for (int i = 0; i < movements.length; i++) {
            final m = movements[i];
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
                final prevDt = DateTime.parse(movements[i-1].createdAt);
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
                  if (i < movements.length - 1) const SizedBox(height: 8),
                ],
              ));
            } else {
              listWidgets.add(Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: movementCard,
              ));
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: listWidgets,
          );
        },
      ),
    );
  }
}
