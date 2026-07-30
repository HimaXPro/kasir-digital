import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../login/login_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../pos/pos_screen.dart';
import '../products/products_screen.dart';
import '../categories/categories_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/printer_settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final _authService = AuthService();

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.point_of_sale_outlined, activeIcon: Icons.point_of_sale, label: 'Kasir'),
    _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Produk'),
    _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Laporan'),
  ];

  final List<Widget> _screens = const [
    DashboardScreen(),
    PosScreen(),
    ProductsScreen(),
    ReportsScreen(),
  ];

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Apakah Anda yakin ingin keluar?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Logout', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
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
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
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

  Widget _buildDrawer() {
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
                        'Point of Sale',
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
                  _drawerItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
                  _drawerItem(Icons.point_of_sale_outlined, Icons.point_of_sale, 'Kasir POS', 1),
                  _drawerItem(Icons.inventory_2_outlined, Icons.inventory_2, 'Manajemen Produk', 2),
                  _drawerItem(Icons.bar_chart_outlined, Icons.bar_chart, 'Laporan', 3),
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
              child: FutureBuilder<Map<String, String>>(
                future: _authService.getUserInfo(),
                builder: (ctx, snap) {
                  final name = snap.data?['name'] ?? 'User';
                  final email = snap.data?['email'] ?? '';
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
                  return Row(
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
                            initial,
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
                              name,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFCBD5E1),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              email,
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
                          _logout();
                        },
                        icon: const Icon(Icons.logout_rounded,
                            color: Color(0xFF64748B), size: 18),
                        tooltip: 'Logout',
                      ),
                    ],
                  );
                },
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

  Widget _drawerItem(IconData icon, IconData activeIcon, String label, int index) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withAlpha(46)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.sidebarActive : AppTheme.sidebarTextH,
              size: 18,
            ),
            const SizedBox(width: 11),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? AppTheme.sidebarActive : AppTheme.sidebarTextH,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItemNav(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.sidebarTextH, size: 18),
            const SizedBox(width: 11),
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.sidebarTextH,
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
