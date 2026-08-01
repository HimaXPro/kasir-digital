import 'package:flutter/material.dart';
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
      _currentUser = await _authService.getCurrentAppUser();
    } catch (e) {
      _currentUser = null;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _currentUser = await _authService.loginWithProfile(email, password);
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }
}
