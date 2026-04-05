import 'supabase_bootstrap.dart';

class ClassAttendanceRepository {
  Future<List<Map<String, dynamic>>> listClassBookings(String classId) async {
    final data = await sb.rpc(
      'admin_list_class_bookings',
      params: {'p_class_id': classId},
    );
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> adminUpdateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    await sb.rpc(
      'admin_update_booking_status',
      params: {'p_booking_id': bookingId, 'p_status': status},
    );
  }

  Future<void> checkInToClass(String classId) async {
    await sb.rpc('my_check_in_to_class', params: {'p_class_id': classId});
  }

  Future<void> adminBookMemberIntoClass({
    required String classId,
    required String memberId,
  }) async {
    final result = await sb.rpc(
      'book_class_for_member',
      params: {'p_class_id': classId, 'p_member_id': memberId},
    );

    final ok = result['ok'] == true;
    if (!ok) {
      throw Exception(
        (result['message'] ?? 'Could not add member to class').toString(),
      );
    }
  }
}
