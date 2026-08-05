import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../../models/app_user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  AppUser? _currentUser;
  bool _isLoading = true;
  bool _isTimeTampered = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isTimeTampered => _isTimeTampered;

  AuthProvider() {
    _initAuthListener();
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<dynamic>? _userDocSub;
  Timer? _lockTimer;
  Timer? _heartbeatTimer;

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
          _scheduleLockTimer();
          _startHeartbeat();
          notifyListeners();
        });
      }
    });
  }

  void _scheduleLockTimer() async {
    _lockTimer?.cancel();
    if (_currentUser == null || !_currentUser!.isTrial || _currentUser!.trialExpiresAt == null) return;

    final now = DateTime.now();
    final expiresAt = _currentUser!.trialExpiresAt!;

    // Initial time tampering check on stream update
    await _checkTimeTampering(now);
    if (_isTimeTampered) return;
    
    if (expiresAt.isAfter(now)) {
      final duration = expiresAt.difference(now);
      _lockTimer = Timer(duration, () {
        // Automatically lock when the time arrives
        notifyListeners();
      });
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final now = DateTime.now();
      await _checkTimeTampering(now);
    });
  }

  Future<void> _checkTimeTampering(DateTime now) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastKnownString = prefs.getString('last_known_time');
      
      if (lastKnownString != null) {
        final lastKnownTime = DateTime.parse(lastKnownString);
        // If current time is earlier than the last known time, they rewound the clock!
        if (now.isBefore(lastKnownTime)) {
          if (!_isTimeTampered) {
            _isTimeTampered = true;
            notifyListeners();
          }
          return;
        }
      }
      // Update last known time
      await prefs.setString('last_known_time', now.toIso8601String());
    } catch (e) {
      // Ignore errors for shared_preferences
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    _lockTimer?.cancel();
    _heartbeatTimer?.cancel();
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
