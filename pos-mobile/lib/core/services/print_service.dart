import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';

class PrintService {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  Future<List<BluetoothDevice>> getDevices() async {
    try {
      return await bluetooth.getBondedDevices();
    } catch (e) {
      return [];
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      bool? isConnected = await bluetooth.isConnected;
      if (isConnected == true) {
        await bluetooth.disconnect();
      }
      return await bluetooth.connect(device) ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() async {
    await bluetooth.disconnect();
  }

  Future<bool> isConnected() async {
    return await bluetooth.isConnected ?? false;
  }

  Future<void> printReceipt(Map<String, dynamic> transactionData) async {
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected != true) {
      throw Exception('Printer tidak terhubung. Silakan sambungkan printer Bluetooth terlebih dahulu.');
    }

    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    bluetooth.printNewLine();
    bluetooth.printCustom("KASIR DIGITAL", 2, 1);
    bluetooth.printCustom("Point of Sale System", 0, 1);
    bluetooth.printCustom("-------------------------------", 0, 1);
    
    bluetooth.printLeftRight("No:", transactionData['invoice_number'] ?? '-', 0);
    bluetooth.printLeftRight("Tgl:", transactionData['created_at'] ?? '-', 0);
    bluetooth.printLeftRight("Kasir:", transactionData['cashier_name']?.toString() ?? 'Kasir', 0);
    if (transactionData['customer_name'] != null && transactionData['customer_name'].toString().isNotEmpty) {
      bluetooth.printLeftRight("Pelanggan:", transactionData['customer_name'].toString(), 0);
    }
    bluetooth.printLeftRight("Pembayaran:", (transactionData['payment_method'] ?? 'CASH').toString().toUpperCase(), 0);
    if (transactionData['order_note'] != null && transactionData['order_note'].toString().isNotEmpty) {
      bluetooth.printCustom("Catatan: ${transactionData['order_note']}", 0, 0);
    }
    
    bluetooth.printCustom("-------------------------------", 0, 1);

    List items = transactionData['items'] ?? [];
    for (var item in items) {
      bluetooth.printCustom(item['name'] ?? item['product_name'] ?? 'Item', 0, 0);
      
      if (item['note'] != null && item['note'].toString().isNotEmpty) {
        bluetooth.printCustom("  * ${item['note']}", 0, 0);
      }
      
      int qty = item['quantity'] ?? item['qty'] ?? 1;
      int price = item['price'] ?? item['selling_price'] ?? 0;
      int subtotal = qty * price;
      
      bluetooth.printLeftRight("$qty x ${currency.format(price)}", currency.format(subtotal), 0);
    }

    bluetooth.printCustom("-------------------------------", 0, 1);
    
    int subtotal = transactionData['subtotal'] ?? 0;
    int discount = transactionData['discount_amount'] ?? transactionData['discount'] ?? 0;
    int total = transactionData['grand_total'] ?? transactionData['total'] ?? 0;
    int payAmt = transactionData['pay_amount'] ?? transactionData['payAmt'] ?? total;
    int change = payAmt - total;

    if (discount > 0) {
      bluetooth.printLeftRight("Subtotal", currency.format(subtotal), 0);
      bluetooth.printLeftRight("Diskon", "-${currency.format(discount)}", 0);
    }
    bluetooth.printLeftRight("TOTAL", currency.format(total), 1);
    bluetooth.printLeftRight("TUNAI", currency.format(payAmt), 0);
    bluetooth.printLeftRight("KEMBALI", currency.format(change > 0 ? change : 0), 0);

    bluetooth.printCustom("-------------------------------", 0, 1);
    bluetooth.printCustom("Terima kasih atas kunjungan Anda", 0, 1);
    bluetooth.printCustom("Barang yang sudah dibeli", 0, 1);
    bluetooth.printCustom("tidak dapat dikembalikan", 0, 1);
    
    bluetooth.printNewLine();
    bluetooth.printNewLine();
    bluetooth.printNewLine();
    bluetooth.paperCut();
  }
}
