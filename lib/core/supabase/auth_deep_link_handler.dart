
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'supabase_bootstrap.dart';

class AuthDeepLinkHandler {
  AuthDeepLinkHandler._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final _appLinks = AppLinks();

  static StreamSubscription<Uri>? _sub;
  static bool _started = false;
  static bool _busy = false;

  static Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _handle(initial);
      }
    } catch (_) {}

    _sub = _appLinks.uriLinkStream.listen((uri) async {
      await _handle(uri);
    });
  }

  static Future<void> _handle(Uri uri) async {
    if (_busy) return;
    _busy = true;

    try {
      if (uri.scheme != 'athletelab') return;

      final params = <String, String>{};

      params.addAll(uri.queryParameters);

      if (uri.fragment.isNotEmpty) {
        final fragmentParams = Uri.splitQueryString(uri.fragment);
        params.addAll(fragmentParams);
      }

      final code = params['code'];
      final refreshToken = params['refresh_token'];
      final rawType = params['type'];
      final type = rawType?.toLowerCase().trim();

      final nav = navigatorKey.currentState;
      if (nav == null) return;

      // PKCE recovery flow
      if (code != null && code.isNotEmpty) {
        debugPrint('DL password recovery flow detected');
        nav.pushNamedAndRemoveUntil('/set-password', (_) => false);
        return;
      }

      // legacy invite / recovery tokens
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await sb.auth.setSession(refreshToken);

        final isPasswordSetupFlow =
            type == 'invite' || type == 'recovery';

        if (isPasswordSetupFlow) {
          nav.pushNamedAndRemoveUntil('/set-password', (_) => false);
        } else {
          nav.pushNamedAndRemoveUntil('/', (_) => false);
        }
      }
    } catch (e) {
      debugPrint('DL error: $e');

      final nav = navigatorKey.currentState;
      nav?.pushNamedAndRemoveUntil('/login', (_) => false);
    } finally {
      _busy = false;
    }
  }

  static Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
  }
}
