import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/supabase/class_attendance_repository.dart';
import '../../shared/widgets/app_card.dart';

class ClassAttendanceScreen extends StatefulWidget {
  final Map<String, dynamic> classItem;

  const ClassAttendanceScreen({super.key, required this.classItem});

  @override
  State<ClassAttendanceScreen> createState() => _ClassAttendanceScreenState();
}

class _ClassAttendanceScreenState extends State<ClassAttendanceScreen> {
  TextStyle _font(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = const Color(0xFF111318),
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.barlowCondensed(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  final _repo = ClassAttendanceRepository();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

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
      final classId = widget.classItem['id'].toString();
      final data = await _repo.listClassBookings(classId);

      if (!mounted) return;
      setState(() {
        _items = data;
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

  Future<void> _setStatus(String bookingId, String status) async {
    try {
      await _repo.adminUpdateBookingStatus(
        bookingId: bookingId,
        status: status,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  bool _canMarkAttended() {
    try {
      final dt = DateTime.parse(
        widget.classItem['starts_at'].toString(),
      ).toLocal();
      return !dt.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'attended':
        return const Color(0xFF3D8D5C);
      case 'booked':
        return const Color(0xFFB59B6A);
      case 'cancelled':
        return const Color(0xFFC65F5F);
      default:
        return const Color(0xFF818898);
    }
  }

  Color _statusBackground(String status) {
    switch (status) {
      case 'attended':
        return const Color(0xFFEAF6EE);
      case 'booked':
        return const Color(0xFFF7F3EA);
      case 'cancelled':
        return const Color(0xFFFDECEC);
      default:
        return const Color(0xFFF2F4F7);
    }
  }

  Widget _summaryChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF98A2B3)),
          const SizedBox(width: 8),
          Text(
            label,
            style: _font(
              12,
              weight: FontWeight.w700,
              color: const Color(0xFF344054),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.classItem['title'] ?? '').toString();
    final program = (widget.classItem['program_name'] ?? 'Class').toString();
    final coach = (widget.classItem['coach_name'] ?? 'TBD').toString();
    final duration = (widget.classItem['duration_minutes'] ?? 60).toString();
    final bookedCount = _items
        .where((e) => (e['status'] ?? '').toString() == 'booked')
        .length;
    final attendedCount = _items
        .where((e) => (e['status'] ?? '').toString() == 'attended')
        .length;

    String subtitle = '';
    try {
      final dt = DateTime.parse(
        widget.classItem['starts_at'].toString(),
      ).toLocal();
      subtitle = DateFormat('EEEE, MMM d · HH:mm').format(dt);
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        'ATTENDANCE',
                        style: _font(
                          18,
                          weight: FontWeight.w800,
                          color: const Color(0xFF0E0E11),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F3EA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: Color(0xFFB59B6A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F3EA),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.groups_2_rounded,
                                size: 22,
                                color: Color(0xFFB59B6A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    program.toUpperCase(),
                                    style: _font(
                                      22,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFF111318),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty ||
                                      title.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      [
                                        if (title.isNotEmpty &&
                                            title.toLowerCase() !=
                                                program.toLowerCase())
                                          title,
                                        if (subtitle.isNotEmpty) subtitle,
                                      ].join(' · '),
                                      style: _font(
                                        13,
                                        weight: FontWeight.w500,
                                        color: const Color(0xFF667085),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _summaryChip(
                              icon: Icons.timer_outlined,
                              label: '$duration min',
                            ),
                            _summaryChip(
                              icon: Icons.person_outline_rounded,
                              label: 'Coach: $coach',
                            ),
                            _summaryChip(
                              icon: Icons.event_available_rounded,
                              label: 'Booked: $bookedCount',
                            ),
                            _summaryChip(
                              icon: Icons.check_circle_outline_rounded,
                              label: 'Attended: $attendedCount',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Text(
                      _error!,
                      style: _font(
                        13,
                        weight: FontWeight.w500,
                        color: const Color(0xFFB42318),
                      ),
                    )
                  else if (_items.isEmpty)
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 26,
                      ),
                      child: Center(
                        child: Text(
                          'No bookings for this class',
                          style: _font(
                            14,
                            weight: FontWeight.w500,
                            color: const Color(0xFF667085),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._items.map((item) {
                      final bookingId = item['booking_id'].toString();
                      final status = (item['status'] ?? '').toString();
                      final name = (item['member_name'] ?? 'Athlete')
                          .toString();
                      final email = (item['member_email'] ?? '').toString();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      size: 20,
                                      color: Color(0xFF98A2B3),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name.toUpperCase(),
                                          style: _font(
                                            18,
                                            weight: FontWeight.w800,
                                            color: const Color(0xFF111318),
                                            letterSpacing: -0.15,
                                          ),
                                        ),
                                        if (email.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            email,
                                            style: _font(
                                              13,
                                              weight: FontWeight.w500,
                                              color: const Color(0xFF667085),
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 26,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusBackground(status),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: _statusBackground(status),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      status.toUpperCase(),
                                      style: _font(
                                        10,
                                        weight: FontWeight.w700,
                                        color: _statusColor(status),
                                        letterSpacing: 0.25,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (status != 'attended' &&
                                      _canMarkAttended())
                                    _ActionButton(
                                      label: 'Mark attended',
                                      backgroundColor: const Color(0xFFEAF6EE),
                                      textColor: const Color(0xFF3D8D5C),
                                      borderColor: const Color(0xFFD6ECDD),
                                      icon: Icons.check_circle_outline_rounded,
                                      onTap: () =>
                                          _setStatus(bookingId, 'attended'),
                                    ),
                                  if (status != 'booked')
                                    _ActionButton(
                                      label: 'Set booked',
                                      backgroundColor: const Color(0xFFF7F3EA),
                                      textColor: const Color(0xFFB59B6A),
                                      borderColor: const Color(0xFFE8DDC8),
                                      icon: Icons.event_available_rounded,
                                      onTap: () =>
                                          _setStatus(bookingId, 'booked'),
                                    ),
                                  if (status != 'cancelled')
                                    _ActionButton(
                                      label: 'Cancel',
                                      backgroundColor: const Color(0xFFFDECEC),
                                      textColor: const Color(0xFFC65F5F),
                                      borderColor: const Color(0xFFF3D6D6),
                                      icon: Icons.close_rounded,
                                      onTap: () =>
                                          _setStatus(bookingId, 'cancelled'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.barlowCondensed(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
