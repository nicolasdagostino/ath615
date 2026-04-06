import 'supabase_bootstrap.dart';

class GymRepository {
  Future<String?> myGymId() async {
    try {
      final data = await sb.rpc('my_gym_id');
      if (data != null && data.toString().isNotEmpty) {
        return data.toString();
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

        final gymId = profile?['gym_id']?.toString();
        if (gymId != null && gymId.isNotEmpty) {
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

  Future<String?> myGymName() async {
    final gymId = await myGymId();
    if (gymId == null || gymId.isEmpty) return null;

    try {
      final data = await sb
          .from('gyms')
          .select('name')
          .eq('id', gymId)
          .limit(1)
          .maybeSingle();

      final name = data?['name']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    } catch (_) {}

    return null;
  }

  Future<String?> resolveGymId() async {
    final mine = await myGymId();
    if (mine != null && mine.isNotEmpty) return mine;

    return null;
  }
}
