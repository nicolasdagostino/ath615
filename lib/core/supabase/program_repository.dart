import 'supabase_bootstrap.dart';

class ProgramRepository {
  Future<List<Map<String, dynamic>>> listPrograms(String gymId) async {
    final data = await sb
        .from('programs')
        .select('*')
        .eq('gym_id', gymId)
        .order('name', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> createProgram({
    required String gymId,
    required String name,
    String? description,
    String? colorHex,
  }) async {
    await sb.from('programs').insert({
      'gym_id': gymId,
      'name': name,
      'description': description,
      'color_hex': colorHex,
    });
  }

  Future<void> updateProgram({
    required String gymId,
    required String id,
    required String name,
    String? description,
    String? colorHex,
  }) async {
    await sb
        .from('programs')
        .update({
          'name': name,
          'description': description,
          'color_hex': colorHex,
        })
        .eq('id', id)
        .eq('gym_id', gymId);
  }

  Future<void> deleteProgram({
    required String gymId,
    required String id,
  }) async {
    await sb.from('programs').delete().eq('id', id).eq('gym_id', gymId);
  }
}
