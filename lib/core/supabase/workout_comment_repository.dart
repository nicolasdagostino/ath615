import 'supabase_bootstrap.dart';

class WorkoutCommentRepository {
  Future<List<Map<String, dynamic>>> listCommentsForWorkout(
    String workoutId,
  ) async {
    final data = await sb
        .from('v_workout_comments_detailed')
        .select('*')
        .eq('workout_id', workoutId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> createComment({
    required String workoutId,
    required String comment,
  }) async {
    final user = sb.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    if (comment.trim().isEmpty) throw Exception('Comment cannot be empty');

    await sb.from('workout_comments').insert({
      'workout_id': workoutId,
      'user_id': user.id,
      'comment': comment.trim(),
    });
  }

  Future<void> deleteComment(String commentId) async {
    await sb.from('workout_comments').delete().eq('id', commentId);
  }
}
