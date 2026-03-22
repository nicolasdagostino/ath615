import 'supabase_bootstrap.dart';

class BookingRepository {
  Future<List<Map<String, dynamic>>> listMyBookings() async {
    final user = sb.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final data = await sb
        .from('class_bookings')
        .select('''
          id,
          class_id,
          member_id,
          status,
          created_at,
          classes (
            id,
            title,
            description,
            starts_at,
            duration_minutes,
            max_spots,
            location,
            status,
            program_id,
            coach_id
          )
        ''')
        .eq('member_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> cancelBooking(String bookingId) async {
    final result = await sb.rpc(
      'cancel_my_booking',
      params: {'p_booking_id': bookingId},
    );

    final ok = result['ok'] == true;
    if (!ok) {
      throw Exception(
        (result['message'] ?? 'Could not cancel booking').toString(),
      );
    }
  }
}
