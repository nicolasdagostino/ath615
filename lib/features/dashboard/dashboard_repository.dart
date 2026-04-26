import '../../l10n/app_strings.dart';
import '../../core/supabase/gym_repository.dart';
import '../../core/supabase/supabase_bootstrap.dart';
import 'dashboard_builders.dart';
import 'dashboard_loaders.dart';
import 'dashboard_models.dart';

class DashboardRepository {
  final GymRepository _gymRepository;
  final DashboardLoaders _loaders;

  DashboardRepository({GymRepository? gymRepository, DashboardLoaders? loaders})
    : _gymRepository = gymRepository ?? GymRepository(),
      _loaders = loaders ?? DashboardLoaders();

  Future<DashboardData> loadDashboard({required AppStrings t}) async {
    final gymId = await _gymRepository.resolveGymId();

    String? currentRole;
    String? coachId;

    final user = sb.auth.currentUser;
    if (user != null) {
      try {
        final profile = await sb
            .from('profiles')
            .select('id, role')
            .eq('id', user.id)
            .maybeSingle();

        currentRole = (profile?['role'] ?? '').toString().toLowerCase().trim();
        if (currentRole == 'coach') {
          coachId = (profile?['id'] ?? user.id).toString().trim();
        }
      } catch (_) {}
    }

    final members = await _loaders.loadMemberRows(gymId);
    final classesToday = await _loaders.loadDayClasses(
      gymId,
      dayOffset: 0,
      coachId: coachId,
    );
    final classesTomorrow = await _loaders.loadDayClasses(
      gymId,
      dayOffset: 1,
      coachId: coachId,
    );
    final thisWeekClasses = await _loaders.loadWeekClasses(
      gymId,
      weekOffset: 0,
      coachId: coachId,
    );
    final lastWeekClasses = await _loaders.loadWeekClasses(
      gymId,
      weekOffset: -1,
      coachId: coachId,
    );
    final bookings = await _loaders.loadGymBookings(gymId, coachId: coachId);
    final payments = await _loaders.loadMembershipPayments(gymId);
    final memberships = await _loaders.loadMemberships(gymId);

    final todayStats = dashboardBuildTodayStats(classesToday, bookings);
    final memberStats = dashboardBuildMemberStats(members);
    final engagementStats = dashboardBuildEngagementStats(members, bookings);
    final revenueStats = dashboardBuildRevenueStats(
      payments: payments,
      memberships: memberships,
    );
    final performanceStats = dashboardBuildPerformanceStats(
      thisWeekClasses: thisWeekClasses,
      lastWeekClasses: lastWeekClasses,
      bookings: bookings,
    );
    final tomorrowStats = dashboardBuildTomorrowStats(
      classesTomorrow,
      bookings,
      t,
    );
    final memberActivity = dashboardBuildMemberActivity(members, bookings, t);
    final pendingAttendance = dashboardBuildPendingAttendance(bookings);
    final topClasses = dashboardBuildTopClasses(thisWeekClasses, bookings, t);
    final lowClasses = dashboardBuildLowClasses(thisWeekClasses, bookings, t);

    return DashboardData(
      today: todayStats,
      members: memberStats,
      engagement: engagementStats,
      revenue: revenueStats,
      performance: performanceStats,
      tomorrow: tomorrowStats,
      memberActivity: memberActivity,
      pendingAttendance: pendingAttendance,
      topClasses: topClasses,
      lowClasses: lowClasses,
      gymId: gymId,
      isCoachView: currentRole == 'coach',
      memberRows: members,
    );
  }
}
