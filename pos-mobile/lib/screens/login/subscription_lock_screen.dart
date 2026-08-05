import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_user.dart';

class SubscriptionLockScreen extends StatelessWidget {
  final AppUser user;

  const SubscriptionLockScreen({super.key, required this.user});

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
              const Icon(
                Icons.lock_clock,
                size: 80,
                color: Color(0xFFF472B6), // Pink accent
              ),
              const SizedBox(height: 24),
              Text(
                'Masa Percobaan Habis',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Masa uji coba 24 jam untuk cabang ${user.name} telah berakhir.\n'
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
