import 'package:flutter/foundation.dart';

enum AthleteHistoryStatus { attended, cancelled, noShow, booked }

enum AthleteHistoryFilter { all, attended, missed, cancelled }

@immutable
class AthleteHistoryEntry {
  final String bookingId;
  final String classId;
  final AthleteHistoryStatus status;
  final DateTime classStartsAt;
  final int durationMinutes;
  final String title;
  final String description;
  final String location;
  final DateTime? bookedAt;
  final DateTime? updatedAt;

  const AthleteHistoryEntry({
    required this.bookingId,
    required this.classId,
    required this.status,
    required this.classStartsAt,
    required this.durationMinutes,
    required this.title,
    required this.description,
    required this.location,
    this.bookedAt,
    this.updatedAt,
  });

  String get statusKey {
    switch (status) {
      case AthleteHistoryStatus.attended:
        return 'attended';
      case AthleteHistoryStatus.cancelled:
        return 'cancelled';
      case AthleteHistoryStatus.noShow:
        return 'no_show';
      case AthleteHistoryStatus.booked:
        return 'missed';
    }
  }

  bool matchesFilter(AthleteHistoryFilter filter) {
    switch (filter) {
      case AthleteHistoryFilter.all:
        return true;
      case AthleteHistoryFilter.attended:
        return status == AthleteHistoryStatus.attended;
      case AthleteHistoryFilter.missed:
        return status == AthleteHistoryStatus.noShow ||
            status == AthleteHistoryStatus.booked;
      case AthleteHistoryFilter.cancelled:
        return status == AthleteHistoryStatus.cancelled;
    }
  }

  static AthleteHistoryStatus? statusFromRaw(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'attended':
        return AthleteHistoryStatus.attended;
      case 'cancelled':
        return AthleteHistoryStatus.cancelled;
      case 'no_show':
        return AthleteHistoryStatus.noShow;
      case 'booked':
        return AthleteHistoryStatus.booked;
      default:
        return null;
    }
  }
}

class AthleteHistoryCounts {
  final int total;
  final int attended;
  final int missed;
  final int cancelled;

  const AthleteHistoryCounts({
    required this.total,
    required this.attended,
    required this.missed,
    required this.cancelled,
  });
}
