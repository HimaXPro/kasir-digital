import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../products/products_screen.dart';
import '../categories/categories_screen.dart';
import '../reports/reports_screen.dart';
import 'admin_login_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ProductsScreen(),
    CategoriesScreen(),
    ReportsScreen(),
    Center(child: Text('Manajemen Kasir (Segera Hadir)')),
  ];

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 250,
              color: AppTheme.primary,
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  const Icon(Icons.admin_panel_settings, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Admin Portal',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildNavButton(0, Icons.dashboard_rounded, 'Dashboard'),
                  _buildNavButton(1, Icons.inventory_2_rounded, 'Produk'),
                  _buildNavButton(2, Icons.category_rounded, 'Kategori'),
                  _buildNavButton(3, Icons.bar_chart_rounded, 'Laporan'),
                  _buildNavButton(4, Icons.people_rounded, 'Kasir'),
                  const Spacer(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white70),
                    title: const Text('Keluar', style: TextStyle(color: Colors.white70)),
                    onTap: _logout,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          Expanded(
            child: _screens[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.textMuted,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
                BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Produk'),
                BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Kategori'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Laporan'),
                BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Kasir'),
              ],
            ),
    );
  }

  Widget _buildNavButton(int index, IconData icon, String title) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.black12,
      onTap: () => setState(() => _currentIndex = index),
    );
  }
}
