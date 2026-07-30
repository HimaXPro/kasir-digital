import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class QrisDialog extends StatefulWidget {
  final String transactionId;
  final String qrString;
  final double amount;
  final FirebaseService fbService;

  const QrisDialog({
    super.key,
    required this.transactionId,
    required this.qrString,
    required this.amount,
    required this.fbService,
  });

  @override
  State<QrisDialog> createState() => _QrisDialogState();
}

class _QrisDialogState extends State<QrisDialog> {
  StreamSubscription? _subscription;
  String _status = 'PENDING';

  @override
  void initState() {
    super.initState();
    _listenToTransaction();
  }

  void _listenToTransaction() {
    _subscription = widget.fbService
        .streamTransaction(widget.transactionId)
        .listen((transaction) {
      if (transaction != null) {
        final data = transaction.toFirestore();
        final status = data['qris_status'] as String? ?? 'PENDING';
        if (mounted && status != _status) {
          setState(() {
            _status = status;
          });
          
          if (status == 'PAID') {
            // Berhasil bayar!
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) Navigator.pop(context, true);
            });
          } else if (status == 'FAILED') {
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) Navigator.pop(context, false);
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pembayaran QRIS',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context, false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_status == 'PAID') ...[
              const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 80),
              const SizedBox(height: 16),
              Text('Pembayaran Berhasil!',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.success)),
            ] else if (_status == 'FAILED') ...[
              const Icon(Icons.error_rounded, color: AppTheme.danger, size: 80),
              const SizedBox(height: 16),
              Text('Pembayaran Gagal/Expired',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.danger)),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: const [AppTheme.shadowSm],
                ),
                child: QrImageView(
                  data: widget.qrString,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 24),
              Text('Total Pembayaran:',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              Text(formatRupiah(widget.amount),
                  style: GoogleFonts.inter(
                      fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.primary)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                  ),
                  const SizedBox(width: 12),
                  Text('Menunggu pembayaran...',
                      style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 16),
              // DEBUG BUTTON UNTUK TESTING
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // Kita mock state secara lokal untuk testing alur UI
                  // karena backend sesungguhnya belum online
                  setState(() => _status = 'PAID');
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    if (mounted) Navigator.pop(context, true);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.bug_report_rounded, size: 16),
                label: Text('Simulasikan Bayar (Testing)',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              )
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
