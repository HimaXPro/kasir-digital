import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';

class SubscriptionLockScreen extends StatelessWidget {
  final AppUser? user;
  final bool isTimeTampered;

  const SubscriptionLockScreen({super.key, this.user, this.isTimeTampered = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B), // Dark blue/slate background
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isTimeTampered ? Icons.warning_amber_rounded : Icons.lock_clock,
                size: 80,
                color: const Color(0xFFF472B6), // Pink accent
              ),
              const SizedBox(height: 24),
              Text(
                isTimeTampered ? 'Manipulasi Waktu Terdeteksi' : 'Masa Percobaan Habis',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isTimeTampered 
                  ? 'Kami mendeteksi adanya percobaan memundurkan jam/tanggal pada perangkat ini.\n\nSistem keamanan telah mengunci mesin kasir. Silakan pastikan pengaturan waktu Anda otomatis (tersinkron internet) lalu muat ulang.'
                  : 'Masa uji coba 24 jam untuk cabang ${user?.name ?? 'ini'} telah berakhir.\n'
                    'Silakan hubungi Pusat (Superadmin) untuk mengaktifkan akun atau memperpanjang masa trial Anda.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  label: const Text('Keluar (Logout)', style: TextStyle(color: Colors.white70)),
                  onPressed: () {
                    context.read<AuthProvider>().logout();
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
