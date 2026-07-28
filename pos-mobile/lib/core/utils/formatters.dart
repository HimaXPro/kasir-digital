import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

String formatRupiah(num amount) => _idr.format(amount);

String formatDate(String dateStr) {
  try {
    // Parse format '28 Jul 2026 · 13:21' or ISO format
    return dateStr;
  } catch (_) {
    return dateStr;
  }
}
