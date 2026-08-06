import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<AppUser> loginWithProfile(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Login gagal');
      }

      return await _fetchUserProfile(user.uid, user.email ?? '');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        throw Exception('Email tidak ditemukan atau password salah.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Password salah.');
      }
      throw Exception('Login gagal: ${e.code} - ${e.message}');
    }
  }

  Future<AppUser?> getCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await _fetchUserProfile(user.uid, user.email ?? '');
  }

  Future<AppUser> _fetchUserProfile(String uid, String email) async {
    final doc = await _db.collection('users').doc(uid).get();
    
    if (!doc.exists) {
      // Auto-create default profile if missing (Dev Mode Convenience)
      final newUser = AppUser(
        uid: uid,
        email: email,
        name: 'Kasir',
        role: 'kasir',
        storeId: 'bhayangkari_pusat',
        storeName: 'Bhayangkari Pusat',
        provinceId: 'DKI JAKARTA',
        cityId: 'JAKARTA SELATAN',
      );
      await _db.collection('users').doc(uid).set(newUser.toFirestore());
      return newUser;
    }
    
    return AppUser.fromFirestore(doc.data()!, uid);
  }

  Stream<AppUser?> streamUserProfile(String uid, String email) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromFirestore(doc.data()!, uid);
    });
  }

  // Legacy method for old screens
  Future<Map<String, dynamic>> login(String email, String password) async {
    final profile = await loginWithProfile(email, password);
    return {
      'uid': profile.uid,
      'email': profile.email,
      'name': profile.name,
    };
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  Future<Map<String, String>> getUserInfo() async {
    final user = _auth.currentUser;
    return {
      'name': user?.displayName ?? 'Kasir',
      'email': user?.email ?? '',
    };
  }
}
