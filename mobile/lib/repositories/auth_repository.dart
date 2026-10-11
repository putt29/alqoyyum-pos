import '../core/json.dart';
import '../models/user.dart';
import '../services/api_client.dart';

class LoginResult {
  const LoginResult({required this.token, required this.user});

  final String token;
  final AppUser user;
}

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<LoginResult> login(String username, String password) async {
    final j = asMap(await _api.post('/api/auth/login', body: {'username': username, 'password': password}));
    return LoginResult(token: asStr(j['access_token']), user: AppUser.fromJson(asMap(j['user'])));
  }

  Future<AppUser> me() async => AppUser.fromJson(asMap(await _api.get('/api/auth/me')));

  Future<void> logout() async {
    await _api.post('/api/auth/logout');
  }

  /// Mengembalikan token baru (token lama otomatis tidak berlaku setelah ganti password).
  Future<String?> changePassword(String oldPassword, String newPassword) async {
    final j = asMap(await _api.post('/api/auth/change-password',
        body: {'old_password': oldPassword, 'new_password': newPassword}));
    return asStrOrNull(j['access_token']);
  }
}
