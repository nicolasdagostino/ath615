class DashboardTodayStats {
  final int classesToday;
  final int bookingsToday;
  final int attendanceToday;
  final int fullClassesToday;
  final double occupancyRate;

  const DashboardTodayStats({
    required this.classesToday,
    required this.bookingsToday,
    required this.attendanceToday,
    required this.fullClassesToday,
    required this.occupancyRate,
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

class DashboardRevenueStats {
  final double revenueThisMonth;
  final int paymentsThisMonth;
  final int activeMemberships;
  final int expiredMemberships;

  const DashboardRevenueStats({
    required this.revenueThisMonth,
    required this.paymentsThisMonth,
    required this.activeMemberships,
    required this.expiredMemberships,
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
  final double occupancyRateThisWeek;
  final double occupancyRateLastWeek;

  const DashboardPerformanceStats({
    required this.bookingsThisWeek,
    required this.bookingsLastWeek,
    required this.attendanceRate,
    required this.attendanceRateLastWeek,
    required this.avgAthletesPerClass,
    required this.avgAthletesPerClassLastWeek,
    required this.occupancyRateThisWeek,
    required this.occupancyRateLastWeek,
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

class DashboardPendingAttendanceStats {
  final int pendingClasses;
  final int pendingBookings;

  const DashboardPendingAttendanceStats({
    required this.pendingClasses,
    required this.pendingBookings,
  });
}

class DashboardClassDemandItem {
  final String id;
  final String title;
  final String subtitle;
  final int booked;
  final int capacity;
  final double occupancyRate;
  final bool isLow;

  const DashboardClassDemandItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.booked,
    required this.capacity,
    required this.occupancyRate,
    required this.isLow,
  });
}

class DashboardData {
  final DashboardTodayStats today;
  final DashboardMemberStats members;
  final DashboardEngagementStats engagement;
  final DashboardRevenueStats revenue;
  final DashboardPerformanceStats performance;
  final DashboardTomorrowStats tomorrow;
  final List<DashboardMemberActivityItem> memberActivity;
  final DashboardPendingAttendanceStats pendingAttendance;
  final List<DashboardClassDemandItem> topClasses;
  final List<DashboardClassDemandItem> lowClasses;
  final String? gymId;
  final bool isCoachView;

  const DashboardData({
    required this.today,
    required this.members,
    required this.engagement,
    required this.revenue,
    required this.performance,
    required this.tomorrow,
    required this.memberActivity,
    required this.pendingAttendance,
    required this.topClasses,
    required this.lowClasses,
    required this.gymId,
    required this.isCoachView,
  });
}
