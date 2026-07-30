import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  // Ganti dengan URL function Anda setelah di-deploy ke Firebase
  // Contoh: 'https://us-central1-kasir-bhayangkari.cloudfunctions.net/generateQris'
  final String _baseUrl = 'http://10.0.2.2:5001/kasir-bhayangkari/us-central1/generateQris';

  Future<Map<String, dynamic>> generateQris({
    required String transactionId,
    required double amount,
    List<Map<String, dynamic>>? items,
    String? customerName,
    String? email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'transactionId': transactionId,
          'amount': amount,
          'items': items,
          'customerName': customerName,
          'email': email,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal membuat QRIS: ${response.statusCode}');
      }
    } catch (e) {
      // FALLBACK MOCK: Untuk keperluan testing di HP fisik jika Firebase Functions belum di-deploy
      print('Warning: API gagal/timeout ($e). Menggunakan Mock QRIS untuk testing UI.');
      return {
        'success': true,
        'transactionId': transactionId,
        'qrString': '00020101021226570011ID.CO.QRIS.WWW01189360091531234567890214154123456789010303UMI51440014ID.CO.QRIS.WWW0215ID10200212345670303UMI52045499530336054061250005802ID5914KASIR DIGITAL 6013JAKARTA PUSAT6105103406233011403010323304194070732330429408006304ED28',
      };
    }
  }
}
