import 'supabase_bootstrap.dart';

class ProfileRepository {
  Future<Map<String, dynamic>?> getMyProfile() async {
    final user = sb.auth.currentUser;
    if (user == null) return null;

    final data = await sb
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();

    return data == null ? null : Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> listMembers() async {
    final data = await sb
        .from('profiles')
        .select('*')
        .inFilter('role', ['athlete', 'member', 'admin'])
        .order('full_name', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> listCoaches() async {
    final data = await sb
        .from('profiles')
        .select('*')
        .inFilter('role', ['coach', 'admin'])
        .order('full_name', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> createMemberByAdmin({
    required String gymId,
    required String fullName,
    required String email,
    required String role,
    String? phone,
    String? dateOfBirth,
    String? notes,
    bool isActive = true,
  }) async {
    final cleanFullName = fullName.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone?.trim();
    final cleanDob = dateOfBirth?.trim();
    final cleanNotes = notes?.trim();

    if (cleanFullName.isEmpty) {
      throw Exception('Full name is required');
    }

    if (cleanEmail.isEmpty) {
      throw Exception('Email is required');
    }

    final existing = await sb
        .from('profiles')
        .select('id, email')
        .eq('email', cleanEmail)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Ya existe un miembro con ese email.');
    }

    final payload = <String, dynamic>{
      'gym_id': gymId,
      'full_name': cleanFullName,
      'email': cleanEmail,
      'role': role,
      'phone': (cleanPhone == null || cleanPhone.isEmpty) ? null : cleanPhone,
      'date_of_birth': (cleanDob == null || cleanDob.isEmpty) ? null : cleanDob,
      'notes': (cleanNotes == null || cleanNotes.isEmpty) ? null : cleanNotes,
      'is_active': isActive,
      'member_since': DateTime.now().toIso8601String().split('T').first,
    };

    await sb.from('profiles').insert(payload);
  }

  Future<void> updateRole({
    required String profileId,
    required String role,
  }) async {
    await sb.from('profiles').update({'role': role}).eq('id', profileId);
  }

  Future<void> updateMemberActiveStatus({
    required String profileId,
    required bool isActive,
  }) async {
    await sb
        .from('profiles')
        .update({'is_active': isActive})
        .eq('id', profileId);
  }
}
