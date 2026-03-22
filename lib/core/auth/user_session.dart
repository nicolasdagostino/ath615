import '../../core/supabase/profile_repository.dart';
import 'user_role.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  UserRole role = UserRole.athlete;

  Future<void> load() async {
    final repo = ProfileRepository();
    final profile = await repo.getMyProfile();

    if (profile == null) return;

    role = parseRole(profile['role']);
  }

  bool get isAdmin => role == UserRole.admin;

  void clear() {
    role = UserRole.athlete;
  }
}
