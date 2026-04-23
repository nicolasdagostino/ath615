import 'supabase_bootstrap.dart';

class GymRepository {
  static String? _cachedGymId;
  static Map<String, dynamic>? _cachedGymInfo;

  void invalidateCache() {
    _cachedGymId = null;
    _cachedGymInfo = null;
  }

  Future<String?> myGymId() async {
    final cached = _cachedGymId?.trim();
    if (cached != null && cached.isNotEmpty) return cached;
    try {
      final data = await sb.rpc('my_gym_id');
      if (data != null && data.toString().isNotEmpty) {
        final resolved = data.toString().trim();
        if (resolved.isNotEmpty) {
          _cachedGymId = resolved;
          return resolved;
        }
      }
    } catch (_) {}

    try {
      final user = sb.auth.currentUser;
      if (user != null) {
        final profile = await sb
            .from('profiles')
            .select('gym_id')
            .eq('id', user.id)
            .maybeSingle();

        final gymId = profile?['gym_id']?.toString().trim();
        if (gymId != null && gymId.isNotEmpty) {
          _cachedGymId = gymId;
          return gymId;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<String?> firstGymId() async {
    try {
      final data = await sb.from('gyms').select('id').limit(1).maybeSingle();

      final id = data?['id']?.toString();
      if (id != null && id.isNotEmpty) {
        return id;
      }
    } catch (_) {}

    return null;
  }

  Future<String?> gymIdBySlug(String slug) async {
    try {
      final data = await sb
          .from('gyms')
          .select('id')
          .eq('slug', slug)
          .limit(1)
          .maybeSingle();

      final id = data?['id']?.toString();
      if (id != null && id.isNotEmpty) {
        return id;
      }
    } catch (_) {}

    return null;
  }

  Future<Map<String, dynamic>?> myGymInfo() async {
    if (_cachedGymInfo != null) {
      return Map<String, dynamic>.from(_cachedGymInfo!);
    }

    final gymId = await myGymId();
    if (gymId == null || gymId.isEmpty) return null;

    try {
      final data = await sb
          .from('gyms')
          .select('id, name, logo_url')
          .eq('id', gymId)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;

      final mapped = Map<String, dynamic>.from(data);
      _cachedGymInfo = mapped;
      final resolvedId = (mapped['id'] ?? '').toString().trim();
      if (resolvedId.isNotEmpty) {
        _cachedGymId = resolvedId;
      }
      return Map<String, dynamic>.from(mapped);
    } catch (_) {
      return null;
    }
  }

  Future<String?> myGymName() async {
    final gym = await myGymInfo();
    final name = (gym?['name'] ?? '').toString().trim();
    return name.isEmpty ? null : name;
  }

  Future<void> updateGym({
    required String gymId,
    String? name,
    String? logoUrl,
  }) async {
    final payload = <String, dynamic>{};

    if (name != null) {
      payload['name'] = name.trim();
    }
    if (logoUrl != null) {
      payload['logo_url'] = logoUrl.trim().isEmpty ? null : logoUrl.trim();
    }
    if (payload.isEmpty) return;

    final rows = await sb
        .from('gyms')
        .update(payload)
        .eq('id', gymId)
        .select('id, name, logo_url');

    if (rows.isEmpty) {
      throw Exception('Could not update gym');
    }

    final updated = Map<String, dynamic>.from(rows.first);
    _cachedGymId = (updated['id'] ?? gymId).toString().trim();
    _cachedGymInfo = updated;
  }

  Future<Map<String, dynamic>?> myGymStatus() async {
    final gymId = await myGymId();
    if (gymId == null || gymId.isEmpty) return null;

    try {
      final data = await sb
          .from('gyms')
          .select(
            'id, name, slug, is_active, is_blocked, blocked_reason, blocked_at, deleted_at',
          )
          .eq('id', gymId)
          .limit(1)
          .maybeSingle();

      return data == null ? null : Map<String, dynamic>.from(data);
    } catch (_) {
      return null;
    }
  }

  Future<String?> resolveGymId() async {
    final mine = await myGymId();
    if (mine != null && mine.isNotEmpty) return mine;

    return null;
  }
}
