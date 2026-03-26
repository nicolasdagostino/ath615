import '../../core/supabase/gym_repository.dart';
import '../../core/supabase/supabase_bootstrap.dart';
import 'dashboard_models.dart';

class DashboardRepository {
  final GymRepository _gymRepository;

  DashboardRepository({GymRepository? gymRepository})
    : _gymRepository = gymRepository ?? GymRepository();

  Future<DashboardData> loadDashboard() async {
    final gymId = await _gymRepository.resolveGymId();

    final members = await _loadMemberRows(gymId);
    final classesToday = await _loadDayClasses(gymId, dayOffset: 0);
    final classesTomorrow = await _loadDayClasses(gymId, dayOffset: 1);
    final thisWeekClasses = await _loadWeekClasses(gymId, weekOffset: 0);
    final lastWeekClasses = await _loadWeekClasses(gymId, weekOffset: -1);
    final bookings = await _loadGymBookings(gymId);
    final todayWorkouts = await _loadTodayWorkouts(gymId);

    final todayStats = _buildTodayStats(classesToday, bookings);
    final memberStats = _buildMemberStats(members);
    final engagementStats = _buildEngagementStats(members, bookings);
    final performanceStats = _buildPerformanceStats(
      thisWeekClasses: thisWeekClasses,
      lastWeekClasses: lastWeekClasses,
      bookings: bookings,
    );
    final tomorrowStats = _buildTomorrowStats(classesTomorrow, bookings);
    final memberActivity = _buildMemberActivity(members, bookings);
    final alerts = _buildAlerts(
      members: members,
      classesToday: classesToday,
      bookings: bookings,
    );
    final nextClass = _buildNextClass(classesToday, classesTomorrow, bookings);
    final workoutStatus = _buildWorkoutStatus(
      classesToday: classesToday,
      todayWorkouts: todayWorkouts,
    );
    final todayHighlights = _buildTodayHighlights(
      members: members,
      workoutStatus: workoutStatus,
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
      gymId: gymId,
    );
  }

