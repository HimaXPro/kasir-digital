import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/theme/app_theme.dart';

class QrisSettingsScreen extends StatefulWidget {
  const QrisSettingsScreen({super.key});

  @override
  State<QrisSettingsScreen> createState() => _QrisSettingsScreenState();
}

class _QrisSettingsScreenState extends State<QrisSettingsScreen> {
  final TextEditingController _qrisController = TextEditingController();
  bool _isLoading = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null && user.qrisBaseString != null) {
      _qrisController.text = user.qrisBaseString!;
    }
  }

  @override
  void dispose() {
    _qrisController.dispose();
    super.dispose();
  }

  Future<void> _saveQris() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    final qris = _qrisController.text.trim();
    if (qris.isNotEmpty && !qris.startsWith('000201')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format QRIS tidak valid. Harus berawalan 000201...')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final fbService = FirebaseService(user);
      await fbService.saveQrisBaseString(qris);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan QRIS berhasil disimpan')),
        );
        Navigator.pop(context); // Kembali
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          _qrisController.text = code;
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QRIS berhasil dipindai!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Scan QRIS Toko', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _isScanning = false),
          ),
        ),
        body: MobileScanner(
          onDetect: _onDetect,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan QRIS', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      backgroundColor: AppTheme.bodyBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengaturan QRIS Cabang',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Masukkan kode QRIS Statis cabang Anda di bawah ini, atau gunakan kamera untuk men-scan stiker QRIS fisik secara otomatis.',
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teks Mentah QRIS',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _qrisController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: '000201010211...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _isScanning = true),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan QRIS dari Kamera'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveQris,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Simpan Pengaturan',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
