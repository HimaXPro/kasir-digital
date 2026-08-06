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
            backgroundColor: const Color(0xFF0F172A),
            body: Stack(
              children: [
                // Background gradient decorations
                Positioned(
                  top: -100,
                  right: -80,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withAlpha(25),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -60,
                  left: -60,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accent.withAlpha(20),
                    ),
                  ),
                ),
                // Main Content
                SafeArea(
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withAlpha(50),
                                    blurRadius: 32,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.asset(
                                  'assets/images/logo_bhayangkari.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Kasir Digital\nUMKM BHAYANGKARI',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 48),
                            const CircularProgressIndicator(
                              color: AppTheme.primary,
                              strokeWidth: 3,
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'powered by HimaXPro',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
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
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
