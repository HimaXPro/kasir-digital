import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/role_selection_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/login/subscription_lock_screen.dart';

import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';

class KasirDigitalApp extends StatelessWidget {
  const KasirDigitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kasir Digital',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatelessWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return Scaffold(
            backgroundColor: const Color(0xFF4F46E5),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo_bhayangkari.jpg',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kasir Digital | UMKM BHAYANGKARI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(color: Colors.white54),
                  const SizedBox(height: 48),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'powered by HimaXPro',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Image.asset(
                        'assets/images/logo_himaxpro.png',
                        width: 80,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
        
        final isLoggedIn = auth.isLoggedIn;
        
        if (!isLoggedIn) {
          return const LoginScreen();
        }

        if (auth.currentUser?.isLocked == true) {
          return SubscriptionLockScreen(user: auth.currentUser!);
        }

        return const RoleSelectionScreen();
      },
    );
  }
}
