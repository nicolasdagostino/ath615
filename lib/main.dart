import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/supabase/supabase_bootstrap.dart';
import 'core/supabase/auth_deep_link_handler.dart';
import 'features/auth/auth_gate.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/debug_session_screen.dart';
import 'features/auth/set_new_password_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.init();
  await AuthDeepLinkHandler.start();
  runApp(const Ath615App());
}

class Ath615App extends StatelessWidget {
  const Ath615App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AuthDeepLinkHandler.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Ath615',
      theme: AppTheme.build(),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/login': (context) => const LoginScreen(),
        '/debug-session': (context) => const DebugSessionScreen(),
        '/set-password': (context) => const SetNewPasswordScreen(),
      },
    );
  }
}
