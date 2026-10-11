import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/errors.dart';
import 'local_settings.dart';
import 'token_storage.dart';

/// Klien HTTP ke backend terpusat. Semua data bisnis berasal dari server.
class ApiClient {
  ApiClient({required this.settings, required this.tokens, http.Client? client})
      : _http = client ?? http.Client();

  final LocalSettings settings;
  final TokenStorage tokens;
  final http.Client _http;

  /// Dipanggil saat server menolak token (401) pada permintaan yang membawa token.
  void Function()? onUnauthorized;

  static const Duration _timeout = Duration(seconds: 25);

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(settings.serverUrl);
    final basePath = base.path.replaceAll(RegExp(r'/+$'), '');
    final params = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.toString().isNotEmpty) params[k] = v.toString();
    });
    return base.replace(path: '$basePath$path', queryParameters: params.isEmpty ? null : params);
  }

  Future<Map<String, String>> _headers({bool json = true}) async {
    final h = <String, String>{'Accept': 'application/json'};
    if (json) h['Content-Type'] = 'application/json; charset=utf-8';
    final token = await tokens.read();
    if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
    return h;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => _send('GET', path, query: query);
  Future<dynamic> post(String path, {Object? body}) => _send('POST', path, body: body);
  Future<dynamic> patch(String path, {Object? body}) => _send('PATCH', path, body: body);
  Future<dynamic> put(String path, {Object? body}) => _send('PUT', path, body: body);

  Future<dynamic> _send(String method, String path, {Map<String, dynamic>? query, Object? body}) async {
    try {
      final request = http.Request(method, _uri(path, query));
      final headers = await _headers();
      request.headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _http.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      return _handle(response, hadToken: headers.containsKey('Authorization'), path: path);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Server tidak merespons. Periksa koneksi lalu coba lagi.');
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server. Periksa jaringan atau alamat server.');
    } on HandshakeException {
      throw ApiException('Koneksi aman ke server gagal. Periksa alamat/sertifikat server.');
    } on http.ClientException {
      throw ApiException('Tidak dapat terhubung ke server. Periksa jaringan atau alamat server.');
    } on FormatException {
      throw ApiException('Alamat server tidak valid atau respons server tidak dikenali.');
    }
  }

  /// Unduh berkas (PDF/Excel laporan).
  Future<Uint8List> download(String path, {Map<String, dynamic>? query}) async {
    try {
      final headers = await _headers(json: false);
      final response = await _http.get(_uri(path, query), headers: headers).timeout(const Duration(seconds: 60));
      if (response.statusCode >= 200 && response.statusCode < 300) return response.bodyBytes;
      _throwFor(response, hadToken: headers.containsKey('Authorization'), path: path);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Server tidak merespons. Periksa koneksi lalu coba lagi.');
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server. Periksa jaringan atau alamat server.');
    } on http.ClientException {
      throw ApiException('Tidak dapat terhubung ke server. Periksa jaringan atau alamat server.');
    }
  }

  dynamic _handle(http.Response res, {required bool hadToken, required String path}) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    _throwFor(res, hadToken: hadToken, path: path);
  }

  Never _throwFor(http.Response res, {required bool hadToken, required String path}) {
    var message = 'Terjadi kesalahan. Silakan coba lagi.';
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map && decoded['detail'] is String) message = decoded['detail'] as String;
    } catch (_) {
      // body bukan JSON: pakai pesan umum
    }
    if (res.statusCode >= 500) message = 'Terjadi kesalahan pada server. Silakan coba lagi.';
    if (res.statusCode == 401 && hadToken && path != '/api/auth/login') {
      onUnauthorized?.call();
    }
    throw ApiException(message, statusCode: res.statusCode);
  }
}
