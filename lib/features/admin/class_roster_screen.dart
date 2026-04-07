import 'package:flutter/material.dart';

import '../../core/supabase/class_attendance_repository.dart';
import '../../core/supabase/supabase_bootstrap.dart';
import '../../shared/widgets/app_toast.dart';

class ClassRosterScreen extends StatefulWidget {
  final String classId;
  final String classTitle;
  final String? classTime;
  final String? gymId;

  const ClassRosterScreen({
    super.key,
    required this.classId,
    required this.classTitle,
    this.classTime,
    this.gymId,
  });

  @override
  State<ClassRosterScreen> createState() => _ClassRosterScreenState();
}

class _ClassRosterScreenState extends State<ClassRosterScreen> {
  final _attendanceRepo = ClassAttendanceRepository();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _athletes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      List<Map<String, dynamic>> rows;

      try {
        rows = await _attendanceRepo.listClassBookings(widget.classId);
      } catch (_) {
        dynamic fallbackQuery = sb
            .from('class_bookings')
            .select('''
              id,
              status,
              member_id,
              classes!inner(id, gym_id),
              profiles(full_name,email)
            ''')
            .eq('class_id', widget.classId);

        final fallbackGymId = (widget.gymId ?? '').trim();
        if (fallbackGymId.isNotEmpty) {
          fallbackQuery = fallbackQuery.eq('classes.gym_id', fallbackGymId);
        }

        final data = await fallbackQuery.order('created_at', ascending: true);

        rows = List<Map<String, dynamic>>.from(data);
      }

      if (!mounted) return;
      setState(() {
        _athletes = rows;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _athleteName(Map<String, dynamic> item) {
    final profile = item['profiles'];
    if (profile is Map<String, dynamic>) {
      final name = (profile['full_name'] ?? '').toString().trim();
      if (name.isNotEmpty) return name;
      final email = (profile['email'] ?? '').toString().trim();
      if (email.isNotEmpty) return email;
    }

    final member = item['member'];
    if (member is Map<String, dynamic>) {
      final name = (member['full_name'] ?? '').toString().trim();
      if (name.isNotEmpty) return name;
      final email = (member['email'] ?? '').toString().trim();
      if (email.isNotEmpty) return email;
    }

    final fullName = (item['full_name'] ?? item['member_name'] ?? '')
        .toString()
        .trim();
    if (fullName.isNotEmpty) return fullName;

    final email = (item['email'] ?? item['member_email'] ?? '')
        .toString()
        .trim();
    if (email.isNotEmpty) return email;

    return 'Athlete';
  }

  String _bookingId(Map<String, dynamic> item) {
    final id = (item['id'] ?? item['booking_id'] ?? '').toString().trim();
    return id;
  }

  Future<void> _setStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      await _attendanceRepo.adminUpdateBookingStatus(
        bookingId: bookingId,
        status: status,
      );
      await _load();

      if (!mounted) return;
      AppToast.show(
        context,
        'Booking marked as $status',
        icon: Icons.check_circle_outline_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Widget _statusChip(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'attended':
        bg = const Color(0xFFDDF5E5);
        fg = const Color(0xFF16A34A);
        break;
      case 'no_show':
        bg = const Color(0xFFFEE4E2);
        fg = const Color(0xFFB42318);
        break;
      case 'cancelled':
        bg = const Color(0xFFF2F4F7);
        fg = const Color(0xFF667085);
        break;
      default:
        bg = const Color(0xFFE6EDF7);
        fg = const Color(0xFF245BEB);
        break;
    }

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _row(Map<String, dynamic> item) {
    final bookingId = _bookingId(item);
    final status = (item['status'] ?? 'booked').toString();
    final name = _athleteName(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D0D12),
                  ),
                ),
              ),
              _statusChip(status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: bookingId.isEmpty
                      ? null
                      : () => _setStatus(
                          bookingId: bookingId,
                          status: 'attended',
                        ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Attended'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: bookingId.isEmpty
                      ? null
                      : () =>
                            _setStatus(bookingId: bookingId, status: 'no_show'),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('No-show'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if ((widget.classTime ?? '').trim().isNotEmpty) widget.classTime!.trim(),
      '${_athletes.length} athletes',
    ].join(' · ');

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(widget.classTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB59B6A)),
            )
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFB42318)),
              ),
            )
          : _athletes.isEmpty
          ? const Center(
              child: Text(
                'No athletes booked for this class',
                style: TextStyle(color: Color(0xFF667085)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _athletes.map(_row).toList(),
              ),
            ),
    );
  }
}
