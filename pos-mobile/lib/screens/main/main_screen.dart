import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers/auth_provider.dart' as my_auth;
import '../../core/theme/app_theme.dart';
import '../login/login_screen.dart';
import '../login/role_selection_screen.dart';
import '../login/subscription_lock_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../pos/pos_screen.dart';
import '../products/products_screen.dart';
import '../categories/categories_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/printer_settings_screen.dart';

class MainScreen extends StatefulWidget {
  final String activeRole;
  const MainScreen({super.key, this.activeRole = 'kasir'});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  Future<void> _switchRole(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Ganti Peran', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        content: Text(
          'Apakah Anda ingin kembali ke layar Pilih Peran?',
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
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Ya, Ganti', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const RoleSelectionScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null || user.email == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool loading = false;
        String? errorMsg;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Ganti Password', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${user.email}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: oldPasswordCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Password Lama',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Password Baru (Minimal 6 karakter)',
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
                    if (newPasswordCtrl.text.length < 6) {
                      setState(() => errorMsg = 'Password baru minimal 6 karakter');
                      return;
                    }
                    setState(() { loading = true; errorMsg = null; });
                    try {
                      final cred = EmailAuthProvider.credential(email: user.email!, password: oldPasswordCtrl.text);
                      await user.reauthenticateWithCredential(cred);
                      await user.updatePassword(newPasswordCtrl.text);
                      if (!context.mounted) return;
                      Navigator.pop(context, true);
                    } catch (e) {
                      setState(() {
                        loading = false;
                        errorMsg = 'Password lama salah atau gagal mengubah: ${e.toString()}';
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan'),
                )
              ],
            );
          }
        );
      }
    );

    if (result == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diubah. Seluruh perangkat akan dilogout. Silakan login kembali.'), backgroundColor: AppTheme.success, duration: Duration(seconds: 4)),
      );
      await context.read<my_auth.AuthProvider>().logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<my_auth.AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (authProvider.isTimeTampered) {
      return SubscriptionLockScreen(user: user, isTimeTampered: true);
    }

    if (user.isLocked) {
      return SubscriptionLockScreen(user: user);
    }

    // Override roles based on activeRole selected in RoleSelectionScreen
    final bool isOwner = widget.activeRole == 'owner';
    final bool isManager = widget.activeRole == 'manager' || isOwner;

    // Generate allowed screens and nav items dynamically based on role
    final List<Widget> screens = [];
    final List<_NavItem> navItems = [];
    
    // 1. Dashboard (Owner only)
    if (isOwner) {
      screens.add(DashboardScreen(
        onBukaKasirTap: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
      ));
      navItems.add(const _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'));
    }
    
    // 2. POS (All roles)
    screens.add(const PosScreen());
    navItems.add(const _NavItem(icon: Icons.point_of_sale_outlined, activeIcon: Icons.point_of_sale, label: 'Kasir'));

    // 3. Products (Manager & Owner)
    if (isManager) {
      screens.add(const ProductsScreen());
      navItems.add(const _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Produk'));
    }

    // 4. Reports (Owner only)
    if (isOwner) {
      screens.add(const ReportsScreen());
      navItems.add(const _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Laporan'));
    }

    if (_selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      drawer: _buildDrawer(user, navItems, _selectedIndex),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNav(navItems),
    );
  }

  Widget _buildBottomNav(List<_NavItem> navItems) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isActive = _selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primary.withAlpha(20)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            key: ValueKey(isActive),
                            color: isActive ? AppTheme.primary : AppTheme.textMuted,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? AppTheme.primary : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(dynamic user, List<_NavItem> navItems, int currentIndex) {
    return Drawer(
      backgroundColor: AppTheme.sidebarBg,
      child: SafeArea(
        child: Column(
          children: [
            // Logo header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withAlpha(15)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(100),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.point_of_sale, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kasir Digital',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF1F5F9),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Role: ${widget.activeRole.toUpperCase()}',
                        style: GoogleFonts.inter(
                          color: AppTheme.sidebarText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Navigation
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(10),
                children: [
                  _drawerLabel('MENU UTAMA'),
                  ...List.generate(navItems.length, (index) {
                    final item = navItems[index];
                    final isActive = currentIndex == index;
                    return _drawerItemNav(
                      isActive ? item.activeIcon : item.icon,
                      item.label,
                      () {
                        Navigator.pop(context);
                        setState(() => _selectedIndex = index);
                      },
                      isActive: isActive,
                    );
                  }),
                  if (user.isManager || user.isOwner) ...[
                    _drawerLabel('MASTER DATA'),
                    _drawerItemNav(
                      Icons.category_outlined,
                      'Kategori',
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                        );
                      },
                    ),
                  ],
                  _drawerLabel('PENGATURAN'),
                  _drawerItemNav(
                    Icons.print_outlined,
                    'Pengaturan Printer',
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
                      );
                    },
                  ),
                  if (widget.activeRole == 'owner') ...[
                    _drawerItemNav(
                      Icons.lock_reset_outlined,
                      'Ganti Password',
                      () {
                        Navigator.pop(context);
                        _showChangePasswordDialog(context);
                      },
                    ),
                  ],
                ],
              ),
            ),

            // User footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withAlpha(15)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFCBD5E1),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${user.cityId} - ${user.provinceId}',
                          style: GoogleFonts.inter(
                            color: AppTheme.sidebarText,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _switchRole(context);
                    },
                    icon: const Icon(Icons.swap_horiz_rounded,
                        color: Color(0xFF64748B), size: 24),
                    tooltip: 'Ganti Peran',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerLabel(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF475569),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _drawerItemNav(IconData icon, String label, VoidCallback onTap, {bool isActive = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? AppTheme.primary : AppTheme.sidebarTextH, size: 18),
            const SizedBox(width: 11),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? AppTheme.primary : AppTheme.sidebarTextH,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
