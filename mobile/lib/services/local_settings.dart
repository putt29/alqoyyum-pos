import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';

/// Pengaturan lokal perangkat (BUKAN data bisnis): alamat server.
class LocalSettings {
  LocalSettings(this._prefs);

  final SharedPreferences _prefs;
  static const String _kServerUrl = 'server_url';

  String get serverUrl => _prefs.getString(_kServerUrl) ?? AppConfig.defaultApiBaseUrl;

  Future<void> setServerUrl(String value) async {
    await _prefs.setString(_kServerUrl, normalizeUrl(value));
  }

  static String normalizeUrl(String value) {
    var s = value.trim();
    if (s.isEmpty) return AppConfig.defaultApiBaseUrl;
    if (!s.startsWith('http://') && !s.startsWith('https://')) s = 'http://$s';
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }
}
