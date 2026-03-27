import '../../core/supabase/gym_repository.dart';
import 'dashboard_builders.dart';
import 'dashboard_loaders.dart';
import 'dashboard_models.dart';

class DashboardRepository {
  final GymRepository _gymRepository;
  final DashboardLoaders _loaders;

  DashboardRepository({GymRepository? gymRepository, DashboardLoaders? loaders})
    : _gymRepository = gymRepository ?? GymRepository(),
      _loaders = loaders ?? DashboardLoaders();

  Future<DashboardData> loadDashboard() async {
    final gymId = await _gymRepository.resolveGymId();

    final members = await _loaders.loadMemberRows(gymId);
    final classesToday = await _loaders.loadDayClasses(gymId, dayOffset: 0);
    final classesTomorrow = await _loaders.loadDayClasses(gymId, dayOffset: 1);
    final thisWeekClasses = await _loaders.loadWeekClasses(
      gymId,
      weekOffset: 0,
    );
    final lastWeekClasses = await _loaders.loadWeekClasses(
      gymId,
      weekOffset: -1,
    );
    final bookings = await _loaders.loadGymBookings(gymId);
    final todayWorkouts = await _loaders.loadTodayWorkouts(gymId);

    final todayStats = dashboardBuildTodayStats(classesToday, bookings);
    final memberStats = dashboardBuildMemberStats(members);
    final engagementStats = dashboardBuildEngagementStats(members, bookings);
    final performanceStats = dashboardBuildPerformanceStats(
      thisWeekClasses: thisWeekClasses,
      lastWeekClasses: lastWeekClasses,
      bookings: bookings,
    );
    final tomorrowStats = dashboardBuildTomorrowStats(
      classesTomorrow,
      bookings,
    );
    final memberActivity = dashboardBuildMemberActivity(members, bookings);
    final alerts = dashboardBuildAlerts(
      members: members,
      classesToday: classesToday,
      bookings: bookings,
    );
    final nextClass = dashboardBuildNextClass(
      classesToday,
      classesTomorrow,
      bookings,
    );
    final workoutStatus = dashboardBuildWorkoutStatus(
      classesToday: classesToday,
      todayWorkouts: todayWorkouts,
    );
    final todayHighlights = dashboardBuildTodayHighlights(
      members: members,
      workoutStatus: workoutStatus,
    );
    final milestones = dashboardBuildMilestones(members, bookings);
    final recommendedActions = dashboardBuildRecommendedActions(
      tomorrow: tomorrowStats,
      memberActivity: memberActivity,
      nextClass: nextClass,
      workoutStatus: workoutStatus,
      todayHighlights: todayHighlights,
      today: todayStats,
    );

    return DashboardData(
      today: todayStats,
      members: memberStats,
      engagement: engagementStats,
      performance: performanceStats,
      tomorrow: tomorrowStats,
      memberActivity: memberActivity,
      alerts: alerts,
      nextClass: nextClass,
      workoutStatus: workoutStatus,
      todayHighlights: todayHighlights,
      milestones: milestones,
      recommendedActions: recommendedActions,
      gymId: gymId,
    );
  }
}
