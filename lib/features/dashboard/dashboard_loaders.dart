import '../../core/supabase/supabase_bootstrap.dart';
import 'dashboard_utils.dart';

class DashboardLoaders {
  Future<List<Map<String, dynamic>>> loadMemberRows(String? gymId) async {
    dynamic query = sb
        .from('profiles')
        .select(
          'id, gym_id, full_name, date_of_birth, member_since, is_active, role',
        );

    if (gymId != null && gymId.isNotEmpty) {
      query = query.eq('gym_id', gymId);
    }

    final data = await query
        .inFilter('role', ['athlete', 'member', 'admin'])
        .order('full_name', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> loadDayClasses(
    String? gymId, {
    required int dayOffset,
    String? coachId,
  }) async {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: dayOffset));
    final end = start.add(const Duration(days: 1));

    dynamic query = sb
        .from('v_classes_with_spots')
        .select('*')
        .gte('starts_at', start.toUtc().toIso8601String())
        .lt('starts_at', end.toUtc().toIso8601String())
        .eq('status', 'scheduled');

    if (gymId != null && gymId.isNotEmpty) {
      query = query.eq('gym_id', gymId);
    }
    if (coachId != null && coachId.isNotEmpty) {
      query = query.eq('coach_id', coachId);
    }

    final data = await query.order('starts_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> loadWeekClasses(
    String? gymId, {
    required int weekOffset,
    String? coachId,
  }) async {
    final range = dashboardWeekRange(weekOffset: weekOffset);

    dynamic query = sb
        .from('v_classes_with_spots')
        .select('*')
        .gte('starts_at', range.start.toUtc().toIso8601String())
        .lt('starts_at', range.end.toUtc().toIso8601String())
        .eq('status', 'scheduled');

    if (gymId != null && gymId.isNotEmpty) {
      query = query.eq('gym_id', gymId);
    }
    if (coachId != null && coachId.isNotEmpty) {
      query = query.eq('coach_id', coachId);
    }

    final data = await query.order('starts_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> loadGymBookings(
    String? gymId, {
    String? coachId,
  }) async {
    dynamic query = sb
        .from('class_bookings')
        .select(
          'id, member_id, class_id, status, created_at, classes!inner(id, gym_id, starts_at, coach_id)',
        );

    if (gymId != null && gymId.isNotEmpty) {
      query = query.eq('classes.gym_id', gymId);
    }
    if (coachId != null && coachId.isNotEmpty) {
      query = query.eq('classes.coach_id', coachId);
    }

    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> loadMembershipPayments(
    String? gymId,
  ) async {
    dynamic query = sb
        .from('membership_payments')
        .select(
          'id, amount, payment_status, paid_at, created_at, plan_id, membership_plans!inner(gym_id)',
        );

    if (gymId != null && gymId.isNotEmpty) {
      query = query.eq('membership_plans.gym_id', gymId);
    }

    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> loadMemberships(String? gymId) async {
    dynamic query = sb
        .from('member_memberships')
        .select(
          'id, status, start_date, end_date, plan_id, membership_plans!inner(gym_id)',
        );

    if (gymId != null && gymId.isNotEmpty) {
      query = query.eq('membership_plans.gym_id', gymId);
    }

    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> loadTodayWorkouts(String? gymId) async {
    final now = DateTime.now();
    final todayIso =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    dynamic query = sb
        .from('workouts')
        .select('id, gym_id, title, workout_date');

    if (gymId != null && gymId.isNotEmpty) {
      query = query.eq('gym_id', gymId);
    }

    final data = await query
        .eq('workout_date', todayIso)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }
}
