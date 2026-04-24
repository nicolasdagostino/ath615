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

  Future<bool> hasLinkedItems({
    required String gymId,
    required String id,
  }) async {
    final workouts = await sb
        .from('workouts')
        .select('id')
        .eq('gym_id', gymId)
        .eq('program_id', id)
        .limit(1);

    if (workouts.isNotEmpty) return true;

    final classes = await sb
        .from('classes')
        .select('id')
        .eq('gym_id', gymId)
        .eq('program_id', id)
        .limit(1);

    return classes.isNotEmpty;
  }

  Future<void> deleteProgram({
    required String gymId,
    required String id,
  }) async {
    final linked = await hasLinkedItems(gymId: gymId, id: id);
    if (linked) {
      throw Exception('PROGRAM_HAS_LINKED_ITEMS');
    }

    await sb.from('programs').delete().eq('id', id).eq('gym_id', gymId);
  }
}
