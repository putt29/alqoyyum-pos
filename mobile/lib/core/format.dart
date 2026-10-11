import 'package:intl/intl.dart';

final NumberFormat _idNumber = NumberFormat.decimalPattern('id_ID');

/// 125000 -> "Rp125.000"
String rp(num value) => 'Rp${_idNumber.format(value)}';

/// 125000 -> "125.000"
String thousands(num value) => _idNumber.format(value);

/// Singkat untuk sumbu grafik: 1500000 -> "1,5jt"
String rpCompact(num v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1).replaceAll('.', ',')}jt';
  if (v >= 1000) return '${(v / 1000).round()}rb';
  return v.round().toString();
}

String dateTimeShort(DateTime? d) => d == null ? '-' : DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(d);
String dateShort(DateTime? d) => d == null ? '-' : DateFormat('dd/MM/yyyy', 'id_ID').format(d);
String dateLong(DateTime? d) => d == null ? '-' : DateFormat('d MMMM yyyy', 'id_ID').format(d);
String dayMonth(DateTime d) => DateFormat('dd/MM', 'id_ID').format(d);
String weekdayShort(DateTime d) => DateFormat('E', 'id_ID').format(d);

/// "2026-10-09" untuk parameter API.
String isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

/// Hapus semua karakter non-digit: "Rp 125.000" -> 125000
int parseDigits(String s) {
  final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
}

/// Nama file aman: "Struk_367/1026.png" -> "Struk_367-1026.png"
String safeFileName(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9_.\-]'), '-');
