import 'supabase_bootstrap.dart';

class OwnerRepository {
  Future<Map<String, dynamic>> createGym({
    required String name,
    required String slug,
  }) async {
    final res = await sb.functions.invoke(
      'create-gym',
      body: {
        'name': name,
        'slug': slug,
      },
    );

    final payload = res.data;

    if (res.status != 200) {
      if (payload is Map && payload['error'] != null) {
        throw Exception(payload['error'].toString());
      }
      throw Exception('Could not create gym');
    }

    return Map<String, dynamic>.from(payload as Map);
  }

  Future<List<Map<String, dynamic>>> listGyms() async {
    final rows = await sb
        .from('gyms')
        .select('id, name, slug, created_at')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> inviteGymAdmin({
    required String gymId,
    required String fullName,
    required String email,
  }) async {
    final res = await sb.functions.invoke(
      'owner-invite-gym-admin',
      body: {
        'gymId': gymId,
        'fullName': fullName,
        'email': email,
      },
    );

    final payload = res.data;

    if (res.status != 200) {
      if (payload is Map && payload['error'] != null) {
        throw Exception(payload['error'].toString());
      }
      throw Exception('Could not invite gym admin');
    }

    return Map<String, dynamic>.from(payload as Map);
  }
}
