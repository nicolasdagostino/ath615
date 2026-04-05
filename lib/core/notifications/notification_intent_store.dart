import 'package:flutter/material.dart';

import '../../features/workouts/workout_detail_screen.dart';
import '../supabase/auth_deep_link_handler.dart';
import 'notification_intent.dart';

class NotificationIntentStore {
  NotificationIntentStore._();

  static NotificationIntent? _pending;

  static void set(NotificationIntent intent) {
    _pending = intent;
  }

  static NotificationIntent? consume() {
    final intent = _pending;
    _pending = null;
    return intent;
  }

  static Future<void> consumeIfAvailable() async {
    final intent = consume();
    if (intent == null) return;

    NavigatorState? nav = AuthDeepLinkHandler.navigatorKey.currentState;
    if (nav == null) {
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        nav = AuthDeepLinkHandler.navigatorKey.currentState;
        if (nav != null) break;
      }
    }

    if (nav == null) {
      _pending = intent;
      return;
    }

    switch (intent.type) {
      case NotificationIntentType.workoutDetail:
        nav.push(
          MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(workoutId: intent.workoutId),
          ),
        );
        return;
    }
  }
}