  Future<List<Map<String, dynamic>>> _loadMemberRows(String? gymId) async {
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

  Future<List<Map<String, dynamic>>> _loadDayClasses(
    String? gymId, {
    required int dayOffset,
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

    final data = await query.order('starts_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> _loadWeekClasses(
    String? gymId, {
    required int weekOffset,
  }) async {
    final range = _weekRange(weekOffset: weekOffset);

    dynamic query = sb
        .from('v_classes_with_spots')
        .select('*')
        .gte('starts_at', range.start.toUtc().toIso8601String())
        .lt('starts_at', range.end.toUtc().toIso8601String())
        .eq('status', 'scheduled');

    if (gymId != null && gymId.isNotEmpty) {
      query = query.eq('gym_id', gymId);
    }

    final data = await query.order('starts_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> _loadGymBookings(String? gymId) async {
    dynamic query = sb
        .from('class_bookings')
        .select(
          'id, member_id, class_id, status, created_at, classes!inner(id, gym_id, starts_at)',
        );

    if (gymId != null && gymId.isNotEmpty) {
      query = query.eq('classes.gym_id', gymId);
    }

    final data = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> _loadTodayWorkouts(String? gymId) async {
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

  DashboardTodayStats _buildTodayStats(
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
        .where((item) => _isClassFull(item))
        .length;

    return DashboardTodayStats(
      classesToday: classesToday.length,
      bookingsToday: bookingsToday,
      attendanceToday: attendanceToday,
      fullClassesToday: fullClassesToday,
    );
  }

  DashboardMemberStats _buildMemberStats(List<Map<String, dynamic>> members) {
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

  DashboardEngagementStats _buildEngagementStats(
    List<Map<String, dynamic>> members,
    List<Map<String, dynamic>> bookings,
  ) {
    final now = DateTime.now();
    final activeMemberIds = members
        .where((m) => m['is_active'] == true)
        .map((m) => (m['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    final lastActivityByMember = _lastActivityByMember(
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

  DashboardPerformanceStats _buildPerformanceStats({
    required List<Map<String, dynamic>> thisWeekClasses,
    required List<Map<String, dynamic>> lastWeekClasses,
    required List<Map<String, dynamic>> bookings,
  }) {
    final thisWeek = _computeWeekPerformance(
      classes: thisWeekClasses,
      bookings: bookings,
      weekOffset: 0,
    );
    final lastWeek = _computeWeekPerformance(
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

  DashboardTomorrowStats _buildTomorrowStats(
    List<Map<String, dynamic>> classesTomorrow,
    List<Map<String, dynamic>> bookings,
  ) {
    final riskItems = <DashboardRiskClassItem>[];

    for (final item in classesTomorrow) {
      final classId = (item['id'] ?? '').toString();
      if (classId.isEmpty) continue;

      final maxSpots = _readInt(item, const [
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

  List<DashboardMemberActivityItem> _buildMemberActivity(
    List<Map<String, dynamic>> members,
    List<Map<String, dynamic>> bookings,
  ) {
    final now = DateTime.now();
    final activeMembers = members.where((m) => m['is_active'] == true).toList();

    final activeMemberIds = activeMembers
        .map((m) => (m['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    final lastActivityByMember = _lastActivityByMember(
      bookings,
      activeMemberIds,
    );
    final items = <DashboardMemberActivityItem>[];

    for (final member in activeMembers) {
      final memberId = (member['id'] ?? '').toString();
      if (memberId.isEmpty) continue;

      final name = _memberName(member);
      final last = lastActivityByMember[memberId];

      if (last == null) {
        items.add(
          DashboardMemberActivityItem(
            id: memberId,
            name: name,
            subtitle: 'No booking activity yet',
            priority: 1000,
            isAtRisk: true,
          ),
        );
        continue;
      }

      final days = now.difference(last.toLocal()).inDays;

      String subtitle;
      if (days <= 0) {
        subtitle = 'Active today';
      } else if (days == 1) {
        subtitle = 'Active 1 day ago';
      } else {
        subtitle = 'Active $days days ago';
      }

      items.add(
        DashboardMemberActivityItem(
          id: memberId,
          name: name,
          subtitle: days >= 10 ? '$days days without activity' : subtitle,
          priority: days >= 10 ? days : -days,
          isAtRisk: days >= 10,
        ),
      );
    }

    items.sort((a, b) => b.priority.compareTo(a.priority));
    return items.take(5).toList();
  }

  DashboardNextClassItem? _buildNextClass(
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

    final maxSpots = _readInt(nextItem, const [
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

  DashboardWorkoutStatus _buildWorkoutStatus({
    required List<Map<String, dynamic>> classesToday,
    required List<Map<String, dynamic>> todayWorkouts,
  }) {
    var missing = 0;
    for (final item in classesToday) {
      final hasWorkout = (item['workout_id'] ?? '')
          .toString()
          .trim()
          .isNotEmpty;
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

  List<DashboardTodayHighlightItem> _buildTodayHighlights({
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

      final name = _memberName(member);
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

  _WeekPerformance _computeWeekPerformance({
    required List<Map<String, dynamic>> classes,
    required List<Map<String, dynamic>> bookings,
    required int weekOffset,
  }) {
    final range = _weekRange(weekOffset: weekOffset);
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

    return _WeekPerformance(
      bookings: bookingsCount,
      attendanceRate: attendanceRate,
      avgAthletesPerClass: avgAthletesPerClass,
    );
  }

  List<DashboardAlertItem> _buildAlerts({
    required List<Map<String, dynamic>> members,
    required List<Map<String, dynamic>> classesToday,
    required List<Map<String, dynamic>> bookings,
  }) {
    final alerts = <DashboardAlertItem>[];

    alerts.addAll(_buildInactiveMemberAlerts(members, bookings));
    alerts.addAll(_buildBirthdayAlerts(members));
    alerts.addAll(_buildLowOccupancyAlerts(classesToday, bookings));

    alerts.sort((a, b) => b.priority.compareTo(a.priority));
    return alerts.take(6).toList();
  }

  List<DashboardAlertItem> _buildBirthdayAlerts(
    List<Map<String, dynamic>> members,
  ) {
    final now = DateTime.now();
    final alerts = <DashboardAlertItem>[];

    for (final member in members) {
      if (member['is_active'] != true) continue;

      final name = _memberName(member);
      final dobRaw = (member['date_of_birth'] ?? '').toString().trim();
      final dob = DateTime.tryParse(dobRaw);
      if (dob == null) continue;

      final nextBirthday = _nextBirthdayDate(now, dob);
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

  List<DashboardAlertItem> _buildInactiveMemberAlerts(
    List<Map<String, dynamic>> members,
    List<Map<String, dynamic>> bookings,
  ) {
    final now = DateTime.now();
    final activeMembers = members.where((m) => m['is_active'] == true).toList();

    final activeMemberIds = activeMembers
        .map((m) => (m['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    final lastActivityByMember = _lastActivityByMember(
      bookings,
      activeMemberIds,
    );
    final alerts = <DashboardAlertItem>[];

    for (final member in activeMembers) {
      final memberId = (member['id'] ?? '').toString();
      if (memberId.isEmpty) continue;

      final last = lastActivityByMember[memberId];
      final inactiveDays = last == null
          ? 999
          : now.difference(last.toLocal()).inDays;

      if (inactiveDays < 10) continue;

      final name = _memberName(member);
      final subtitle = last == null
          ? 'No booking activity yet'
          : '$inactiveDays days without activity';

      alerts.add(
        DashboardAlertItem(
          id: 'inactive-$memberId',
          type: 'inactive_member',
          title: '$name inactive',
          subtitle: subtitle,
          priority: last == null ? 100 : inactiveDays,
        ),
      );
    }

    alerts.sort((a, b) => b.priority.compareTo(a.priority));
    return alerts.take(3).toList();
  }

  DateTime _nextBirthdayDate(DateTime now, DateTime dob) {
    var year = now.year;
    var candidate = DateTime(year, dob.month, dob.day);
    final today = DateTime(now.year, now.month, now.day);
    if (candidate.isBefore(today)) {
      year += 1;
      candidate = DateTime(year, dob.month, dob.day);
    }
    return candidate;
  }

  List<DashboardAlertItem> _buildLowOccupancyAlerts(
    List<Map<String, dynamic>> classesToday,
    List<Map<String, dynamic>> bookings,
  ) {
    final alerts = <DashboardAlertItem>[];

    for (final item in classesToday) {
      final classId = (item['id'] ?? '').toString();
      if (classId.isEmpty) continue;

      final maxSpots = _readInt(item, const [
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

  Map<String, DateTime> _lastActivityByMember(
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

  _WeekRange _weekRange({required int weekOffset}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfThisWeek = today.subtract(Duration(days: now.weekday - 1));
    final start = startOfThisWeek.add(Duration(days: 7 * weekOffset));
    final end = start.add(const Duration(days: 7));
    return _WeekRange(start: start, end: end);
  }

  String _memberName(Map<String, dynamic> member) {
    final raw = (member['full_name'] ?? '').toString().trim();
    if (raw.isEmpty) return 'Athlete';
    return raw;
  }

  bool _isClassFull(Map<String, dynamic> item) {
    final maxSpots = _readInt(item, const [
      'max_spots',
      'capacity',
      'spots_total',
    ]);
    final remaining = _readNullableInt(item, const [
      'spots_left',
      'remaining_spots',
      'spots_remaining',
    ]);
    final booked = _readNullableInt(item, const [
      'booked_spots',
      'booking_count',
      'spots_taken',
    ]);

    if (remaining != null) return remaining <= 0;
    if (booked != null && maxSpots > 0) return booked >= maxSpots;
    return false;
  }

  int _readInt(Map<String, dynamic> item, List<String> keys) {
    return _readNullableInt(item, keys) ?? 0;
  }

  int? _readNullableInt(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final raw = item[key];
      if (raw == null) continue;
      if (raw is int) return raw;
      final parsed = int.tryParse(raw.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }
}

class _WeekRange {
  final DateTime start;
  final DateTime end;

  const _WeekRange({required this.start, required this.end});
}

class _WeekPerformance {
  final int bookings;
  final double attendanceRate;
  final double avgAthletesPerClass;

  const _WeekPerformance({
    required this.bookings,
    required this.attendanceRate,
    required this.avgAthletesPerClass,
  });
}
