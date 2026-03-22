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

  Stream<AuthState> authStateChanges() {
    return sb.auth.onAuthStateChange;
  }

  Future<void> resetPassword(
    String email, {
    String? redirectTo,
  }) async {
    await sb.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo ?? 'athletelab://auth',
    );
  }
}
