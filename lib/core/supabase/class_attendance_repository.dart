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
}
