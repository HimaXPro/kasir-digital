import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Login gagal');
      }

      return {
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? 'Kasir',
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Email tidak ditemukan.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Password salah.');
      }
      throw Exception('Login gagal: ${e.message}');
    }
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
