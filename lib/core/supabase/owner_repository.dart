import 'supabase_bootstrap.dart';

class OwnerRepository {
  Future<dynamic> _invokeOwnerFunction(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    Future<dynamic> callWithToken(String accessToken) {
      return sb.functions.invoke(
        functionName,
        body: body,
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    }

    final currentSession = sb.auth.currentSession;
    if (currentSession == null) {
      throw Exception('User not authenticated');
    }

    dynamic res = await callWithToken(currentSession.accessToken);

    final status = res.status;
    final payload = res.data;

    final invalidJwt =
        status == 401 &&
        payload is Map &&
        (payload['message']?.toString().toLowerCase().contains('invalid jwt') ==
                true ||
            payload['error']?.toString().toLowerCase().contains(
                  'invalid jwt',
                ) ==
                true);

    if (!invalidJwt) {
      return res;
    }

    final refreshed = await sb.auth.refreshSession();
    final freshSession = refreshed.session ?? sb.auth.currentSession;

    if (freshSession == null) {
      throw Exception('User not authenticated');
    }

    return await callWithToken(freshSession.accessToken);
  }

  Future<Map<String, dynamic>> createGym({
    required String name,
    required String slug,
  }) async {
    final res = await _invokeOwnerFunction(
      'create-gym',
      body: {'name': name, 'slug': slug},
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

  Future<List<Map<String, dynamic>>> listGymMetrics() async {
    final res = await _invokeOwnerFunction('owner-list-gym-metrics');

    final payload = res.data;

    if (res.status != 200) {
      if (payload is Map && payload['error'] != null) {
        throw Exception(payload['error'].toString());
      }
      throw Exception('Could not load gym metrics');
    }

    final map = Map<String, dynamic>.from(payload as Map);
    final items = (map['items'] as List?) ?? const [];
    return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> listGyms() async {
    final rows = await sb
        .from('gyms')
        .select(
          'id, name, slug, created_at, is_active, is_blocked, blocked_reason, blocked_at, deleted_at',
        )
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> inviteGymAdmin({
    required String gymId,
    required String fullName,
    required String email,
  }) async {
    final res = await _invokeOwnerFunction(
      'owner-invite-gym-admin',
      body: {'gymId': gymId, 'fullName': fullName, 'email': email},
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

  Future<Map<String, dynamic>> updateGymStatus({
    required String gymId,
    required String action,
    String? reason,
  }) async {
    final res = await _invokeOwnerFunction(
      'owner-update-gym-status',
      body: {'gymId': gymId, 'action': action, 'reason': reason},
    );

    final payload = res.data;

    if (res.status != 200) {
      if (payload is Map && payload['error'] != null) {
        throw Exception(payload['error'].toString());
      }
      throw Exception('Could not update gym status');
    }

    return Map<String, dynamic>.from(payload as Map);
  }

  Future<Map<String, dynamic>> seedTestAthletes({
    required String gymId,
    int count = 10,
    String password = 'Prueba5-',
  }) async {
    final res = await _invokeOwnerFunction(
      'owner-seed-test-athletes',
      body: {'gymId': gymId, 'count': count, 'password': password},
    );

    final payload = res.data;

    if (res.status != 200) {
      if (payload is Map && payload['error'] != null) {
        throw Exception(payload['error'].toString());
      }
      throw Exception('Could not seed test athletes');
    }

    return Map<String, dynamic>.from(payload as Map);
  }
}
