class DashboardWeekRange {
  final DateTime start;
  final DateTime end;

  const DashboardWeekRange({required this.start, required this.end});
}

class DashboardWeekPerformance {
  final int bookings;
  final double attendanceRate;
  final double avgAthletesPerClass;
  final double occupancyRate;

  const DashboardWeekPerformance({
    required this.bookings,
    required this.attendanceRate,
    required this.avgAthletesPerClass,
    required this.occupancyRate,
  });
}

DateTime dashboardNextBirthdayDate(DateTime now, DateTime dob) {
  var year = now.year;
  var candidate = DateTime(year, dob.month, dob.day);
  final today = DateTime(now.year, now.month, now.day);
  if (candidate.isBefore(today)) {
    year += 1;
    candidate = DateTime(year, dob.month, dob.day);
  }
  return candidate;
}

DashboardWeekRange dashboardWeekRange({required int weekOffset}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startOfThisWeek = today.subtract(Duration(days: now.weekday - 1));
  final start = startOfThisWeek.add(Duration(days: 7 * weekOffset));
  final end = start.add(const Duration(days: 7));
  return DashboardWeekRange(start: start, end: end);
}

String dashboardMemberName(Map<String, dynamic> member) {
  final raw = (member['full_name'] ?? '').toString().trim();
  if (raw.isEmpty) return 'Athlete';
  return raw;
}

bool dashboardIsClassFull(Map<String, dynamic> item) {
  final maxSpots = dashboardReadInt(item, const [
    'max_spots',
    'capacity',
    'spots_total',
  ]);
  final remaining = dashboardReadNullableInt(item, const [
    'spots_left',
    'remaining_spots',
    'spots_remaining',
  ]);
  final booked = dashboardReadNullableInt(item, const [
    'booked_spots',
    'booking_count',
    'spots_taken',
  ]);

  if (remaining != null) return remaining <= 0;
  if (booked != null && maxSpots > 0) return booked >= maxSpots;
  return false;
}

int dashboardReadInt(Map<String, dynamic> item, List<String> keys) {
  return dashboardReadNullableInt(item, keys) ?? 0;
}

int? dashboardReadNullableInt(Map<String, dynamic> item, List<String> keys) {
  for (final key in keys) {
    final raw = item[key];
    if (raw == null) continue;
    if (raw is int) return raw;
    final parsed = int.tryParse(raw.toString());
    if (parsed != null) return parsed;
  }
  return null;
}
