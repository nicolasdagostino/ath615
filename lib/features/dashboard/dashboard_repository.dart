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
    final classesToday = await _loadTodayClasses(gymId);
    final bookings = await _loadGymBookings(gymId);

    final todayStats = _buildTodayStats(classesToday, bookings);
    final memberStats = _buildMemberStats(members);
    final engagementStats = _buildEngagementStats(members, bookings);
    final alerts = _buildAlerts(
      members: members,
      classesToday: classesToday,
      bookings: bookings,
    );

    return DashboardData(
      today: todayStats,
      members: memberStats,
      engagement: engagementStats,
      alerts: alerts,
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

  Future<List<Map<String, dynamic>>> _loadTodayClasses(String? gymId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
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

    final Map<String, DateTime> lastActivityByMember = {};

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

      final current = lastActivityByMember[memberId];
      if (current == null || activityAt.isAfter(current)) {
        lastActivityByMember[memberId] = activityAt;
      }
    }

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

  List<DashboardAlertItem> _buildAlerts({
    required List<Map<String, dynamic>> members,
    required List<Map<String, dynamic>> classesToday,
    required List<Map<String, dynamic>> bookings,
  }) {
    final alerts = <DashboardAlertItem>[];
    alerts.addAll(_buildBirthdayAlerts(members));
    alerts.addAll(_buildLowOccupancyAlerts(classesToday, bookings));
    return alerts;
  }

  List<DashboardAlertItem> _buildBirthdayAlerts(
    List<Map<String, dynamic>> members,
  ) {
    final now = DateTime.now();
    final alerts = <DashboardAlertItem>[];

    for (final member in members) {
      if (member['is_active'] != true) continue;

      final name = (member['full_name'] ?? 'Athlete').toString().trim().isEmpty
          ? 'Athlete'
          : (member['full_name'] ?? 'Athlete').toString().trim();

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
        ),
      );
    }

    alerts.sort((a, b) => a.title.compareTo(b.title));
    return alerts.take(4).toList();
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
        ),
      );
    }

    return alerts.take(4).toList();
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
