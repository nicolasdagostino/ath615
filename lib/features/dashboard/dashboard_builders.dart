import '../../l10n/app_strings.dart';
import 'dashboard_models.dart';
import 'dashboard_utils.dart';

DashboardTodayStats dashboardBuildTodayStats(
  List<Map<String, dynamic>> classesToday,
  List<Map<String, dynamic>> bookings,
) {
  final todayClassIds = classesToday
      .map((e) => (e['id'] ?? '').toString())
      .where((e) => e.isNotEmpty)
      .toSet();

  var bookingsToday = 0;
  var attendanceToday = 0;

  for (final booking in bookings) {
    final classId = (booking['class_id'] ?? '').toString();
    if (!todayClassIds.contains(classId)) continue;

    final status = (booking['status'] ?? '').toString().toLowerCase().trim();
    if (status == 'booked' || status == 'attended') {
      bookingsToday++;
    }
    if (status == 'attended') {
      attendanceToday++;
    }
  }

  final fullClassesToday = classesToday
      .where((item) => dashboardIsClassFull(item))
      .length;

  final totalCapacity = classesToday.fold<int>(
    0,
    (sum, c) =>
        sum +
        dashboardReadInt(c, const ['max_spots', 'capacity', 'spots_total']),
  );

  final occupancyRate = totalCapacity == 0
      ? 0.0
      : (bookingsToday / totalCapacity) * 100;

  return DashboardTodayStats(
    classesToday: classesToday.length,
    bookingsToday: bookingsToday,
    attendanceToday: attendanceToday,
    fullClassesToday: fullClassesToday,
    occupancyRate: occupancyRate,
  );
}

DashboardMemberStats dashboardBuildMemberStats(
  List<Map<String, dynamic>> members,
) {
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);

  final activeMembers = members.where((m) => m['is_active'] == true).length;

  final newMembersThisMonth = members.where((m) {
    final raw = (m['member_since'] ?? '').toString().trim();
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return false;
    return !parsed.isBefore(monthStart);
  }).length;

  return DashboardMemberStats(
    activeMembers: activeMembers,
    newMembersThisMonth: newMembersThisMonth,
  );
}

DashboardEngagementStats dashboardBuildEngagementStats(
  List<Map<String, dynamic>> members,
  List<Map<String, dynamic>> bookings,
) {
  final now = DateTime.now();
  final activeMemberIds = members
      .where((m) => m['is_active'] == true)
      .map((m) => (m['id'] ?? '').toString())
      .where((id) => id.isNotEmpty)
      .toSet();

  final lastActivityByMember = dashboardLastActivityByMember(
    bookings,
    activeMemberIds,
  );

  var inactive7 = 0;
  var inactive14 = 0;

  for (final memberId in activeMemberIds) {
    final last = lastActivityByMember[memberId];
    if (last == null) {
      inactive7++;
      inactive14++;
      continue;
    }

    final diff = now.difference(last.toLocal());
    if (diff.inDays >= 7) inactive7++;
    if (diff.inDays >= 14) inactive14++;
  }

  return DashboardEngagementStats(
    inactive7Days: inactive7,
    inactive14Days: inactive14,
  );
}

DashboardRevenueStats dashboardBuildRevenueStats({
  required List<Map<String, dynamic>> payments,
  required List<Map<String, dynamic>> memberships,
}) {
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);

  double revenueThisMonth = 0;
  int paymentsThisMonth = 0;

  for (final payment in payments) {
    final status = (payment['payment_status'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    if (status != 'paid' && status != 'succeeded' && status != 'completed') {
      continue;
    }

    final paidAt = DateTime.tryParse(
      (payment['paid_at'] ?? payment['created_at'] ?? '').toString(),
    )?.toLocal();

    if (paidAt == null || paidAt.isBefore(monthStart)) continue;

    final rawAmount = payment['amount'];
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '') ?? 0.0;

    revenueThisMonth += amount;
    paymentsThisMonth++;
  }

  int activeMemberships = 0;
  int expiredMemberships = 0;

  for (final membership in memberships) {
    final status = (membership['status'] ?? '').toString().toLowerCase().trim();
    final endDate = DateTime.tryParse(
      (membership['end_date'] ?? '').toString(),
    )?.toLocal();

    final isActiveStatus = status == 'active';
    final isExpiredByDate =
        endDate != null &&
        DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
        ).isBefore(DateTime(now.year, now.month, now.day));

    if (isActiveStatus && !isExpiredByDate) {
      activeMemberships++;
    } else if (status == 'expired' || isExpiredByDate) {
      expiredMemberships++;
    }
  }

  return DashboardRevenueStats(
    revenueThisMonth: revenueThisMonth,
    paymentsThisMonth: paymentsThisMonth,
    activeMemberships: activeMemberships,
    expiredMemberships: expiredMemberships,
  );
}

