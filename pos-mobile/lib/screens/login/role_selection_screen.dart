import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_user.dart';
import 'subscription_lock_screen.dart';
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

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleRoleSelection(String role) async {
    final user = context.read<my_auth.AuthProvider>().currentUser;
    if (user == null) return;
    
    final pinDocRef = FirebaseFirestore.instance
        .collection('stores')
        .doc(user.storeId)
        .collection('settings')
        .doc('store_pins');

    setState(() => _isLoading = true);
    String? expectedPin;
    try {
      final doc = await pinDocRef.get(const GetOptions(source: Source.server));
      if (!doc.exists) {
        // Create defaults if not exist
        await pinDocRef.set({
          'pin_kasir': '111111',
          'pin_manager': '222222',
          'pin_owner': '333333',
        });
        expectedPin = role == 'kasir' ? '111111' : role == 'manager' ? '222222' : '333333';
      } else {
        expectedPin = doc.data()?['pin_$role'];
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
        const SnackBar(content: Text('Koneksi internet diperlukan untuk masuk!'), backgroundColor: AppTheme.danger),
      );
      return;
    }
    setState(() => _isLoading = false);
    
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
      ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          index < pin.length ? Icons.circle : Icons.radio_button_unchecked,
                          size: 20,
                          color: AppTheme.primary,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 240, // Memaksa layout maksimal 3 kolom (60*3 + 16*2 = 212)
                    child: Wrap(
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
                              if (pin.length < 6) {
                                setState(() => pin += number.toString());
                                if (pin.length == 6) {
                                  Navigator.pop(context, pin);
                                }
                              }
                            },
                            child: Text(number.toString(), style: GoogleFonts.inter(fontSize: 24, color: Colors.white)),
                          ),
                        );
                      }),
                    ),
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
                    _showForgotPasswordDialog(role);
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

  Future<void> _showForgotPasswordDialog(String role) async {
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
      if (!mounted) return;
      await _showSetNewPinDialog(role);
    }
  }

  Future<void> _showSetNewPinDialog(String role) async {
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
                'Buat PIN Baru (${role.toUpperCase()})',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Masukkan 6 digit PIN baru',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          index < pin.length ? Icons.circle : Icons.radio_button_unchecked,
                          size: 20,
                          color: AppTheme.success,
                        ),
                      );
                    }),
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
                            if (pin.length < 6) {
                              setState(() => pin += number.toString());
                              if (pin.length == 6) {
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
              ],
            );
          }
        );
      }
    );

    if (result != null && result.length == 6) {
      final user = context.read<my_auth.AuthProvider>().currentUser;
      if (user == null) return;
      
      final pinDocRef = FirebaseFirestore.instance
          .collection('stores')
          .doc(user.storeId)
          .collection('settings')
          .doc('store_pins');

      setState(() => _isLoading = true);
      try {
        await pinDocRef.set({
          'pin_$role': result,
        }, SetOptions(merge: true));
        if (!mounted) return;
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          SnackBar(content: Text('PIN baru untuk ${role.toUpperCase()} berhasil disimpan!'), backgroundColor: AppTheme.success),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)..clearSnackBars()..showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan PIN. Pastikan koneksi internet stabil.'), backgroundColor: AppTheme.danger),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun utama Koperasi?',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Ya, Logout', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

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
    final authProvider = context.watch<my_auth.AuthProvider>();
    final user = authProvider.currentUser;
    
    if (authProvider.isTimeTampered) {
      return SubscriptionLockScreen(user: user, isTimeTampered: true);
    }
    
    if (user != null && user.isLocked) {
      return SubscriptionLockScreen(user: user);
    }

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
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/logo_bhayangkari.jpg',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
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
                      const SizedBox(height: 32),
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
                        const SizedBox(height: 32),
                        // Footer
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'powered by HimaXPro',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Image.asset(
                              'assets/images/logo_himaxpro.png',
                              width: 60,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
