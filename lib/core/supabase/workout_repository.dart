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
    var builder = sb.from('v_workouts_detailed').select('*');

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

  Future<void> createWorkout({
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

    await sb.from('workouts').insert({
      'gym_id': gymId,
      'program_id': (programId == null || programId.isEmpty) ? null : programId,
      'title': title,
      'description': description,
      'workout_date': workoutDate,
      'time_cap_minutes': timeCapMinutes,
      'workout_type': workoutType,
      'created_by': (createdBy == null || createdBy.isEmpty) ? null : createdBy,
      'image_url': (imageUrl == null || imageUrl.isEmpty) ? null : imageUrl,
      'is_benchmark': isBenchmark,
    });
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
