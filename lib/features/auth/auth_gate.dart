import 'package:flutter/material.dart';

import '../../core/auth/user_session.dart';
import '../../core/notifications/notification_intent_store.dart';
import '../../core/supabase/auth_repository.dart';
import '../../core/supabase/profile_repository.dart';
import '../../shared/widgets/bottom_nav_shell.dart';
import 'login_screen.dart';
import 'access_blocked_screen.dart';

class AuthGate extends StatefulWidget {
  final int initialIndex;

  const AuthGate({super.key, this.initialIndex = 1});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _repo = AuthRepository();
  final _profileRepo = ProfileRepository();
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



  Future<Map<String, dynamic>> _loadAccessState() async {
    try {
      final snapshot = await _profileRepo.getMyAccessSnapshot();
      if (snapshot == null) {
        return {
          'allowed': false,
          'title': 'Access unavailable',
          'message':
              'We could not verify your account access. Please sign in again.',
        };
      }

      final profile = snapshot['profile'] is Map
          ? Map<String, dynamic>.from(snapshot['profile'])
          : const <String, dynamic>{};
      final gym = snapshot['gym'] is Map
          ? Map<String, dynamic>.from(snapshot['gym'])
          : null;

      final profileIsActive = profile['is_active'] == true;
      if (!profileIsActive) {
        return {
          'allowed': false,
          'title': 'Account inactive',
          'message':
              'Your account is not active right now. Please contact your gym for help.',
        };
      }

      final gymId = (profile['gym_id'] ?? '').toString().trim();
      if (gymId.isEmpty) {
        return {
          'allowed': true,
          'title': '',
          'message': '',
        };
      }

      if (gym == null) {
        return {
          'allowed': false,
          'title': 'Gym unavailable',
          'message':
              'Your gym could not be found or is no longer available on the platform.',
        };
      }

      final gymIsActive = gym['is_active'] == true;
      final gymIsBlocked = gym['is_blocked'] == true;
      final gymDeletedAt = (gym['deleted_at'] ?? '').toString().trim();
      final blockedReason = (gym['blocked_reason'] ?? '').toString().trim();

      if (!gymIsActive) {
        return {
          'allowed': false,
          'title': 'Gym inactive',
          'message':
              'This gym is currently inactive. Please contact the gym for more information.',
        };
      }

      if (gymIsBlocked) {
        return {
          'allowed': false,
          'title': 'Gym suspended',
          'message': blockedReason.isNotEmpty
              ? blockedReason
              : 'This gym is temporarily suspended. Please contact the gym for help.',
        };
      }

      if (gymDeletedAt.isNotEmpty) {
        return {
          'allowed': false,
          'title': 'Gym unavailable',
          'message':
              'This gym is no longer available on the platform.',
        };
      }

      return {
        'allowed': true,
        'title': '',
        'message': '',
      };
    } catch (_) {
      return {
        'allowed': false,
        'title': 'Access unavailable',
        'message':
            'We could not verify your account access. Please sign in again.',
      };
    }
  }

  Future<void> _signOutToLogin() async {
    await _repo.signOut();
    UserSession().clear();
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

            return FutureBuilder<Map<String, dynamic>>(
              future: _loadAccessState(),
              builder: (context, accessSnapshot) {
                if (accessSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFB59B6A),
                      ),
                    ),
                  );
                }

                final accessState = accessSnapshot.data ?? const <String, dynamic>{};
                final canAccess = accessState['allowed'] == true;

                if (!canAccess) {
                  return AccessBlockedScreen(
                    title: (accessState['title'] ?? 'Access unavailable')
                        .toString(),
                    message: (accessState['message'] ??
                            'We could not verify your account access.')
                        .toString(),
                    onSignOut: _signOutToLogin,
                  );
                }

                _scheduleNotificationIntentConsumption();
                return BottomNavShell(initialIndex: widget.initialIndex);
              },
            );
          },
        );
      },
    );
  }
}
