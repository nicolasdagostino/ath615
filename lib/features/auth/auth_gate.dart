import 'package:flutter/material.dart';

import '../../core/auth/user_session.dart';
import '../../core/notifications/notification_intent_store.dart';
import '../../core/supabase/auth_repository.dart';
import '../../shared/widgets/bottom_nav_shell.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  final int initialIndex;

  const AuthGate({super.key, this.initialIndex = 1});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _repo = AuthRepository();
  Future<void>? _loadFuture;
  bool _notificationIntentScheduled = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  void _prepare() {
    final session = _repo.currentSession();
    if (session != null) {
      _loadFuture = UserSession().load();
      _scheduleNotificationIntentConsumption();
    } else {
      _loadFuture = Future.value();
    }
  }

  void _scheduleNotificationIntentConsumption() {
    if (_notificationIntentScheduled) return;
    _notificationIntentScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await NotificationIntentStore.consumeIfAvailable();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _repo.authStateChanges(),
      builder: (context, snapshot) {
        final session = _repo.currentSession();

        if (session == null) {
          return const LoginScreen();
        }

        _loadFuture ??= UserSession().load();

        return FutureBuilder<void>(
          future: _loadFuture,
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFFB59B6A)),
                ),
              );
            }

            _scheduleNotificationIntentConsumption();

            return BottomNavShell(initialIndex: widget.initialIndex);
          },
        );
      },
    );
  }
}
