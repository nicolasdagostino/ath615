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

  Future<List<Map<String, dynamic>>> adminNotifications() async {
    final data = await sb
        .from('notifications')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> createNotification({
    required String gymId,
    required String type,
    required String title,
    required String message,
    String recipientsScope = 'all_users',
    String status = 'draft',
    String? scheduledForIso,
  }) async {
    final user = sb.auth.currentUser;

    await sb.from('notifications').insert({
      'gym_id': gymId,
      'created_by': user?.id,
      'type': type,
      'status': status,
      'title': title,
      'message': message,
      'recipients_scope': recipientsScope,
      'scheduled_for': scheduledForIso,
    });
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
}
