import 'supabase_bootstrap.dart';

class AdminMemberCreateResult {
  final bool resent;

  const AdminMemberCreateResult({required this.resent});

  factory AdminMemberCreateResult.fromMap(dynamic data) {
    if (data is Map) {
      return AdminMemberCreateResult(resent: data['resent'] == true);
    }
    return const AdminMemberCreateResult(resent: false);
  }
}

class AdminMemberRepository {
  Future<AdminMemberCreateResult> createMember({
    required String fullName,
    required String email,
    required String role,
    String? phone,
    String? dateOfBirth,
    String? notes,
    bool isActive = true,
  }) async {
    final session = sb.auth.currentSession;
    if (session == null) {
      throw Exception('No active session found.');
    }

    final res = await sb.functions.invoke(
      'admin-create-member',
      body: {
        'fullName': fullName,
        'email': email,
        'role': role,
        'phone': phone,
        'dateOfBirth': dateOfBirth,
        'notes': notes,
        'isActive': isActive,
      },
    );

    final data = res.data;

    if (res.status != 200) {
      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }
      throw Exception('No se pudo crear el miembro.');
    }

    return AdminMemberCreateResult.fromMap(data);
  }
}
