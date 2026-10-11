import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token sesi disimpan di penyimpanan aman (Android Keystore), bukan di database/preferensi biasa.
class TokenStorage {
  TokenStorage() : _storage = const FlutterSecureStorage();

  static const String _key = 'auth_token';
  final FlutterSecureStorage _storage;

  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      // Keystore rusak/tidak terbaca: anggap belum login.
      return null;
    }
  }

  Future<void> write(String token) async {
    try {
      await _storage.write(key: _key, value: token);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}
