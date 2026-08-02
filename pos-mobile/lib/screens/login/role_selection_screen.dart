import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart' as my_auth;
import '../main/main_screen.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isLoading = false;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs.getString('pin_kasir') == null) {
      await _prefs.setString('pin_kasir', '1111');
      await _prefs.setString('pin_manager', '2222');
      await _prefs.setString('pin_owner', '3333');
    }
  }

  Future<void> _handleRoleSelection(String role) async {
    final String? expectedPin = _prefs.getString('pin_$role');
    
    final enteredPin = await _showPinDialog(role);
    if (enteredPin == null) return; // cancelled

    if (enteredPin == expectedPin) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => MainScreen(activeRole: role),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN Salah!'), backgroundColor: AppTheme.danger),
      );
    }
  }

  Future<String?> _showPinDialog(String role) async {
    String pin = '';
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Masukkan PIN ${role.toUpperCase()}',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pin.padRight(4, '•').substring(0, 4),
                    style: GoogleFonts.inter(fontSize: 32, letterSpacing: 8, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: List.generate(12, (index) {
                      if (index == 9) return const SizedBox(width: 60, height: 60);
                      if (index == 11) {
                        return SizedBox(
                          width: 60,
                          height: 60,
                          child: TextButton(
                            onPressed: () {
                              if (pin.isNotEmpty) {
                                setState(() => pin = pin.substring(0, pin.length - 1));
                              }
                            },
                            child: const Icon(Icons.backspace_outlined, color: Colors.white54),
                          ),
                        );
                      }
                      final number = index == 10 ? 0 : index + 1;
                      return SizedBox(
                        width: 60,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF334155),
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {
                            if (pin.length < 4) {
                              setState(() => pin += number.toString());
                              if (pin.length == 4) {
                                Navigator.pop(context, pin);
                              }
                            }
                          },
                          child: Text(number.toString(), style: GoogleFonts.inter(fontSize: 24, color: Colors.white)),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text('Batal', style: GoogleFonts.inter(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, null);
                    _showForgotPasswordDialog();
                  },
                  child: Text('Lupa PIN?', style: GoogleFonts.inter(color: AppTheme.primary)),
                ),
              ],
            );
          }
        );
      }
    );
    return result;
  }

  Future<void> _showForgotPasswordDialog() async {
    final passwordCtrl = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool loading = false;
        String? errorMsg;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: Text('Reset PIN', style: GoogleFonts.inter(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Masukkan Password Akun Anda (${user.email})', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      errorText: errorMsg,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Batal', style: GoogleFonts.inter(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: loading ? null : () async {
                    setState(() { loading = true; errorMsg = null; });
                    try {
                      final cred = EmailAuthProvider.credential(email: user.email!, password: passwordCtrl.text);
                      await user.reauthenticateWithCredential(cred);
                      if (!context.mounted) return;
                      Navigator.pop(context, true);
                    } catch (e) {
                      setState(() {
                        loading = false;
                        errorMsg = 'Password salah';
                      });
                    }
                  },
                  child: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Reset'),
                )
              ],
            );
          }
        );
      }
    );

    if (result == true) {
      await _prefs.setString('pin_kasir', '1111');
      await _prefs.setString('pin_manager', '2222');
      await _prefs.setString('pin_owner', '3333');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN berhasil direset ke default (1111, 2222, 3333)'), backgroundColor: AppTheme.success),
      );
    }
  }
  
  Future<void> _logout() async {
    setState(() => _isLoading = true);
    await context.read<my_auth.AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Widget _buildRoleButton(String role, IconData icon, Color color) {
    return InkWell(
      onTap: () => _handleRoleSelection(role),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(50), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(
              role.toUpperCase(),
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: _logout,
            tooltip: 'Logout',
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store_outlined, size: 64, color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Siapa Anda?',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pilih peran untuk melanjutkan',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildRoleButton('kasir', Icons.point_of_sale, Colors.blue),
                      _buildRoleButton('manager', Icons.inventory_2, AppTheme.warning),
                      _buildRoleButton('owner', Icons.admin_panel_settings, AppTheme.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
