class DashboardTodayStats {
  final int classesToday;
  final int bookingsToday;
  final int attendanceToday;
  final int fullClassesToday;

  const DashboardTodayStats({
    required this.classesToday,
    required this.bookingsToday,
    required this.attendanceToday,
    required this.fullClassesToday,
  });
}

class DashboardMemberStats {
  final int activeMembers;
  final int newMembersThisMonth;

  const DashboardMemberStats({
    required this.activeMembers,
    required this.newMembersThisMonth,
  });
}

class DashboardEngagementStats {
  final int inactive7Days;
  final int inactive14Days;

  const DashboardEngagementStats({
    required this.inactive7Days,
    required this.inactive14Days,
  });
}

class DashboardPerformanceStats {
  final int bookingsThisWeek;
  final int bookingsLastWeek;
  final double attendanceRate;
  final double attendanceRateLastWeek;
  final double avgAthletesPerClass;
  final double avgAthletesPerClassLastWeek;

  const DashboardPerformanceStats({
    required this.bookingsThisWeek,
    required this.bookingsLastWeek,
    required this.attendanceRate,
    required this.attendanceRateLastWeek,
    required this.avgAthletesPerClass,
    required this.avgAthletesPerClassLastWeek,
  });
}

class DashboardTomorrowStats {
  final int classesTomorrow;
  final int lowOccupancyTomorrow;
  final List<DashboardRiskClassItem> riskClasses;

  const DashboardTomorrowStats({
    required this.classesTomorrow,
    required this.lowOccupancyTomorrow,
    required this.riskClasses,
  });
}

class DashboardRiskClassItem {
  final String id;
  final String title;
  final String subtitle;
  final bool needsWorkoutAssignment;

  const DashboardRiskClassItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.needsWorkoutAssignment = false,
  });
}

class DashboardMemberActivityItem {
  final String id;
  final String name;
  final String subtitle;
  final int priority;
  final bool isAtRisk;

  const DashboardMemberActivityItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.priority,
    required this.isAtRisk,
  });
}

class DashboardAlertItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final int priority;

  const DashboardAlertItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.priority,
  });
}

class DashboardNextClassItem {
  final String id;
  final String title;
  final String subtitle;
  final String occupancyLabel;
  final bool hasWorkout;
  final bool isToday;

  const DashboardNextClassItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.occupancyLabel,
    required this.hasWorkout,
    required this.isToday,
  });
}

class DashboardWorkoutStatus {
  final bool hasWorkoutToday;
  final int workoutsToday;
  final int classesMissingWorkoutToday;
  final String summary;

  const DashboardWorkoutStatus({
    required this.hasWorkoutToday,
    required this.workoutsToday,
    required this.classesMissingWorkoutToday,
    required this.summary,
  });
}

class DashboardTodayHighlightItem {
  final String id;
  final String title;
  final String subtitle;
  final String type;

  const DashboardTodayHighlightItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
  });
}

class DashboardMilestoneItem {
  final String id;
  final String name;
  final String subtitle;
  final int classesCount;
  final int target;
  final bool reached;

  const DashboardMilestoneItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.classesCount,
    required this.target,
    required this.reached,
  });
}

class DashboardData {
  final DashboardTodayStats today;
  final DashboardMemberStats members;
  final DashboardEngagementStats engagement;
  final DashboardPerformanceStats performance;
  final DashboardTomorrowStats tomorrow;
  final List<DashboardMemberActivityItem> memberActivity;
  final List<DashboardAlertItem> alerts;
  final DashboardNextClassItem? nextClass;
  final DashboardWorkoutStatus workoutStatus;
  final List<DashboardTodayHighlightItem> todayHighlights;
  final List<DashboardMilestoneItem> milestones;
  final String? gymId;

  const DashboardData({
    required this.today,
    required this.members,
    required this.engagement,
    required this.performance,
    required this.tomorrow,
    required this.memberActivity,
    required this.alerts,
    required this.nextClass,
    required this.workoutStatus,
    required this.todayHighlights,
    required this.milestones,
    required this.gymId,
  });
}
