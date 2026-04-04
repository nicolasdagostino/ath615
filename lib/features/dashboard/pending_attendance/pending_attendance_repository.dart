import '../../../core/supabase/gym_repository.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import 'pending_attendance_models.dart';

class PendingAttendanceRepository {
  final GymRepository _gymRepository;

  PendingAttendanceRepository({GymRepository? gymRepository})
    : _gymRepository = gymRepository ?? GymRepository();

  Future<List<PendingAttendanceDayGroup>> loadPendingAttendance({
    String? gymId,
  }) async {
    final resolvedGymId = (gymId ?? await _gymRepository.resolveGymId() ?? '')
        .trim();
    if (resolvedGymId.isEmpty) return const [];

    String? coachId;
    final user = sb.auth.currentUser;
    if (user != null) {
      try {
        final profile = await sb
            .from('profiles')
            .select('id, role')
            .eq('id', user.id)
            .maybeSingle();

        final role = (profile?['role'] ?? '').toString().toLowerCase().trim();
        if (role == 'coach') {
          coachId = (profile?['id'] ?? user.id).toString().trim();
        }
      } catch (_) {}
    }

    dynamic query = sb
        .from('class_bookings')
        .select('''
          id,
          class_id,
          status,
          classes!inner(
            id,
            gym_id,
            coach_id,
            title,
            starts_at,
            duration_minutes,
            location
          )
        ''')
        .eq('classes.gym_id', resolvedGymId);

    if (coachId != null && coachId.isNotEmpty) {
      query = query.eq('classes.coach_id', coachId);
    }

    final rows = await query.order('created_at', ascending: false);

    final rawRows = List<Map<String, dynamic>>.from(rows);
    final classIds = rawRows
        .map((row) => (row['class_id'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final classMetaById = <String, Map<String, dynamic>>{};
    if (classIds.isNotEmpty) {
      dynamic classMetaQuery = sb
          .from('v_classes_with_spots')
          .select('id, program_name, coach_name')
          .inFilter('id', classIds);

      if (coachId != null && coachId.isNotEmpty) {
        classMetaQuery = classMetaQuery.eq('coach_id', coachId);
      }

      final classMetaRows = await classMetaQuery;

      for (final raw in List<Map<String, dynamic>>.from(classMetaRows)) {
        final classId = (raw['id'] ?? '').toString().trim();
        if (classId.isEmpty) continue;
        classMetaById[classId] = raw;
      }
    }

    final now = DateTime.now();
    final grouped = <String, _PendingClassAccumulator>{};

    for (final row in rawRows) {
      final classId = (row['class_id'] ?? '').toString().trim();
      if (classId.isEmpty) continue;

      final classData = row['classes'];
      if (classData is! Map) continue;

      final startsAt = DateTime.tryParse(
        (classData['starts_at'] ?? '').toString(),
      )?.toLocal();
      if (startsAt == null) continue;
      if (!startsAt.isBefore(now)) continue;

      final status = (row['status'] ?? '').toString().toLowerCase().trim();
      final extra = classMetaById[classId] ?? const <String, dynamic>{};

      final current = grouped[classId];
      if (current == null) {
        grouped[classId] = _PendingClassAccumulator(
          classId: classId,
          title: (classData['title'] ?? '').toString().trim(),
          programName: (extra['program_name'] ?? '').toString().trim(),
          coachName: (extra['coach_name'] ?? '').toString().trim(),
          location: (classData['location'] ?? '').toString().trim(),
          startsAt: startsAt,
          durationMinutes: _asInt(classData['duration_minutes'], 60),
        );
      }

      final accumulator = grouped[classId]!;
      switch (status) {
        case 'attended':
          accumulator.attendedCount++;
          break;
        case 'cancelled':
          accumulator.cancelledCount++;
          break;
        case 'no_show':
          accumulator.noShowCount++;
          break;
        case 'booked':
          accumulator.bookedCount++;
          break;
      }
    }

    final pendingClasses = grouped.values
        .where((item) => item.bookedCount > 0)
        .map(
          (item) => PendingAttendanceClassItem(
            classId: item.classId,
            title: item.title,
            programName: item.programName,
            coachName: item.coachName,
            location: item.location,
            startsAt: item.startsAt,
            durationMinutes: item.durationMinutes,
            bookedCount: item.bookedCount,
            attendedCount: item.attendedCount,
            cancelledCount: item.cancelledCount,
            noShowCount: item.noShowCount,
            classItem: {
              'id': item.classId,
              'title': item.title,
              'program_name': item.programName,
              'coach_name': item.coachName,
              'location': item.location,
              'starts_at': item.startsAt.toIso8601String(),
              'duration_minutes': item.durationMinutes,
            },
          ),
        )
        .toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

    final byDay = <DateTime, List<PendingAttendanceClassItem>>{};
    for (final item in pendingClasses) {
      byDay.putIfAbsent(item.dayDate, () => []).add(item);
    }

    final groups = byDay.entries
        .map(
          (entry) => PendingAttendanceDayGroup(
            date: entry.key,
            classes: entry.value..sort((a, b) => b.startsAt.compareTo(a.startsAt)),
          ),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return groups;
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }
}

class _PendingClassAccumulator {
  final String classId;
  final String title;
  final String programName;
  final String coachName;
  final String location;
  final DateTime startsAt;
  final int durationMinutes;

  int bookedCount = 0;
  int attendedCount = 0;
  int cancelledCount = 0;
  int noShowCount = 0;

  _PendingClassAccumulator({
    required this.classId,
    required this.title,
    required this.programName,
    required this.coachName,
    required this.location,
    required this.startsAt,
    required this.durationMinutes,
  });
}
