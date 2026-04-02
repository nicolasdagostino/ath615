import 'package:flutter/foundation.dart';

@immutable
class PendingAttendanceClassItem {
  final String classId;
  final String title;
  final String programName;
  final String coachName;
  final String location;
  final DateTime startsAt;
  final int durationMinutes;
  final int bookedCount;
  final int attendedCount;
  final int cancelledCount;
  final int noShowCount;
  final Map<String, dynamic> classItem;

  const PendingAttendanceClassItem({
    required this.classId,
    required this.title,
    required this.programName,
    required this.coachName,
    required this.location,
    required this.startsAt,
    required this.durationMinutes,
    required this.bookedCount,
    required this.attendedCount,
    required this.cancelledCount,
    required this.noShowCount,
    required this.classItem,
  });

  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    if (programName.trim().isNotEmpty) return programName.trim();
    return 'Class';
  }

  DateTime get dayDate => DateTime(startsAt.year, startsAt.month, startsAt.day);
}

@immutable
class PendingAttendanceDayGroup {
  final DateTime date;
  final List<PendingAttendanceClassItem> classes;

  const PendingAttendanceDayGroup({
    required this.date,
    required this.classes,
  });
}
