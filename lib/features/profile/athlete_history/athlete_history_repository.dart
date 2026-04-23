import '../../../core/supabase/supabase_bootstrap.dart';
import '../../../core/supabase/gym_repository.dart';
import 'athlete_history_models.dart';

class AthleteHistoryRepository {
  final _gymRepository = GymRepository();
  Future<List<AthleteHistoryEntry>> listMyPastHistory() async {
    final user = sb.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final gymId = await _gymRepository.resolveGymId();

    dynamic query = sb
        .from('class_bookings')
        .select('''
          id,
          class_id,
          member_id,
          status,
          created_at,
          updated_at,
          classes!inner(
            id,
            title,
            description,
            starts_at,
            duration_minutes,
            location,
            status,
            gym_id
          )
        ''')
        .eq('member_id', user.id);

    if (gymId != null && gymId.trim().isNotEmpty) {
      query = query.eq('classes.gym_id', gymId.trim());
    }

    final data = await query.order('created_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(data);
    final classIds = rows
        .map((row) => (row['class_id'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final programNamesByClassId = <String, String>{};
    if (classIds.isNotEmpty) {
      dynamic classViewQuery = sb
          .from('v_classes_with_spots')
          .select('id, program_name')
          .inFilter('id', classIds);

      if (gymId != null && gymId.trim().isNotEmpty) {
        classViewQuery = classViewQuery.eq('gym_id', gymId.trim());
      }

      final classViewRows = await classViewQuery;

      for (final rawView in List<Map<String, dynamic>>.from(classViewRows)) {
        final classId = (rawView['id'] ?? '').toString().trim();
        final programName = (rawView['program_name'] ?? '').toString().trim();
        if (classId.isEmpty) continue;
        if (programName.isEmpty || programName.toLowerCase() == 'null')
          continue;
        programNamesByClassId[classId] = programName;
      }
    }

    final now = DateTime.now();
    final bestByClass = <String, AthleteHistoryEntry>{};

    for (final raw in rows) {
      final status = AthleteHistoryEntry.statusFromRaw(
        (raw['status'] ?? '').toString(),
      );
      if (status == null) continue;

      final classData = raw['classes'];
      if (classData is! Map<String, dynamic>) continue;

      final startsAtRaw = (classData['starts_at'] ?? '').toString().trim();
      if (startsAtRaw.isEmpty) continue;

      DateTime startsAt;
      try {
        startsAt = DateTime.parse(startsAtRaw).toLocal();
      } catch (_) {
        continue;
      }

      final durationMinutes = _asInt(classData['duration_minutes'], 60);
      final classEndsAt = startsAt.add(Duration(minutes: durationMinutes));
      if (!classEndsAt.isBefore(now)) continue;

      final classId = (raw['class_id'] ?? classData['id'] ?? '')
          .toString()
          .trim();
      if (classId.isEmpty) continue;

      final rawTitle = (classData['title'] ?? '').toString().trim();
      final rawProgramName = (programNamesByClassId[classId] ?? '')
          .toString()
          .trim();

      final normalizedTitle =
          rawTitle.isNotEmpty && rawTitle.toLowerCase() != 'null'
          ? rawTitle
          : rawProgramName.isNotEmpty && rawProgramName.toLowerCase() != 'null'
          ? rawProgramName
          : 'Class';

      final entry = AthleteHistoryEntry(
        bookingId: (raw['id'] ?? '').toString(),
        classId: classId,
        status: status,
        classStartsAt: startsAt,
        durationMinutes: _asInt(classData['duration_minutes'], 60),
        title: normalizedTitle,
        description: (classData['description'] ?? '').toString().trim(),
        location: (classData['location'] ?? '').toString().trim(),
        bookedAt: _parseDateTime(raw['created_at']),
        updatedAt: _parseDateTime(raw['updated_at']),
      );

      final existing = bestByClass[classId];
      if (existing == null || _compareEntries(entry, existing) < 0) {
        bestByClass[classId] = entry;
      }
    }

    final items = bestByClass.values.toList()
      ..sort((a, b) => b.classStartsAt.compareTo(a.classStartsAt));

    return items;
  }

  int _compareEntries(AthleteHistoryEntry a, AthleteHistoryEntry b) {
    final rankA = _statusRank(a.status);
    final rankB = _statusRank(b.status);
    if (rankA != rankB) {
      return rankA.compareTo(rankB);
    }

    final aMoment = a.updatedAt ?? a.bookedAt ?? a.classStartsAt;
    final bMoment = b.updatedAt ?? b.bookedAt ?? b.classStartsAt;
    return bMoment.compareTo(aMoment);
  }

  int _statusRank(AthleteHistoryStatus status) {
    switch (status) {
      case AthleteHistoryStatus.attended:
        return 0;
      case AthleteHistoryStatus.noShow:
        return 1;
      case AthleteHistoryStatus.booked:
        return 2;
      case AthleteHistoryStatus.cancelled:
        return 3;
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }
}
