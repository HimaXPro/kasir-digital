import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> _saveQrisText(String qris) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    if (!qris.startsWith('000201')) {
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
        setState(() {
          _qrisController.text = qris;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QRIS berhasil disimpan!')),
        );
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

  Future<void> _deleteQris() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final fbService = FirebaseService(user);
      await fbService.saveQrisBaseString('');
      
      if (mounted) {
        setState(() {
          _qrisController.text = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QRIS berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
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
        setState(() => _isScanning = false);
        _saveQrisText(code);
      }
    }
  }

  Future<void> _scanFromGallery() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final controller = MobileScannerController();
      final BarcodeCapture? capture = await controller.analyzeImage(image.path);
      
      if (capture != null && capture.barcodes.isNotEmpty) {
        final String? code = capture.barcodes.first.rawValue;
        if (code != null) {
          _saveQrisText(code);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat menemukan QR Code pada gambar')),
          );
        }
      }
      controller.dispose();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memindai gambar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              'Gunakan kamera atau ambil dari galeri untuk men-scan stiker QRIS fisik cabang Anda.',
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
                    'Status QRIS',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _qrisController.text.isNotEmpty ? AppTheme.successLight : AppTheme.dangerLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _qrisController.text.isNotEmpty ? AppTheme.success : AppTheme.danger),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _qrisController.text.isNotEmpty ? Icons.check_circle : Icons.cancel,
                          color: _qrisController.text.isNotEmpty ? AppTheme.success : AppTheme.danger,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _qrisController.text.isNotEmpty ? 'Tersimpan (Aktif)' : 'Belum diatur',
                            style: GoogleFonts.inter(
                              color: _qrisController.text.isNotEmpty ? AppTheme.success : AppTheme.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => setState(() => _isScanning = true),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan QRIS dari Kamera'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _scanFromGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Ambil dari Galeri'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ),
                  if (_qrisController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _isLoading ? null : _deleteQris,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Hapus QRIS'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: AppTheme.danger,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
