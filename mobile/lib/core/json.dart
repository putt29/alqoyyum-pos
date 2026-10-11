/// Helper parsing JSON yang toleran (null/tipe tak terduga tidak membuat aplikasi crash).
int asInt(dynamic v, [int def = 0]) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? def;
  return def;
}

double? asDoubleOrNull(dynamic v) => v is num ? v.toDouble() : null;
String asStr(dynamic v, [String def = '']) => v == null ? def : v.toString();
String? asStrOrNull(dynamic v) => v == null ? null : v.toString();
bool asBool(dynamic v) => v == true || v == 1;
Map<String, dynamic> asMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<dynamic> asList(dynamic v) => v is List ? v : const <dynamic>[];

/// Waktu dari server berformat "2026-10-09T14:03:22+07:00". Diambil sebagai jam dinding klinik (WIB)
/// tanpa konversi zona waktu perangkat.
DateTime? asClinicDate(dynamic v) {
  if (v is! String || v.length < 10) return null;
  final s = v.length >= 19 ? v.substring(0, 19) : v.substring(0, 10);
  return DateTime.tryParse(s);
}
