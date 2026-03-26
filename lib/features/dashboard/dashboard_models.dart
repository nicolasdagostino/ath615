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

class DashboardAlertItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;

  const DashboardAlertItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
  });
}

class DashboardData {
  final DashboardTodayStats today;
  final DashboardMemberStats members;
  final DashboardEngagementStats engagement;
  final List<DashboardAlertItem> alerts;
  final String? gymId;

  const DashboardData({
    required this.today,
    required this.members,
    required this.engagement,
    required this.alerts,
    required this.gymId,
  });
}
