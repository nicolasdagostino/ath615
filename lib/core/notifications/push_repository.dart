import '../supabase/supabase_bootstrap.dart';

class PushRepository {
  Future<Map<String, dynamic>> sendPushToUsers({
    required List<String> userIds,
    required String title,
    required String message,
    Map<String, String> data = const {},
  }) async {
    final res = await sb.functions.invoke(
      'send-push',
      body: {
        'userIds': userIds,
        'title': title,
        'message': message,
        'data': data,
      },
    );

    final payload = res.data;

    if (res.status != 200) {
      if (payload is Map && payload['error'] != null) {
        throw Exception(payload['error'].toString());
      }
      throw Exception('Could not send push');
    }

    return Map<String, dynamic>.from(payload as Map);
  }
}
