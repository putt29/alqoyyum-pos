class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Pesan ramah untuk ditampilkan ke pengguna.
String errorMessage(Object? error) {
  if (error is ApiException) return error.message;
  return 'Terjadi kesalahan. Silakan coba lagi.';
}
