import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final result = await _api.post(
      '/auth/login',
      {'email': email, 'password': password},
      auth: false,
    );

    final token = result['data']['token'] as String;
    final user  = result['data']['user'] as Map<String, dynamic>;

    await ApiService.setToken(token);

    // Simpan info user
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', user['name'].toString());
    await prefs.setString('user_email', user['email'].toString());

    return user;
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', {});
    } catch (_) {
      // Ignore error saat logout, tetap hapus token lokal
    }
    await ApiService.clearToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name':  prefs.getString('user_name') ?? 'User',
      'email': prefs.getString('user_email') ?? '',
    };
  }
}