DashboardPerformanceStats dashboardBuildPerformanceStats({
  required List<Map<String, dynamic>> thisWeekClasses,
  required List<Map<String, dynamic>> lastWeekClasses,
  required List<Map<String, dynamic>> bookings,
}) {
  final thisWeek = dashboardComputeWeekPerformance(
    classes: thisWeekClasses,
    bookings: bookings,
    weekOffset: 0,
  );
  final lastWeek = dashboardComputeWeekPerformance(
    classes: lastWeekClasses,
    bookings: bookings,
    weekOffset: -1,
  );

  return DashboardPerformanceStats(
    bookingsThisWeek: thisWeek.bookings,
    bookingsLastWeek: lastWeek.bookings,
    attendanceRate: thisWeek.attendanceRate,
    attendanceRateLastWeek: lastWeek.attendanceRate,
    avgAthletesPerClass: thisWeek.avgAthletesPerClass,
    avgAthletesPerClassLastWeek: lastWeek.avgAthletesPerClass,
    occupancyRateThisWeek: thisWeek.occupancyRate,
    occupancyRateLastWeek: lastWeek.occupancyRate,
  );
}

DashboardTomorrowStats dashboardBuildTomorrowStats(
  List<Map<String, dynamic>> classesTomorrow,
  List<Map<String, dynamic>> bookings,
  AppStrings t,
) {
  final riskItems = <DashboardRiskClassItem>[];

  for (final item in classesTomorrow) {
    final classId = (item['id'] ?? '').toString();
    if (classId.isEmpty) continue;

    final maxSpots = dashboardReadInt(item, const [
      'max_spots',
      'capacity',
      'spots_total',
    ]);
    if (maxSpots <= 0) continue;

    final reserved = bookings.where((b) {
      final sameClass = (b['class_id'] ?? '').toString() == classId;
      if (!sameClass) return false;
      final status = (b['status'] ?? '').toString().toLowerCase().trim();
      return status == 'booked' || status == 'attended';
    }).length;

    final ratio = reserved / maxSpots;
    final lowOccupancy = ratio <= 0.40;
    if (!lowOccupancy) continue;

    final startsAt = DateTime.tryParse(
      (item['starts_at'] ?? '').toString(),
    )?.toLocal();
    final hh = startsAt?.hour.toString().padLeft(2, '0') ?? '--';
    final mm = startsAt?.minute.toString().padLeft(2, '0') ?? '--';

    final title = (item['title'] ?? item['program_name'] ?? t.classLabel)
        .toString()
        .trim();
    final safeTitle = title.isEmpty ? t.classLabel : title;

    final subtitleParts = <String>[];
    if (lowOccupancy) {
      subtitleParts.add(t.bookedRatio(reserved, maxSpots));
    }

    riskItems.add(
      DashboardRiskClassItem(
        id: classId,
        title: '$hh:$mm · $safeTitle',
        subtitle: subtitleParts.join(' · '),
      ),
    );
  }

  return DashboardTomorrowStats(
    classesTomorrow: classesTomorrow.length,
    lowOccupancyTomorrow: riskItems.length,
    riskClasses: riskItems.take(4).toList(),
  );
}

