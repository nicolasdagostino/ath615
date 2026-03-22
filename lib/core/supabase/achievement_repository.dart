import 'supabase_bootstrap.dart';

class AchievementRepository {
  Future<List<Map<String, dynamic>>> myPrs() async {
    final user = sb.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final data = await sb
        .from('personal_records')
        .select()
        .eq('member_id', user.id)
        .order('achieved_on', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> createPr({
    required String category,
    required String movement,
    num? value,
    String? unit,
    String? scoreText,
    required String achievedOn,
    String? notes,
  }) async {
    final user = sb.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await sb.from('personal_records').insert({
      'member_id': user.id,
      'category': category,
      'movement': movement,
      'value': value,
      'unit': unit,
      'score_text': scoreText,
      'achieved_on': achievedOn,
      'notes': notes,
    });
  }

  Future<void> updatePr({
    required String id,
    String? category,
    String? movement,
    num? value,
    String? unit,
    String? scoreText,
    String? achievedOn,
    String? notes,
  }) async {
    final payload = <String, dynamic>{};

    if (category != null) payload['category'] = category;
    if (movement != null) payload['movement'] = movement;
    payload['value'] = value;
    payload['unit'] = unit;
    payload['score_text'] = scoreText;
    if (achievedOn != null) payload['achieved_on'] = achievedOn;
    payload['notes'] = notes;

    await sb.from('personal_records').update(payload).eq('id', id);
  }

  Future<void> deletePr(String id) async {
    await sb.from('personal_records').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> myAchievements() async {
    final user = sb.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final data = await sb
        .from('member_achievements')
        .select()
        .eq('member_id', user.id)
        .order('awarded_on', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> myStats() async {
    final user = sb.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final prs = await myPrs();
    final achievements = await myAchievements();

    final attended = await sb
        .from('class_bookings')
        .select('id')
        .eq('member_id', user.id)
        .eq('status', 'attended');

    final strengthCount = prs.where((e) {
      return (e['category'] ?? '').toString().toLowerCase() == 'strength';
    }).length;

    return {
      'classes_count': attended.length,
      'prs_count': prs.length,
      'strength_count': strengthCount,
      'milestones_count': achievements.length,
    };
  }
}
