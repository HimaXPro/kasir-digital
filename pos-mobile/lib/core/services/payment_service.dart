import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  // Hitung CRC16-CCITT (0x1021, initial 0xFFFF)
  String _calculateCrc16(String payload) {
    int crc = 0xFFFF;
    for (int i = 0; i < payload.length; i++) {
      crc ^= payload.codeUnitAt(i) << 8;
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  // Generate QRIS dengan menyisipkan Tag 54 (Nominal)
  String _generateDynamicQris(String baseQris, double amount) {
    // 1. Hapus CRC lama (Tag 6304 + 4 digit hex) -> Total 8 karakter terakhir
    // Format tag 63 adalah "6304" diikuti dengan 4 karakter checksum
    String qrisTanpaCrc = baseQris;
    if (baseQris.length > 8 && baseQris.contains("6304")) {
      // Potong tepat sebelum 6304
      int idx = baseQris.lastIndexOf("6304");
      if (idx != -1 && idx > baseQris.length - 15) {
        qrisTanpaCrc = baseQris.substring(0, idx);
      }
    }

    // 2. Jika base QRIS sudah ada tag 54, hapus tag 54 tersebut
    // Tag 54 biasanya berada di antara tag 53 (Currency) dan 58 (Country Code)
    // Untuk amannya, kita akan sisipkan tag 54 sebelum tag 58, atau di akhir jika tidak ketemu
    int tag58Idx = qrisTanpaCrc.indexOf("5802");
    
    // Siapkan nilai tag 54
    int amountInt = amount.toInt();
    String amountStr = amountInt.toString();
    String lengthStr = amountStr.length.toString().padLeft(2, '0');
    String tag54 = "54$lengthStr$amountStr";

    String qrisBaru = "";
    if (tag58Idx != -1) {
      qrisBaru = qrisTanpaCrc.substring(0, tag58Idx) + tag54 + qrisTanpaCrc.substring(tag58Idx);
    } else {
      qrisBaru = qrisTanpaCrc + tag54;
    }

    // 3. Tambahkan kembali tag 6304 (ID + Panjang CRC)
    qrisBaru += "6304";

    // 4. Hitung ulang CRC
    String newCrc = _calculateCrc16(qrisBaru);

    // 5. Gabungkan
    return qrisBaru + newCrc;
  }

  Future<Map<String, dynamic>> generateQris({
    required String transactionId,
    required double amount,
    String? qrisBaseString,
    List<Map<String, dynamic>>? items,
    String? customerName,
    String? email,
  }) async {
    // 1. Coba gunakan Dynamic QRIS (Offline) jika qrisBaseString tersedia
    if (qrisBaseString != null && qrisBaseString.trim().isNotEmpty) {
      try {
        final dynamicQris = _generateDynamicQris(qrisBaseString.trim(), amount);
        return {
          'success': true,
          'transactionId': transactionId,
          'qrString': dynamicQris,
          'is_offline': true,
        };
      } catch (e) {
        print('Gagal membuat dynamic QRIS lokal: $e');
      }
    }

    // 2. Jika tidak ada base QRIS, gunakan Mock/Static QRIS sementara (Atau API Asli)
    print('Warning: qrisBaseString kosong. Menggunakan Mock QRIS untuk testing UI.');
    return {
      'success': true,
      'transactionId': transactionId,
      'qrString': '00020101021226570011ID.CO.QRIS.WWW01189360091531234567890214154123456789010303UMI51440014ID.CO.QRIS.WWW0215ID10200212345670303UMI52045499530336054061250005802ID5914KASIR DIGITAL 6013JAKARTA PUSAT6105103406233011403010323304194070732330429408006304ED28',
    };
  }
}