List<DashboardMemberActivityItem> dashboardBuildMemberActivity(
  List<Map<String, dynamic>> members,
  List<Map<String, dynamic>> bookings,
  AppStrings t,
) {
  final now = DateTime.now();
  final activeMembers = members.where((m) => m['is_active'] == true).toList();

  final activeMemberIds = activeMembers
      .map((m) => (m['id'] ?? '').toString())
      .where((id) => id.isNotEmpty)
      .toSet();

  final lastActivityByMember = dashboardLastActivityByMember(
    bookings,
    activeMemberIds,
  );
  final recentAttendanceByMember = _attendanceLast28DaysByMember(
    bookings,
    activeMemberIds,
  );
  final items = <DashboardMemberActivityItem>[];

  for (final member in activeMembers) {
    final memberId = (member['id'] ?? '').toString();
    if (memberId.isEmpty) continue;

    final name = dashboardMemberName(member);
    final snapshot = _memberRiskSnapshot(
      member: member,
      lastActivity: lastActivityByMember[memberId],
      attendedLast28Days: recentAttendanceByMember[memberId] ?? 0,
      now: now,
      t: t,
    );

    items.add(
      DashboardMemberActivityItem(
        id: memberId,
        name: name,
        subtitle: snapshot.subtitle,
        priority: snapshot.priority,
        isAtRisk: snapshot.isAtRisk,
      ),
    );
  }

  items.sort((a, b) => b.priority.compareTo(a.priority));
  return items.take(5).toList();
}

DashboardPendingAttendanceStats dashboardBuildPendingAttendance(
  List<Map<String, dynamic>> bookings,
) {
  final now = DateTime.now();
  final pendingClassIds = <String>{};
  var pendingBookings = 0;

  for (final booking in bookings) {
    final status = (booking['status'] ?? '').toString().toLowerCase().trim();
    if (status != 'booked') continue;

    final classId = (booking['class_id'] ?? '').toString().trim();
    if (classId.isEmpty) continue;

    final classData = booking['classes'];
    if (classData is! Map) continue;

    final startsAt = DateTime.tryParse(
      (classData['starts_at'] ?? '').toString(),
    )?.toLocal();
    if (startsAt == null) continue;

    if (!startsAt.isBefore(now)) continue;

    pendingClassIds.add(classId);
    pendingBookings++;
  }

  return DashboardPendingAttendanceStats(
    pendingClasses: pendingClassIds.length,
    pendingBookings: pendingBookings,
  );
}

List<DashboardClassDemandItem> dashboardBuildTopClasses(
  List<Map<String, dynamic>> classes,
  List<Map<String, dynamic>> bookings,
  AppStrings t,
) {
  final items = <DashboardClassDemandItem>[];

  for (final item in classes) {
    final classId = (item['id'] ?? '').toString().trim();
    if (classId.isEmpty) continue;

    final capacity = dashboardReadInt(item, const [
      'max_spots',
      'capacity',
      'spots_total',
    ]);
    if (capacity <= 0) continue;

    final booked = bookings.where((b) {
      final sameClass = (b['class_id'] ?? '').toString() == classId;
      if (!sameClass) return false;
      final status = (b['status'] ?? '').toString().toLowerCase().trim();
      return status == 'booked' || status == 'attended';
    }).length;

    final occupancyRate = (booked / capacity) * 100.0;
    final startsAt = DateTime.tryParse(
      (item['starts_at'] ?? '').toString(),
    )?.toLocal();
    final hh = startsAt?.hour.toString().padLeft(2, '0') ?? '--';
    final mm = startsAt?.minute.toString().padLeft(2, '0') ?? '--';

    final title = (item['title'] ?? item['program_name'] ?? t.classLabel)
        .toString()
        .trim();
    final safeTitle = title.isEmpty ? t.classLabel : title;

    items.add(
      DashboardClassDemandItem(
        id: classId,
        title: safeTitle,
        subtitle: '$hh:$mm · $booked/$capacity',
        booked: booked,
        capacity: capacity,
        occupancyRate: occupancyRate,
        isLow: false,
      ),
    );
  }

  items.sort((a, b) {
    final byRate = b.occupancyRate.compareTo(a.occupancyRate);
    if (byRate != 0) return byRate;
    return b.booked.compareTo(a.booked);
  });

  return items.take(3).toList();
}

