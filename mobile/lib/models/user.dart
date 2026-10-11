import '../core/json.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    required this.isActive,
  });

  final int id;
  final String username;
  final String fullName;
  final String role;
  final bool isActive;

  bool get isOwner => role == 'OWNER';

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: asInt(j['id']),
        username: asStr(j['username']),
        fullName: asStr(j['full_name']),
        role: asStr(j['role']),
        isActive: j['is_active'] == null ? true : asBool(j['is_active']),
      );
}
