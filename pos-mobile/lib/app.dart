import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/role_selection_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_main_screen.dart';

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
          return const Scaffold(
            backgroundColor: Color(0xFF4F46E5),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.point_of_sale, color: Colors.white, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Kasir Digital',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 32),
                  CircularProgressIndicator(color: Colors.white54),
                ],
              ),
            ),
          );
        }
        
        final isLoggedIn = auth.isLoggedIn;
        
        if (kIsWeb) {
          return isLoggedIn ? const AdminMainScreen() : const AdminLoginScreen();
        } else {
          return isLoggedIn ? const RoleSelectionScreen() : const LoginScreen();
        }
      },
    );
  }
}
