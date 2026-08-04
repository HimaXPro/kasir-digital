import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    _initAuthListener();
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<dynamic>? _userDocSub;

  void _initAuthListener() {
    _authSub = FirebaseAuth.instance.idTokenChanges().listen((User? user) async {
      _isLoading = true;
      notifyListeners();
      
      _userDocSub?.cancel();
      
      if (user == null) {
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
      } else {
        // Listen to Firestore document directly for real-time updates (SaaS Lock, etc)
        _userDocSub = _authService.streamUserProfile(user.uid, user.email ?? '').listen((AppUser? appUser) {
          _currentUser = appUser;
          _isLoading = false;
          notifyListeners();
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
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

  Future<void> reloadUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authService.getCurrentAppUser();
    } catch (e) {
      // Keep old user or set to null? Better keep old but we'll see
    }
    _isLoading = false;
    notifyListeners();
  }
}
