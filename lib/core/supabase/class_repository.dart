import 'supabase_bootstrap.dart';

class ClassRepository {
  Future<List<Map<String, dynamic>>> listClassesAdmin() async {
    final now = DateTime.now();
    final startIso = now
        .toUtc()
        .subtract(const Duration(days: 7))
        .toIso8601String();
    final endIso = now.toUtc().add(const Duration(days: 7)).toIso8601String();

    final data = await sb
        .from('v_classes_with_spots')
        .select('*')
        .gte('starts_at', startIso)
        .lte('starts_at', endIso)
        .order('starts_at', ascending: true)
        .limit(300);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> listClassesForDate(
    String dateIso, {
    bool includePast = false,
  }) async {
    final now = DateTime.now();
    final todayIso =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (!includePast && dateIso.compareTo(todayIso) < 0) {
      return [];
    }

    final targetDate = DateTime.tryParse('${dateIso}T00:00:00');
    if (targetDate == null) return [];

    final rangeStart = targetDate.subtract(const Duration(days: 1)).toUtc();
    final rangeEnd = targetDate.add(const Duration(days: 2)).toUtc();

    final data = await sb
        .from('v_classes_with_spots')
        .select('*')
        .eq('status', 'scheduled')
        .gte('starts_at', rangeStart.toIso8601String())
        .lte('starts_at', rangeEnd.toIso8601String())
        .order('starts_at', ascending: true);

    String localDateIso(DateTime value) {
      final local = value.toLocal();
      final y = local.year.toString().padLeft(4, '0');
      final m = local.month.toString().padLeft(2, '0');
      final d = local.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }

    final items = List<Map<String, dynamic>>.from(data).where((item) {
      final startsAtRaw = (item['starts_at'] ?? '').toString().trim();
      final startsAt = DateTime.tryParse(startsAtRaw);
      if (startsAt == null) return false;

      if (localDateIso(startsAt) != dateIso) return false;
      if (!includePast &&
          dateIso == todayIso &&
          startsAt.toLocal().isBefore(now)) {
        return false;
      }
      return true;
    }).toList();

    return items;
  }

  Future<void> createClass({
    required String gymId,
    required String programId,
    String? coachId,
    String? title,
    String? description,
    required String startsAtIso,
    required int durationMinutes,
    required int maxSpots,
    String? location,
  }) async {
    final inserted = await sb
        .from('classes')
        .insert({
          'gym_id': gymId,
          'program_id': programId,
          'coach_id': (coachId == null || coachId.isEmpty) ? null : coachId,
          'title': title,
          'description': description,
          'starts_at': startsAtIso,
          'duration_minutes': durationMinutes,
          'max_spots': maxSpots,
          'location': location,
          'status': 'scheduled',
        })
        .select('id, starts_at')
        .single();

    final classId = inserted['id'].toString();
    final startsAt = DateTime.parse(inserted['starts_at'].toString()).toLocal();

    final workoutDate =
        '${startsAt.year.toString().padLeft(4, '0')}-${startsAt.month.toString().padLeft(2, '0')}-${startsAt.day.toString().padLeft(2, '0')}';

    // 🔍 buscar workout existente para ese día + programa
    final existingWorkout = await sb
        .from('workouts')
        .select('id')
        .eq('gym_id', gymId)
        .eq('program_id', programId)
        .eq('workout_date', workoutDate)
        .maybeSingle();

    if (existingWorkout != null) {
      final workoutId = existingWorkout['id'].toString();

      await sb
          .from('classes')
          .update({'workout_id': workoutId})
          .eq('id', classId);
    }
  }

  Future<void> updateClass({
    required String id,
    required String programId,
    String? coachId,
    required String title,
    required String description,
    required String startsAtIso,
    required int durationMinutes,
    required int maxSpots,
    required String location,
    required String status,
  }) async {
    await sb
        .from('classes')
        .update({
          'program_id': programId,
          'coach_id': (coachId == null || coachId.isEmpty) ? null : coachId,
          'title': title,
          'description': description,
          'starts_at': startsAtIso,
          'duration_minutes': durationMinutes,
          'max_spots': maxSpots,
          'location': location,
          'status': status,
        })
        .eq('id', id);
  }

  Future<void> deleteClass(String id) async {
    await sb.from('classes').delete().eq('id', id);
  }

  Future<void> createRecurringClasses({
    required String gymId,
    required String programId,
    String? coachId,
    required List<int> weekdays,
    required List<String> times,
    required String startDate,
    required String endDate,
    required int durationMinutes,
    required int maxSpots,
    String timezone = 'Europe/Madrid',
  }) async {
    final result = await sb.rpc(
      'create_recurring_classes',
      params: {
        'p_gym_id': gymId,
        'p_program_id': programId,
        'p_coach_id': (coachId == null || coachId.isEmpty) ? null : coachId,
        'p_weekdays': weekdays,
        'p_times': times,
        'p_start_date': startDate,
        'p_end_date': endDate,
        'p_duration_minutes': durationMinutes,
        'p_max_spots': maxSpots,
        'p_timezone': timezone,
      },
    );

    final ok = result['ok'] == true;
    if (!ok) {
      throw Exception(
        (result['message'] ?? 'Could not create recurring classes').toString(),
      );
    }
  }

  Future<int> deleteFutureClassesForProgramSlot(String classId) async {
    final result = await sb.rpc(
      'admin_delete_future_classes_for_program_slot',
      params: {'p_class_id': classId},
    );

    final ok = result['ok'] == true;
    if (!ok) {
      throw Exception(
        (result['message'] ?? 'Could not delete future classes').toString(),
      );
    }

    final deletedCount = result['deleted_count'];
    if (deletedCount is int) return deletedCount;
    return int.tryParse(deletedCount.toString()) ?? 0;
  }

  Future<void> bookClass(String classId) async {
    final user = sb.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final result = await sb.rpc(
      'book_class_for_member',
      params: {'p_class_id': classId, 'p_member_id': user.id},
    );

    final ok = result['ok'] == true;
    if (!ok) {
      throw Exception((result['message'] ?? 'Could not book class').toString());
    }
  }
}
