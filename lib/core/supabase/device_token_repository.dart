import 'dart:io' show Platform;

import 'supabase_bootstrap.dart';

class DeviceTokenRepository {
  Future<void> upsertCurrentUserToken(String token) async {
    final user = sb.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');
    if (token.trim().isEmpty) throw Exception('Empty device token');

    final platform = Platform.isIOS
        ? 'ios'
        : Platform.isAndroid
        ? 'android'
        : 'unknown';

    final existing = await sb
        .from('device_tokens')
        .select('id')
        .eq('member_id', user.id)
        .eq('token', token.trim())
        .maybeSingle();

    if (existing != null && existing['id'] != null) {
      await sb
          .from('device_tokens')
          .update({
            'platform': platform,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing['id']);
      return;
    }

    await sb.from('device_tokens').insert({
      'member_id': user.id,
      'token': token.trim(),
      'platform': platform,
    });
  }
}