List<DashboardClassDemandItem> dashboardBuildLowClasses(
  List<Map<String, dynamic>> classes,
  List<Map<String, dynamic>> bookings,
  AppStrings t,
) {
  final items = <DashboardClassDemandItem>[];

  for (final item in classes) {
    final classId = (item['id'] ?? '').toString().trim();
    if (classId.isEmpty) continue;

    final capacity = dashboardReadInt(item, const [
      'max_spots',
      'capacity',
      'spots_total',
    ]);
    if (capacity <= 0) continue;

    final booked = bookings.where((b) {
      final sameClass = (b['class_id'] ?? '').toString() == classId;
      if (!sameClass) return false;
      final status = (b['status'] ?? '').toString().toLowerCase().trim();
      return status == 'booked' || status == 'attended';
    }).length;

    final occupancyRate = (booked / capacity) * 100.0;
    final startsAt = DateTime.tryParse(
      (item['starts_at'] ?? '').toString(),
    )?.toLocal();
    final hh = startsAt?.hour.toString().padLeft(2, '0') ?? '--';
    final mm = startsAt?.minute.toString().padLeft(2, '0') ?? '--';

    final title = (item['title'] ?? item['program_name'] ?? t.classLabel)
        .toString()
        .trim();
    final safeTitle = title.isEmpty ? t.classLabel : title;

    items.add(
      DashboardClassDemandItem(
        id: classId,
        title: safeTitle,
        subtitle: '$hh:$mm · $booked/$capacity',
        booked: booked,
        capacity: capacity,
        occupancyRate: occupancyRate,
        isLow: true,
      ),
    );
  }

  items.sort((a, b) {
    final byRate = a.occupancyRate.compareTo(b.occupancyRate);
    if (byRate != 0) return byRate;
    return a.booked.compareTo(b.booked);
  });

  return items.take(3).toList();
}

DashboardWeekPerformance dashboardComputeWeekPerformance({
  required List<Map<String, dynamic>> classes,
  required List<Map<String, dynamic>> bookings,
  required int weekOffset,
}) {
  final range = dashboardWeekRange(weekOffset: weekOffset);
  final classIds = classes
      .map((e) => (e['id'] ?? '').toString())
      .where((e) => e.isNotEmpty)
      .toSet();

  var bookingsCount = 0;
  var attendedCount = 0;
  var reservedCount = 0;

  for (final booking in bookings) {
    final classId = (booking['class_id'] ?? '').toString();
    if (!classIds.contains(classId)) continue;

    DateTime? classStartsAt;
    final classData = booking['classes'];
    if (classData is Map) {
      classStartsAt = DateTime.tryParse(
        (classData['starts_at'] ?? '').toString(),
      )?.toLocal();
    }

    if (classStartsAt == null) continue;
    if (classStartsAt.isBefore(range.start) ||
        !classStartsAt.isBefore(range.end)) {
      continue;
    }

    final status = (booking['status'] ?? '').toString().toLowerCase().trim();

    if (status == 'booked' || status == 'attended') {
      bookingsCount++;
      reservedCount++;
    }

    if (status == 'attended') {
      attendedCount++;
    }
  }

  final attendanceRate = reservedCount == 0
      ? 0.0
      : (attendedCount / reservedCount) * 100.0;

  final avgAthletesPerClass = classes.isEmpty
      ? 0.0
      : bookingsCount / classes.length;

  final totalCapacity = classes.fold<int>(
    0,
    (sum, c) =>
        sum +
        dashboardReadInt(c, const ['max_spots', 'capacity', 'spots_total']),
  );

  final occupancyRate = totalCapacity == 0
      ? 0.0
      : (bookingsCount / totalCapacity) * 100.0;

  return DashboardWeekPerformance(
    bookings: bookingsCount,
    attendanceRate: attendanceRate,
    avgAthletesPerClass: avgAthletesPerClass,
    occupancyRate: occupancyRate,
  );
}

Map<String, int> _attendanceLast28DaysByMember(
  List<Map<String, dynamic>> bookings,
  Set<String> activeMemberIds,
) {
  final result = <String, int>{};
  final now = DateTime.now();
  final windowStart = now.subtract(const Duration(days: 28));

  for (final booking in bookings) {
    final memberId = (booking['member_id'] ?? '').toString();
    if (!activeMemberIds.contains(memberId)) continue;

    final status = (booking['status'] ?? '').toString().toLowerCase().trim();
    if (status != 'attended') continue;

    final classData = booking['classes'];
    DateTime? classStartsAt;
    if (classData is Map) {
      classStartsAt = DateTime.tryParse(
        (classData['starts_at'] ?? '').toString(),
      )?.toLocal();
    }

    if (classStartsAt == null) continue;
    if (classStartsAt.isBefore(windowStart) || classStartsAt.isAfter(now)) {
      continue;
    }

    result[memberId] = (result[memberId] ?? 0) + 1;
  }

  return result;
}

