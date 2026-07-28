import 'package:flutter/material.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'screens/login/login_screen.dart';
import 'screens/main/main_screen.dart';

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

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  final _authService = AuthService();
  late Future<bool> _checkLogin;

  @override
  void initState() {
    super.initState();
    _checkLogin = _authService.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLogin,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
        final isLoggedIn = snapshot.data ?? false;
        return isLoggedIn ? const MainScreen() : const LoginScreen();
      },
    );
  }
}
