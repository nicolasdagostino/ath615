import 'package:flutter/material.dart';

import '../../features/workouts/workout_detail_screen.dart';
import '../supabase/auth_deep_link_handler.dart';

class PushNavigation {
  PushNavigation._();

  static GlobalKey<NavigatorState> get navigatorKey =>
      AuthDeepLinkHandler.navigatorKey;

  static Future<void> handleMessageData(Map<String, dynamic> data) async {
    final rawType = (data['type'] ?? data['pushType'] ?? '').toString().trim();
    final type = rawType.toLowerCase();
    final workoutId = (data['workoutId'] ?? '').toString().trim();

    final nav = navigatorKey.currentState;
    if (nav == null) return;

    if ((type == 'workout_published' || type == 'workout_comment_reminder') &&
        workoutId.isNotEmpty) {
      nav.push(
        MaterialPageRoute(
          builder: (_) => WorkoutDetailScreen(workoutId: workoutId),
        ),
      );
    }
  }
}
