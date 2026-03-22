import 'supabase_bootstrap.dart';

class WorkoutLikeRepository {
  Future<bool> hasLiked(String workoutId) async {
    final user = sb.auth.currentUser;
    if (user == null) return false;

    final data = await sb
        .from('workout_likes')
        .select('workout_id')
        .eq('workout_id', workoutId)
        .eq('user_id', user.id)
        .maybeSingle();

    return data != null;
  }

  Future<void> toggleLike(String workoutId) async {
    final user = sb.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final existing = await sb
        .from('workout_likes')
        .select('workout_id')
        .eq('workout_id', workoutId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) {
      await sb
          .from('workout_likes')
          .delete()
          .eq('workout_id', workoutId)
          .eq('user_id', user.id);
    } else {
      await sb.from('workout_likes').insert({
        'workout_id': workoutId,
        'user_id': user.id,
      });
    }
  }
}
