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
    Map<String, dynamic>? metadata,
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
          'metadata': metadata ?? <String, dynamic>{},
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
    required String workoutId,
    required String workoutTitle,
    required String workoutDate,
    String? programId,
    String? programName,
  }) async {
    if (gymId.trim().isEmpty || workoutDate.trim().isEmpty) return;

    final now = DateTime.now();
    final todayIso =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final isToday = workoutDate.trim() == todayIso;
    final parts = workoutDate.trim().split('-');
    final scheduledIso = parts.length == 3
        ? DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          ).toUtc().toIso8601String()
        : '${workoutDate.trim()}T00:00:00';
    final cleanProgramName = (programName ?? '').trim();
    final hasProgram = cleanProgramName.isNotEmpty;
    final cleanWorkoutTitle = workoutTitle.trim();

    final title = hasProgram
        ? '$cleanProgramName workout is ready'
        : "Today's workout is ready";

    final message = cleanWorkoutTitle.isEmpty
        ? (hasProgram
              ? "Check today's $cleanProgramName WOD"
              : "Check today's WOD")
        : (hasProgram
              ? "Today's $cleanProgramName WOD is '$cleanWorkoutTitle'"
              : "Today's WOD is '$cleanWorkoutTitle'");

    final existing = await sb
        .from('notifications')
        .select('id')
        .eq('gym_id', gymId)
        .eq('type', 'announcement')
        .contains('metadata', {
          'pushType': 'workout_published',
          'workoutDate': workoutDate.trim(),
          if (hasProgram) 'programName': cleanProgramName,
        })
        .limit(1);

    if (existing.isNotEmpty) {
      return; // ⛔ already sent
    }

    final id = await createNotification(
      gymId: gymId,
      type: 'announcement',
      title: title,
      message: message,
      recipientsScope: 'all_users',
      status: isToday ? 'draft' : 'scheduled',
      scheduledForIso: scheduledIso,
      metadata: {
        'pushType': 'workout_published',
        'workoutId': workoutId,
        'programId': (programId ?? '').trim(),
        'programName': cleanProgramName,
        'workoutTitle': cleanWorkoutTitle,
        'workoutDate': workoutDate.trim(),
      },
    );

    if (isToday) {
      await publishNotification(id);
    }
  }
}