_MemberRiskSnapshot _memberRiskSnapshot({
  required AppStrings t,
  required Map<String, dynamic> member,
  required DateTime? lastActivity,
  required int attendedLast28Days,
  required DateTime now,
}) {
  final memberSince = DateTime.tryParse(
    (member['member_since'] ?? '').toString().trim(),
  )?.toLocal();

  final memberAgeDays = memberSince == null
      ? null
      : now.difference(memberSince).inDays;

  if (lastActivity == null) {
    final oldEnoughWithoutActivity =
        memberAgeDays != null && memberAgeDays >= 21;

    if (oldEnoughWithoutActivity) {
      return _MemberRiskSnapshot(
        subtitle: t.noBookingsYetOnboarding,
        priority: 85,
        isAtRisk: true,
      );
    }

    return _MemberRiskSnapshot(
      subtitle: t.noBookingsYetNewMember,
      priority: 5,
      isAtRisk: false,
    );
  }

  final inactiveDays = now.difference(lastActivity.toLocal()).inDays;

  if (attendedLast28Days >= 8) {
    if (inactiveDays >= 7) {
      return _MemberRiskSnapshot(
        subtitle: t.daysInactiveHighFrequency(inactiveDays),
        priority: 90 + inactiveDays,
        isAtRisk: true,
      );
    }
  } else if (attendedLast28Days >= 4) {
    if (inactiveDays >= 10) {
      return _MemberRiskSnapshot(
        subtitle: t.daysInactiveRegular(inactiveDays),
        priority: 70 + inactiveDays,
        isAtRisk: true,
      );
    }
  } else if (attendedLast28Days >= 1) {
    if (inactiveDays >= 14) {
      return _MemberRiskSnapshot(
        subtitle: t.daysInactiveLowFrequency(inactiveDays),
        priority: 50 + inactiveDays,
        isAtRisk: true,
      );
    }
  } else {
    if (inactiveDays >= 21) {
      return _MemberRiskSnapshot(
        subtitle: t.daysInactiveNoPattern(inactiveDays),
        priority: 35 + inactiveDays,
        isAtRisk: true,
      );
    }
  }

  if (inactiveDays <= 0) {
    return _MemberRiskSnapshot(
      subtitle: attendedLast28Days >= 4
          ? t.activeTodayConsistent
          : t.activeToday,
      priority: -100,
      isAtRisk: false,
    );
  }

  if (inactiveDays == 1) {
    return _MemberRiskSnapshot(
      subtitle: attendedLast28Days >= 4
          ? t.activeOneDayAgoHealthy
          : t.activeOneDayAgo,
      priority: -90,
      isAtRisk: false,
    );
  }

  return _MemberRiskSnapshot(
    subtitle: attendedLast28Days >= 8
        ? t.activeDaysAgoVeryConsistent(inactiveDays)
        : attendedLast28Days >= 4
        ? t.activeDaysAgoRegular(inactiveDays)
        : attendedLast28Days >= 1
        ? t.activeDaysAgo(inactiveDays)
        : t.activeDaysAgoNoPattern(inactiveDays),
    priority: -inactiveDays,
    isAtRisk: false,
  );
}

class _MemberRiskSnapshot {
  final String subtitle;
  final int priority;
  final bool isAtRisk;

  _MemberRiskSnapshot({
    required this.subtitle,
    required this.priority,
    required this.isAtRisk,
  });
}

Map<String, DateTime> dashboardLastActivityByMember(
  List<Map<String, dynamic>> bookings,
  Set<String> activeMemberIds,
) {
  final result = <String, DateTime>{};

  for (final booking in bookings) {
    final memberId = (booking['member_id'] ?? '').toString();
    if (!activeMemberIds.contains(memberId)) continue;

    final classData = booking['classes'];
    DateTime? classStartsAt;
    if (classData is Map) {
      classStartsAt = DateTime.tryParse(
        (classData['starts_at'] ?? '').toString(),
      );
    }

    final createdAt = DateTime.tryParse(
      (booking['created_at'] ?? '').toString(),
    );

    final activityAt = classStartsAt ?? createdAt;
    if (activityAt == null) continue;

    final current = result[memberId];
    if (current == null || activityAt.isAfter(current)) {
      result[memberId] = activityAt;
    }
  }

  return result;
}
