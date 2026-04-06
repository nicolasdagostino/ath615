import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_bootstrap.dart';

class AuthRepository {
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await sb.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await sb.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await sb.auth.signOut(scope: SignOutScope.local);
  }

  Future<void> hardSignOutAndClear() async {
    await sb.auth.signOut(scope: SignOutScope.local);
  }

  User? currentUser() {
    return sb.auth.currentUser;
  }

  Session? currentSession() {
    return sb.auth.currentSession;
  }

  Future<Session> requireFreshSession() async {
    final current = sb.auth.currentSession;
    if (current == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await sb.auth.refreshSession();
      final session = response.session ?? sb.auth.currentSession;
      if (session == null) {
        throw Exception('User not authenticated');
      }
      return session;
    } catch (_) {
      final fallback = sb.auth.currentSession;
      if (fallback == null) {
        throw Exception('User not authenticated');
      }
      return fallback;
    }
  }

  Stream<AuthState> authStateChanges() {
    return sb.auth.onAuthStateChange;
  }

  Future<void> resetPassword(String email, {String? redirectTo}) async {
    await sb.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo ?? 'athletelab://auth',
    );
  }
}
