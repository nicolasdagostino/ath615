import 'supabase_bootstrap.dart';

class NotificationRepository {
  Future<List<Map<String, dynamic>>> myNotifications() async {
    final user = sb.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final data = await sb
        .from('user_notifications')
        .select('*, notifications(*)')
        .eq('member_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> markAsRead(String userNotificationId) async {
    await sb
        .from('user_notifications')
        .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('id', userNotificationId);
  }

  Future<List<Map<String, dynamic>>> adminNotifications({String? gymId}) async {
    dynamic query = sb.from('notifications').select();

    if (gymId != null && gymId.trim().isNotEmpty) {
      query = query.eq('gym_id', gymId.trim());
    }

    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<String> createNotification({
    required String gymId,
    required String type,
    required String title,
    required String message,
    String recipientsScope = 'all_users',
    String status = 'draft',
    String? scheduledForIso,
  }) async {
    final user = sb.auth.currentUser;

    final res = await sb
        .from('notifications')
        .insert({
          'gym_id': gymId,
          'created_by': user?.id,
          'type': type,
          'status': status,
          'title': title,
          'message': message,
          'recipients_scope': recipientsScope,
          'scheduled_for': scheduledForIso,
        })
        .select()
        .single();

    return res['id'].toString();
  }

  Future<void> updateNotification({
    required String id,
    String? type,
    String? status,
    String? title,
    String? message,
    String? recipientsScope,
    String? scheduledForIso,
  }) async {
    final payload = <String, dynamic>{};

    if (type != null) payload['type'] = type;
    if (status != null) payload['status'] = status;
    if (title != null) payload['title'] = title;
    if (message != null) payload['message'] = message;
    if (recipientsScope != null) payload['recipients_scope'] = recipientsScope;
    if (scheduledForIso != null) payload['scheduled_for'] = scheduledForIso;

    await sb.from('notifications').update(payload).eq('id', id);
  }

  Future<void> deleteNotification(String id) async {
    await sb.from('notifications').delete().eq('id', id);
  }

  Future<void> publishNotification(String id) async {
    final res = await sb.functions.invoke(
      'publish-notification',
      body: {'notificationId': id},
    );

    if (res.status != 200) {
      final payload = res.data;
      if (payload is Map && payload['error'] != null) {
        throw Exception(payload['error'].toString());
      }
      throw Exception('Failed to publish notification');
    }
  }

  // 🔥 NUEVA LÓGICA CORRECTA
  Future<void> publishWorkoutNotificationIfNeeded({
    required String gymId,
    required String workoutTitle,
    required String workoutDate,
  }) async {
    if (gymId.trim().isEmpty || workoutDate.trim().isEmpty) return;

    final now = DateTime.now();
    final todayIso =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final isToday = workoutDate.trim() == todayIso;
    final scheduledIso = '${workoutDate.trim()}T00:00:00';

    final title = "Today's workout is ready";
    final message = workoutTitle.trim().isEmpty
        ? "Check today's WOD"
        : "Today's WOD is '$workoutTitle'";

    final id = await createNotification(
      gymId: gymId,
      type: 'announcement',
      title: title,
      message: message,
      recipientsScope: 'all_users',
      status: isToday ? 'draft' : 'scheduled',
      scheduledForIso: scheduledIso,
    );

    if (isToday) {
      await publishNotification(id);
    }
  }
}
