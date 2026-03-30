import 'supabase_bootstrap.dart';

class WorkoutRepository {
  Future<List<Map<String, dynamic>>> listWorkoutsAdmin() async {
    final data = await sb
        .from('v_workouts_detailed')
        .select('*')
        .order('workout_date', ascending: false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> listWorkoutsByDate(String dateIso) async {
    final data = await sb
        .from('v_workouts_detailed')
        .select('*')
        .eq('workout_date', dateIso)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> listRecentWorkouts() async {
    final data = await sb
        .from('v_workouts_detailed')
        .select('*')
        .order('workout_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> listPopularWorkouts() async {
    final data = await sb
        .from('v_workouts_detailed')
        .select('*')
        .order('popularity_score', ascending: false)
        .order('likes_count', ascending: false)
        .order('comments_count', ascending: false)
        .order('workout_date', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> listBenchmarkWorkouts() async {
    final data = await sb
        .from('v_workouts_detailed')
        .select('*')
        .eq('is_benchmark', true)
        .order('workout_date', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> searchExploreWorkouts({
    required String mode,
    String? query,
  }) async {
    final today = DateTime.now();
    final todayIso =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    var builder = sb
        .from('v_workouts_detailed')
        .select('*')
        .lte('workout_date', todayIso);

    final q = (query ?? '').trim();
    if (q.isNotEmpty) {
      builder = builder.or(
        'title.ilike.%$q%,description.ilike.%$q%,program_name.ilike.%$q%',
      );
    }

    if (mode == 'popular') {
      final data = await builder
          .order('popularity_score', ascending: false)
          .order('likes_count', ascending: false)
          .order('comments_count', ascending: false)
          .order('workout_date', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(data);
    }

    if (mode == 'benchmarks') {
      final data = await builder
          .eq('is_benchmark', true)
          .order('workout_date', ascending: false)
          .limit(50);
      return List<Map<String, dynamic>>.from(data);
    }

    final data = await builder
        .order('workout_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>?> findExistingWorkoutForProgramOnDate({
    required String gymId,
    required String programId,
    required String workoutDate,
    String? excludeWorkoutId,
  }) async {
    if (programId.trim().isEmpty) return null;

    dynamic query = sb
        .from('workouts')
        .select('id, title, workout_date, program_id')
        .eq('gym_id', gymId)
        .eq('program_id', programId)
        .eq('workout_date', workoutDate);

    if (excludeWorkoutId != null && excludeWorkoutId.trim().isNotEmpty) {
      query = query.neq('id', excludeWorkoutId.trim());
    }

    final data = await query.limit(1).maybeSingle();
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<int> autoAssignWorkoutToProgramClassesOnDate({
    required String gymId,
    required String programId,
    required String workoutId,
    required String workoutDate,
  }) async {
    if (programId.trim().isEmpty) return 0;

    final startIso = '${workoutDate.trim()}T00:00:00';
    final endIso = '${workoutDate.trim()}T23:59:59';

    final classes = await sb
        .from('v_classes_with_spots')
        .select('id, workout_id')
        .eq('gym_id', gymId)
        .eq('program_id', programId)
        .eq('status', 'scheduled')
        .gte('starts_at', startIso)
        .lte('starts_at', endIso)
        .order('starts_at', ascending: true);

    var assigned = 0;

    for (final raw in classes) {
      final item = Map<String, dynamic>.from(raw);
      final classId = (item['id'] ?? '').toString().trim();
      final currentWorkoutId = (item['workout_id'] ?? '').toString().trim();

      if (classId.isEmpty) continue;
      if (currentWorkoutId.isNotEmpty) continue;

      await assignWorkoutToClass(classId: classId, workoutId: workoutId);
      assigned++;
    }

    return assigned;
  }

  Future<String> createWorkout({
    required String gymId,
    String? programId,
    required String title,
    String? description,
    required String workoutDate,
    int? timeCapMinutes,
    String? workoutType,
    String? createdBy,
    String? imageUrl,
  }) async {
    final lower = title.toLowerCase();
    final benchmarkNames = [
      'fran',
      'murph',
      'annie',
      'angie',
      'cindy',
      'helen',
      'grace',
      'diane',
      'eva',
      'fight gone bad',
      'filthy fifty',
      'jackie',
      'karen',
      'nancy',
      'isabel',
      'chelsea',
      'amanda',
      'linda',
      'mary',
      'elizabeth',
    ];

    final isBenchmark = benchmarkNames.any((n) => lower.contains(n));

    final res = await sb
        .from('workouts')
        .insert({
          'gym_id': gymId,
          'program_id': (programId == null || programId.isEmpty)
              ? null
              : programId,
          'title': title,
          'description': description,
          'workout_date': workoutDate,
          'time_cap_minutes': timeCapMinutes,
          'workout_type': workoutType,
          'created_by': (createdBy == null || createdBy.isEmpty)
              ? null
              : createdBy,
          'image_url': (imageUrl == null || imageUrl.isEmpty) ? null : imageUrl,
          'is_benchmark': isBenchmark,
        })
        .select('id')
        .single();

    return res['id'].toString();
  }

  Future<void> updateWorkout({
    required String id,
    String? programId,
    required String title,
    String? description,
    required String workoutDate,
    int? timeCapMinutes,
    String? workoutType,
    String? imageUrl,
  }) async {
    final lower = title.toLowerCase();
    final benchmarkNames = [
      'fran',
      'murph',
      'annie',
      'angie',
      'cindy',
      'helen',
      'grace',
      'diane',
      'eva',
      'fight gone bad',
      'filthy fifty',
      'jackie',
      'karen',
      'nancy',
      'isabel',
      'chelsea',
      'amanda',
      'linda',
      'mary',
      'elizabeth',
    ];

    final isBenchmark = benchmarkNames.any((n) => lower.contains(n));

    await sb
        .from('workouts')
        .update({
          'program_id': (programId == null || programId.isEmpty)
              ? null
              : programId,
          'title': title,
          'description': description,
          'workout_date': workoutDate,
          'time_cap_minutes': timeCapMinutes,
          'workout_type': workoutType,
          'image_url': (imageUrl == null || imageUrl.isEmpty) ? null : imageUrl,
          'is_benchmark': isBenchmark,
        })
        .eq('id', id);
  }

  Future<void> deleteWorkout(String id) async {
    await sb.from('workouts').delete().eq('id', id);
  }

  Future<void> assignWorkoutToClass({
    required String classId,
    required String workoutId,
  }) async {
    await sb.rpc(
      'assign_workout_to_class',
      params: {'p_class_id': classId, 'p_workout_id': workoutId},
    );
  }
}
