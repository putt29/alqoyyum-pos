/// Konfigurasi tetap aplikasi (identitas klinik sesuai Excel).
class AppConfig {
  AppConfig._();

  /// Alamat server default. Bisa diganti saat build: --dart-define=API_BASE_URL=https://...
  /// atau lewat ikon pengaturan di halaman login (disimpan lokal di perangkat).
  static const String defaultApiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://192.168.1.10:8000');

  static const String clinicName = 'AL-QOYYUM ROYAL CLINIC';
  static const String address = 'Jl. Buana Indah No.61 Cihideung-Sadang-Purwakarta';
  static const String phone = '(0264) 8464554';
  static const String whatsapp = '0813.1314.8633';
  static const String sipd = '446/SIPD-1785/DPMPTSP/2022';

  /// Dokter TETAP (klinik pribadi). Tidak ada master dokter.
  static const String doctorName = 'dr. Maulia Mardini, SpOG, MARS';

  static const int maxItems = 40;
  static const List<String> paymentMethods = ['Cash', 'Transfer', 'QRIS', 'Debit'];

  /// Kertas struk B5 portrait.
  static const double receiptWidthMm = 176;
  static const double receiptHeightMm = 250;
}
