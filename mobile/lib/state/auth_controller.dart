import 'package:flutter/foundation.dart';

import '../core/errors.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../services/token_storage.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthController extends ChangeNotifier {
  AuthController({required AuthRepository repository, required TokenStorage tokens})
      : _repo = repository,
        _tokens = tokens;

  final AuthRepository _repo;
  final TokenStorage _tokens;

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;

  /// Pesan untuk ditampilkan di halaman login (mis. sesi berakhir / server tak terjangkau).
  String? notice;

  bool get isOwner => user?.isOwner ?? false;

  /// Dipanggil saat aplikasi dibuka: pulihkan sesi bila token masih valid di server.
  Future<void> restore() async {
    final token = await _tokens.read();
    if (token == null) {
      status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    try {
      user = await _repo.me();
      status = AuthStatus.signedIn;
    } catch (e) {
      if (e is ApiException && e.isUnauthorized) await _tokens.clear();
      user = null;
      status = AuthStatus.signedOut;
      notice = (e is ApiException && e.isUnauthorized) ? null : errorMessage(e);
    }
    notifyListeners();
  }

  /// Melempar ApiException bila gagal (ditangkap oleh halaman login).
  Future<void> login(String username, String password) async {
    final result = await _repo.login(username.trim(), password);
    await _tokens.write(result.token);
    user = result.user;
    notice = null;
    status = AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (_) {
      // tetap keluar walau server tidak terjangkau
    }
    await _tokens.clear();
    user = null;
    status = AuthStatus.signedOut;
    notifyListeners();
  }

  /// Token ditolak server (kedaluwarsa/akun dinonaktifkan).
  void handleUnauthorized() {
    if (status != AuthStatus.signedIn) return;
    _tokens.clear();
    user = null;
    notice = 'Sesi Anda berakhir. Silakan login kembali.';
    status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final newToken = await _repo.changePassword(oldPassword, newPassword);
    if (newToken != null) await _tokens.write(newToken);
  }
}
