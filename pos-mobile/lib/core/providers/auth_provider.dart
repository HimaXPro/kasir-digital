import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../../models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  AppUser? _currentUser;
  bool _isLoading = true;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final loginTime = prefs.getInt('login_timestamp');
      
      if (loginTime != null) {
        final loginDate = DateTime.fromMillisecondsSinceEpoch(loginTime);
        final now = DateTime.now();
        final difference = now.difference(loginDate).inHours;
        
        if (difference >= 24) {
          // Sesi sudah kadaluarsa (lebih dari 24 jam)
          await _authService.logout();
          await prefs.remove('login_timestamp');
          _currentUser = null;
        } else {
          _currentUser = await _authService.getCurrentAppUser();
        }
      } else {
        _currentUser = await _authService.getCurrentAppUser();
      }
    } catch (e) {
      _currentUser = null;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _currentUser = await _authService.loginWithProfile(email, password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('login_timestamp', DateTime.now().millisecondsSinceEpoch);
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('login_timestamp');
    _currentUser = null;
    notifyListeners();
  }
}
