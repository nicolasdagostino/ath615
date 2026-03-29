import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../supabase/device_token_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('PUSH BG messageId=${message.messageId} data=${message.data}');
}

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      await _requestPermissions();
      await FirebaseMessaging.instance.setAutoInitEnabled(true);

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          'PUSH FG title=${message.notification?.title} data=${message.data}',
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
          'PUSH OPENED title=${message.notification?.title} data=${message.data}',
        );
      });

      unawaited(_logTokenWhenReady());
    } catch (e, st) {
      debugPrint('PUSH initialize error=$e');
      debugPrint('$st');
    }
  }

  static Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    debugPrint('PUSH permission=${settings.authorizationStatus}');
  }

  static Future<void> _logTokenWhenReady() async {
    try {
      final repo = DeviceTokenRepository();
      String? apnsToken;

      for (var i = 0; i < 12; i++) {
        apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty) {
          debugPrint('PUSH APNS token=$apnsToken');
          break;
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }

      if (apnsToken == null || apnsToken.isEmpty) {
        debugPrint('PUSH APNS token still not available yet.');
        return;
      }

      final fcmToken = await _messaging.getToken();
      debugPrint('PUSH FCM token=$fcmToken');

      if (fcmToken != null && fcmToken.isNotEmpty) {
        try {
          await repo.upsertCurrentUserToken(fcmToken);
          debugPrint('PUSH token saved to Supabase');
        } catch (e) {
          debugPrint('PUSH token save error=$e');
        }
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        debugPrint('PUSH refreshed FCM token=$token');
        try {
          await repo.upsertCurrentUserToken(token);
          debugPrint('PUSH refreshed token saved to Supabase');
        } catch (e) {
          debugPrint('PUSH refreshed token save error=$e');
        }
      });
    } catch (e, st) {
      debugPrint('PUSH token fetch error=$e');
      debugPrint('$st');
    }
  }

  static Future<String?> currentToken() async {
    try {
      return _messaging.getToken();
    } catch (e) {
      debugPrint('PUSH currentToken error=$e');
      return null;
    }
  }
}
