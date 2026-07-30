import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Base URL Laravel backend. Ganti sesuai IP server Anda.
/// Contoh: 'http://192.168.1.100:8000/api'
/// Untuk emulator Android (localhost): 'http://10.0.2.2:8000/api'
const String kBaseUrl = 'https://smokiness-catty-wasabi.ngrok-free.dev/api';

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = kBaseUrl});

  // ── Token Management ────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }

  // ── Headers ─────────────────────────────────────────────────────────
  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ── HTTP Methods ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool auth = true,
  }) async {
    var uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await http
        .get(uri, headers: await _headers(auth: auth))
        .timeout(const Duration(seconds: 15));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _headers(auth: auth),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));

    return _handleResponse(response);
  }

  // ── Response Handler ────────────────────────────────────────────────
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body['message'] ?? 'Terjadi kesalahan server.';

    if (response.statusCode == 401) {
      throw ApiException('Sesi habis. Silakan login kembali.', 401);
    }
    if (response.statusCode == 422) {
      // Validation errors
      final errors = body['errors'] as Map<String, dynamic>?;
      final firstError = errors?.values.first;
      final errMsg = firstError is List ? firstError.first : message;
      throw ApiException(errMsg.toString(), 422);
    }

    throw ApiException(message.toString(), response.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
