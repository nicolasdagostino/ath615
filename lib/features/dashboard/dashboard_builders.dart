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

  return DashboardTodayStats(
    classesToday: classesToday.length,
    bookingsToday: bookingsToday,
    attendanceToday: attendanceToday,
    fullClassesToday: fullClassesToday,
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
  );
}

DashboardTomorrowStats dashboardBuildTomorrowStats(
  List<Map<String, dynamic>> classesTomorrow,
  List<Map<String, dynamic>> bookings,
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
    final workoutId = (item['workout_id'] ?? '').toString().trim();
    final hasWorkout = workoutId.isNotEmpty;
    final lowOccupancy = ratio <= 0.40;

    if (!lowOccupancy && hasWorkout) continue;

    final startsAt = DateTime.tryParse(
      (item['starts_at'] ?? '').toString(),
    )?.toLocal();
    final hh = startsAt?.hour.toString().padLeft(2, '0') ?? '--';
    final mm = startsAt?.minute.toString().padLeft(2, '0') ?? '--';

    final title = (item['title'] ?? item['program_name'] ?? 'Class')
        .toString()
        .trim();
    final safeTitle = title.isEmpty ? 'Class' : title;

    final subtitleParts = <String>[];
    if (!hasWorkout) {
      subtitleParts.add('Workout not assigned');
    }
    if (lowOccupancy) {
      subtitleParts.add('$reserved / $maxSpots booked');
    }

    riskItems.add(
      DashboardRiskClassItem(
        id: classId,
        title: '$hh:$mm · $safeTitle',
        subtitle: subtitleParts.join(' · '),
        needsWorkoutAssignment: !hasWorkout,
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

DashboardNextClassItem? dashboardBuildNextClass(
  List<Map<String, dynamic>> classesToday,
  List<Map<String, dynamic>> classesTomorrow,
  List<Map<String, dynamic>> bookings,
) {
  final now = DateTime.now();

  Map<String, dynamic>? nextItem;
  bool isToday = true;

  for (final item in classesToday) {
    final startsAt = DateTime.tryParse(
      (item['starts_at'] ?? '').toString(),
    )?.toLocal();
    if (startsAt == null) continue;
    if (startsAt.isBefore(now)) continue;
    nextItem = item;
    isToday = true;
    break;
  }

  if (nextItem == null && classesTomorrow.isNotEmpty) {
    nextItem = classesTomorrow.first;
    isToday = false;
  }

  if (nextItem == null) return null;

  final classId = (nextItem['id'] ?? '').toString();
  final startsAt = DateTime.tryParse(
    (nextItem['starts_at'] ?? '').toString(),
  )?.toLocal();

  final hh = startsAt?.hour.toString().padLeft(2, '0') ?? '--';
  final mm = startsAt?.minute.toString().padLeft(2, '0') ?? '--';

  final reserved = bookings.where((b) {
    final sameClass = (b['class_id'] ?? '').toString() == classId;
    if (!sameClass) return false;
    final status = (b['status'] ?? '').toString().toLowerCase().trim();
    return status == 'booked' || status == 'attended';
  }).length;

  final maxSpots = dashboardReadInt(nextItem, const [
    'max_spots',
    'capacity',
    'spots_total',
  ]);

  final title = (nextItem['title'] ?? nextItem['program_name'] ?? 'Class')
      .toString()
      .trim();
  final coach = (nextItem['coach_name'] ?? '').toString().trim();
  final hasWorkout = (nextItem['workout_id'] ?? '')
      .toString()
      .trim()
      .isNotEmpty;

  final subtitleParts = <String>[
    isToday ? 'Today · $hh:$mm' : 'Tomorrow · $hh:$mm',
  ];
  if (coach.isNotEmpty) {
    subtitleParts.add(coach);
  }

  return DashboardNextClassItem(
    id: classId,
    title: title.isEmpty ? 'Class' : title,
    subtitle: subtitleParts.join(' · '),
    occupancyLabel: maxSpots > 0
        ? '$reserved / $maxSpots booked'
        : '$reserved booked',
    hasWorkout: hasWorkout,
    isToday: isToday,
  );
}

DashboardWorkoutStatus dashboardBuildWorkoutStatus({
  required List<Map<String, dynamic>> classesToday,
  required List<Map<String, dynamic>> todayWorkouts,
}) {
  var missing = 0;
  for (final item in classesToday) {
    final hasWorkout = (item['workout_id'] ?? '').toString().trim().isNotEmpty;
    if (!hasWorkout) missing++;
  }

  final workoutsToday = todayWorkouts.length;
  final hasWorkoutToday =
      workoutsToday > 0 ||
      classesToday.any(
        (item) => (item['workout_id'] ?? '').toString().trim().isNotEmpty,
      );

  final summary = classesToday.isEmpty
      ? 'No classes scheduled today.'
      : missing == 0
      ? 'Today programming is assigned.'
      : '$missing classes still need a workout.';

  return DashboardWorkoutStatus(
    hasWorkoutToday: hasWorkoutToday,
    workoutsToday: workoutsToday,
    classesMissingWorkoutToday: missing,
    summary: summary,
  );
}

List<DashboardTodayHighlightItem> dashboardBuildTodayHighlights({
  required List<Map<String, dynamic>> members,
  required DashboardWorkoutStatus workoutStatus,
}) {
  final now = DateTime.now();
  final items = <DashboardTodayHighlightItem>[];

  for (final member in members) {
    if (member['is_active'] != true) continue;
    final dobRaw = (member['date_of_birth'] ?? '').toString().trim();
    final dob = DateTime.tryParse(dobRaw);
    if (dob == null) continue;
    if (dob.month != now.month || dob.day != now.day) continue;

    final name = dashboardMemberName(member);
    items.add(
      DashboardTodayHighlightItem(
        id: 'birthday-${member['id']}',
        title: name,
        subtitle: 'Birthday today',
        type: 'birthday',
      ),
    );
  }

  items.add(
    DashboardTodayHighlightItem(
      id: 'workout-status',
      title: workoutStatus.hasWorkoutToday
          ? 'Workout ready'
          : 'Workout missing',
      subtitle: workoutStatus.summary,
      type: 'workout',
    ),
  );

  return items.take(4).toList();
}

List<DashboardMilestoneItem> dashboardBuildMilestones(
  List<Map<String, dynamic>> members,
  List<Map<String, dynamic>> bookings,
) {
  const thresholds = [10, 50, 100, 500, 1000];

  final activeMembers = members.where((m) => m['is_active'] == true).toList();
  final activeMemberIds = activeMembers
      .map((m) => (m['id'] ?? '').toString())
      .where((id) => id.isNotEmpty)
      .toSet();

  final attendanceCountByMember = <String, int>{};

  for (final booking in bookings) {
    final memberId = (booking['member_id'] ?? '').toString();
    if (!activeMemberIds.contains(memberId)) continue;

    final status = (booking['status'] ?? '').toString().toLowerCase().trim();
    if (status != 'attended') continue;

    attendanceCountByMember[memberId] =
        (attendanceCountByMember[memberId] ?? 0) + 1;
  }

  final reachedItems = <DashboardMilestoneItem>[];
  final upcomingItems = <DashboardMilestoneItem>[];

  for (final member in activeMembers) {
    final memberId = (member['id'] ?? '').toString();
    if (memberId.isEmpty) continue;

    final count = attendanceCountByMember[memberId] ?? 0;
    final name = dashboardMemberName(member);

    if (thresholds.contains(count)) {
      reachedItems.add(
        DashboardMilestoneItem(
          id: 'milestone-reached-$memberId',
          name: name,
          subtitle: 'Reached $count classes',
          classesCount: count,
          target: count,
          reached: true,
        ),
      );
      continue;
    }

    int? nextTarget;
    for (final threshold in thresholds) {
      if (count < threshold) {
        nextTarget = threshold;
        break;
      }
    }

    if (nextTarget == null) continue;

    final remaining = nextTarget - count;
    if (remaining > 5) continue;

    upcomingItems.add(
      DashboardMilestoneItem(
        id: 'milestone-next-$memberId',
        name: name,
        subtitle: '$remaining classes left for $nextTarget',
        classesCount: count,
        target: nextTarget,
        reached: false,
      ),
    );
  }

  reachedItems.sort((a, b) => b.target.compareTo(a.target));
  upcomingItems.sort((a, b) {
    final aRemaining = a.target - a.classesCount;
    final bRemaining = b.target - b.classesCount;
    if (aRemaining != bRemaining) return aRemaining.compareTo(bRemaining);
    return b.classesCount.compareTo(a.classesCount);
  });

  return [...reachedItems.take(2), ...upcomingItems.take(2)];
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

  return DashboardWeekPerformance(
    bookings: bookingsCount,
    attendanceRate: attendanceRate,
    avgAthletesPerClass: avgAthletesPerClass,
  );
}

List<DashboardRecommendedAction> dashboardBuildRecommendedActions({
  required DashboardTomorrowStats tomorrow,
  required List<DashboardMemberActivityItem> memberActivity,
  required DashboardNextClassItem? nextClass,
  required DashboardWorkoutStatus workoutStatus,
  required List<DashboardTodayHighlightItem> todayHighlights,
  required DashboardTodayStats today,
}) {
  final actions = <DashboardRecommendedAction>[];

  if (tomorrow.lowOccupancyTomorrow > 0) {
    actions.add(
      DashboardRecommendedAction(
        id: 'tomorrow-risk',
        type: 'tomorrow_risk',
        title: 'Review tomorrow risk',
        subtitle:
            '${tomorrow.lowOccupancyTomorrow} classes may need promotion or review.',
        priority: 100 + tomorrow.lowOccupancyTomorrow,
      ),
    );
  }

  final atRiskMembers = memberActivity.where((e) => e.isAtRisk).length;
  if (atRiskMembers > 0) {
    actions.add(
      DashboardRecommendedAction(
        id: 'inactive-members',
        type: 'inactive_members',
        title: 'Check inactive members',
        subtitle: '$atRiskMembers members may need a follow-up message.',
        priority: 90 + atRiskMembers,
      ),
    );
  }

  if (nextClass != null && !nextClass.hasWorkout) {
    actions.add(
      DashboardRecommendedAction(
        id: 'next-class-workout',
        type: 'next_class_workout',
        title: 'Assign workout to next class',
        subtitle: '${nextClass.title} still has no workout assigned.',
        priority: nextClass.isToday ? 95 : 80,
      ),
    );
  } else if (workoutStatus.classesMissingWorkoutToday > 0) {
    actions.add(
      DashboardRecommendedAction(
        id: 'today-workouts-missing',
        type: 'today_workout_missing',
        title: 'Finish today programming',
        subtitle:
            '${workoutStatus.classesMissingWorkoutToday} classes still need a workout.',
        priority: 85 + workoutStatus.classesMissingWorkoutToday,
      ),
    );
  }

  final birthdayItems = todayHighlights
      .where((e) => e.type == 'birthday')
      .length;
  if (birthdayItems > 0) {
    actions.add(
      DashboardRecommendedAction(
        id: 'birthday-today',
        type: 'birthday',
        title: 'Wish happy birthday',
        subtitle: '$birthdayItems members are celebrating today.',
        priority: 75 + birthdayItems,
      ),
    );
  }

  if (today.bookingsToday > 0) {
    actions.add(
      DashboardRecommendedAction(
        id: 'today-bookings',
        type: 'today_bookings',
        title: 'Review today bookings',
        subtitle:
            '${today.bookingsToday} bookings currently on today schedule.',
        priority: 60 + today.bookingsToday,
      ),
    );
  }

  if (actions.isEmpty) {
    actions.add(
      const DashboardRecommendedAction(
        id: 'open-admin',
        type: 'open_admin',
        title: 'Open admin',
        subtitle:
            'Everything looks healthy. Review classes, members and plans.',
        priority: 10,
      ),
    );
  } else {
    actions.add(
      const DashboardRecommendedAction(
        id: 'open-admin',
        type: 'open_admin',
        title: 'Open admin',
        subtitle: 'Go to admin tools to manage classes, members and plans.',
        priority: 5,
      ),
    );
  }

  actions.sort((a, b) => b.priority.compareTo(a.priority));
  return actions.take(4).toList();
}

List<DashboardAlertItem> dashboardBuildAlerts({
  required List<Map<String, dynamic>> members,
  required List<Map<String, dynamic>> classesToday,
  required List<Map<String, dynamic>> bookings,
}) {
  final alerts = <DashboardAlertItem>[];

  alerts.addAll(dashboardBuildBirthdayAlerts(members));
  alerts.addAll(dashboardBuildInactiveMemberAlerts(members, bookings));
  alerts.addAll(dashboardBuildLowOccupancyAlerts(classesToday, bookings));

  alerts.sort((a, b) => b.priority.compareTo(a.priority));
  return alerts.take(6).toList();
}

List<DashboardAlertItem> dashboardBuildBirthdayAlerts(
  List<Map<String, dynamic>> members,
) {
  final now = DateTime.now();
  final alerts = <DashboardAlertItem>[];

  for (final member in members) {
    if (member['is_active'] != true) continue;

    final name = dashboardMemberName(member);
    final dobRaw = (member['date_of_birth'] ?? '').toString().trim();
    final dob = DateTime.tryParse(dobRaw);
    if (dob == null) continue;

    final nextBirthday = dashboardNextBirthdayDate(now, dob);
    final diff = nextBirthday
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    if (diff < 0 || diff > 7) continue;

    final when = diff == 0
        ? 'Today'
        : diff == 1
        ? 'Tomorrow'
        : 'In $diff days';

    alerts.add(
      DashboardAlertItem(
        id: 'birthday-${member['id']}',
        type: 'birthday',
        title: '$name birthday',
        subtitle: '$when · turns ${nextBirthday.year - dob.year}',
        priority: 40 - diff,
      ),
    );
  }

  return alerts;
}

List<DashboardAlertItem> dashboardBuildInactiveMemberAlerts(
  List<Map<String, dynamic>> members,
  List<Map<String, dynamic>> bookings,
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
  final alerts = <DashboardAlertItem>[];

  for (final member in activeMembers) {
    final memberId = (member['id'] ?? '').toString();
    if (memberId.isEmpty) continue;

    final snapshot = _memberRiskSnapshot(
      member: member,
      lastActivity: lastActivityByMember[memberId],
      attendedLast28Days: recentAttendanceByMember[memberId] ?? 0,
      now: now,
    );

    if (!snapshot.isAtRisk) continue;

    final name = dashboardMemberName(member);

    alerts.add(
      DashboardAlertItem(
        id: 'inactive-$memberId',
        type: 'inactive_member',
        title: '$name inactive',
        subtitle: snapshot.subtitle,
        priority: snapshot.priority,
      ),
    );
  }

  alerts.sort((a, b) => b.priority.compareTo(a.priority));
  return alerts.take(3).toList();
}

List<DashboardAlertItem> dashboardBuildLowOccupancyAlerts(
  List<Map<String, dynamic>> classesToday,
  List<Map<String, dynamic>> bookings,
) {
  final alerts = <DashboardAlertItem>[];

  for (final item in classesToday) {
    final classId = (item['id'] ?? '').toString();
    if (classId.isEmpty) continue;

    final maxSpots = dashboardReadInt(item, const [
      'max_spots',
      'capacity',
      'spots_total',
    ]);
    final reserved = bookings.where((b) {
      final sameClass = (b['class_id'] ?? '').toString() == classId;
      if (!sameClass) return false;
      final status = (b['status'] ?? '').toString().toLowerCase().trim();
      return status == 'booked' || status == 'attended';
    }).length;

    if (maxSpots <= 0) continue;

    final ratio = reserved / maxSpots;
    if (ratio > 0.40) continue;

    final title = (item['title'] ?? item['program_name'] ?? 'Class')
        .toString()
        .trim();
    final startsAt = DateTime.tryParse((item['starts_at'] ?? '').toString());

    var subtitle = '$reserved / $maxSpots booked';
    if (startsAt != null) {
      final hh = startsAt.toLocal().hour.toString().padLeft(2, '0');
      final mm = startsAt.toLocal().minute.toString().padLeft(2, '0');
      subtitle = '$hh:$mm · $subtitle';
    }

    alerts.add(
      DashboardAlertItem(
        id: 'low-occupancy-$classId',
        type: 'low_occupancy',
        title: title.isEmpty ? 'Class with low occupancy' : title,
        subtitle: subtitle,
        priority: 60 - reserved,
      ),
    );
  }

  return alerts;
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
      return const _MemberRiskSnapshot(
        subtitle: 'No bookings yet · member may need onboarding follow-up',
        priority: 85,
        isAtRisk: true,
      );
    }

    return const _MemberRiskSnapshot(
      subtitle: 'No bookings yet · new member or no clear pattern',
      priority: 5,
      isAtRisk: false,
    );
  }

  final inactiveDays = now.difference(lastActivity.toLocal()).inDays;

  if (attendedLast28Days >= 8) {
    if (inactiveDays >= 7) {
      return _MemberRiskSnapshot(
        subtitle: '$inactiveDays days inactive · high-frequency member at risk',
        priority: 90 + inactiveDays,
        isAtRisk: true,
      );
    }
  } else if (attendedLast28Days >= 4) {
    if (inactiveDays >= 10) {
      return _MemberRiskSnapshot(
        subtitle: '$inactiveDays days inactive · regular member at risk',
        priority: 70 + inactiveDays,
        isAtRisk: true,
      );
    }
  } else if (attendedLast28Days >= 1) {
    if (inactiveDays >= 14) {
      return _MemberRiskSnapshot(
        subtitle: '$inactiveDays days inactive · low-frequency member at risk',
        priority: 50 + inactiveDays,
        isAtRisk: true,
      );
    }
  } else {
    if (inactiveDays >= 21) {
      return _MemberRiskSnapshot(
        subtitle: '$inactiveDays days inactive · no recent pattern',
        priority: 35 + inactiveDays,
        isAtRisk: true,
      );
    }
  }

  if (inactiveDays <= 0) {
    return _MemberRiskSnapshot(
      subtitle: attendedLast28Days >= 4
          ? 'Active today · consistent member'
          : 'Active today',
      priority: -100,
      isAtRisk: false,
    );
  }

  if (inactiveDays == 1) {
    return _MemberRiskSnapshot(
      subtitle: attendedLast28Days >= 4
          ? 'Active 1 day ago · healthy rhythm'
          : 'Active 1 day ago',
      priority: -90,
      isAtRisk: false,
    );
  }

  return _MemberRiskSnapshot(
    subtitle: attendedLast28Days >= 8
        ? 'Active $inactiveDays days ago · usually very consistent'
        : attendedLast28Days >= 4
        ? 'Active $inactiveDays days ago · regular attendance'
        : attendedLast28Days >= 1
        ? 'Active $inactiveDays days ago'
        : 'Active $inactiveDays days ago · no recent pattern',
    priority: -inactiveDays,
    isAtRisk: false,
  );
}

class _MemberRiskSnapshot {
  final String subtitle;
  final int priority;
  final bool isAtRisk;

  const _MemberRiskSnapshot({
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
