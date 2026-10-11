import '../core/json.dart';
import '../models/reports.dart';
import '../models/user.dart';
import '../services/api_client.dart';

class AuditLogPage {
  const AuditLogPage({required this.total, required this.items});

  final int total;
  final List<AuditLog> items;
}

class AdminRepository {
  AdminRepository(this._api);

  final ApiClient _api;

  Future<List<AppUser>> users() async =>
      asList(await _api.get('/api/users')).map((e) => AppUser.fromJson(asMap(e))).toList();

  Future<AppUser> createCashier({required String username, required String fullName, required String password}) async =>
      AppUser.fromJson(asMap(await _api
          .post('/api/users', body: {'username': username, 'full_name': fullName, 'password': password})));

  Future<AppUser> updateCashier(int id, {String? fullName, String? password, bool? isActive}) async {
    final body = <String, dynamic>{
      if (fullName != null) 'full_name': fullName,
      if (password != null && password.isNotEmpty) 'password': password,
      if (isActive != null) 'is_active': isActive,
    };
    return AppUser.fromJson(asMap(await _api.patch('/api/users/$id', body: body)));
  }

  Future<AuditLogPage> auditLogs({String q = '', String action = '', int limit = 50, int offset = 0}) async {
    final j = asMap(await _api
        .get('/api/audit-logs', query: {'q': q, 'action': action, 'limit': limit, 'offset': offset}));
    return AuditLogPage(
        total: asInt(j['total']), items: asList(j['items']).map((e) => AuditLog.fromJson(asMap(e))).toList());
  }

  Future<int> nextSequence() async => asInt(asMap(await _api.get('/api/settings/numbering'))['next_sequence']);

  Future<int> setNextSequence(int value) async =>
      asInt(asMap(await _api.put('/api/settings/numbering', body: {'next_sequence': value}))['next_sequence']);
}
