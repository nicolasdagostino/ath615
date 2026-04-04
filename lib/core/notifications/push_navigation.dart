import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/auth/auth_gate.dart';
import 'notification_intent.dart';
import 'notification_intent_store.dart';
import '../supabase/auth_deep_link_handler.dart';

class PushNavigation {
  PushNavigation._();

  static GlobalKey<NavigatorState> get navigatorKey =>
      AuthDeepLinkHandler.navigatorKey;

  static Future<NavigatorState?> _navigatorWhenReady() async {
    for (var i = 0; i < 20; i++) {
      final nav = navigatorKey.currentState;
      if (nav != null) return nav;
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    return navigatorKey.currentState;
  }

  static Future<void> handleMessageData(Map<String, dynamic> data) async {
    final rawType = (data['type'] ?? data['pushType'] ?? '').toString().trim();
    final type = rawType.toLowerCase();
    final workoutId = (data['workoutId'] ?? '').toString().trim();

    final nav = await _navigatorWhenReady();
    if (nav == null) return;

    if ((type == 'workout_published' || type == 'workout_comment_reminder') &&
        workoutId.isNotEmpty) {
      NotificationIntentStore.set(
        NotificationIntent.workoutDetail(workoutId, initialIndex: 0),
      );
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate(initialIndex: 0)),
        (_) => false,
      );
      return;
    }

    if (type == 'inactivity_warning') {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate(initialIndex: 1)),
        (_) => false,
      );
      return;
    }

    if (type == 'member_direct_message') {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate(initialIndex: 5)),
        (_) => false,
      );
      return;
    }
  }
}
