import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_text.dart';

import '../../core/supabase/booking_repository.dart';
import '../../core/supabase/class_attendance_repository.dart';
import '../../core/supabase/class_repository.dart';
import '../../core/supabase/membership_repository.dart';
import '../../core/supabase/supabase_bootstrap.dart';
import '../admin/class_attendance_screen.dart';
import '../../shared/widgets/app_card.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const int _athleteVisibleDays = 14;
  static const int _adminPastDays = 7;
  static const int _adminFutureDays = 14;

  final _classRepo = ClassRepository();
  final _bookingRepo = BookingRepository();
  final _attendanceRepo = ClassAttendanceRepository();
  final _membershipRepo = MembershipRepository();

  bool _loading = true;
  String? _error;

  DateTime _selectedDay = DateTime.now();
  final ScrollController _daysScrollController = ScrollController();
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _myBookings = [];
  Map<String, dynamic>? _activeMembership;
  String? _busyClassId;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToSelectedDay();
    });
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final today = DateTime.now();
    final currentIso = _dateIso(_selectedDay);
    final todayIso = _dateIso(today);
    if (currentIso != todayIso) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (mounted) {}

        setState(() {
          _selectedDay = today;
        });
        _load();
      });
    }
  }

  @override
  void dispose() {
    _daysScrollController.dispose();
    super.dispose();
  }

  String _dateIso(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

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

  Color _programColor(String programName) {
    final value = programName.trim().toLowerCase();

    if (value.contains('crossfit') || value.contains('wod')) {
      return const Color(0xFF245BEB);
    }
    if (value.contains('hyrox') || value.contains('engine')) {
      return const Color(0xFF16A34A);
    }
    if (value.contains('strength') || value.contains('barbell')) {
      return const Color(0xFFB54708);
    }
    if (value.contains('gymnastics')) {
      return const Color(0xFF7A5AF8);
    }
    if (value.contains('conditioning')) {
      return const Color(0xFF0891B2);
    }

    return const Color(0xFF667085);
  }

  void _showToast(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? const Color(0xFFB42318)
            : const Color(0xFF111318),
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: _font(14, weight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      var isAdmin = false;
      final user = sb.auth.currentUser;
      if (user != null) {
        final byId = await sb
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        final role = (byId?['role'] ?? '').toString().toLowerCase().trim();
        isAdmin = role == 'admin';
      }

      final classes = await _classRepo.listClassesForDate(
        _dateIso(_selectedDay),
        includePast: isAdmin,
      );
      final bookings = await _bookingRepo.listMyBookings();
      final activeMembership = await _membershipRepo.myActiveMembership();

      if (!mounted) return;
      setState(() {
        _classes = classes;
        _myBookings = bookings;
        _activeMembership = activeMembership;
        _isAdmin = isAdmin;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToSelectedDay(animated: true);
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

  Map<String, dynamic>? _bookingForClass(String classId) {
    final matches = _myBookings
        .where((b) => (b['class_id'] ?? '').toString() == classId)
        .toList();

    if (matches.isEmpty) return null;

    int rank(String status) {
      switch (status) {
        case 'attended':
          return 4;
        case 'booked':
          return 3;
        case 'waitlist':
          return 2;
        case 'cancelled':
          return 1;
        default:
          return 0;
      }
    }

    matches.sort((a, b) {
      final aStatus = (a['status'] ?? '').toString();
      final bStatus = (b['status'] ?? '').toString();

      final byRank = rank(bStatus).compareTo(rank(aStatus));
      if (byRank != 0) return byRank;

      final aUpdated = (a['updated_at'] ?? a['created_at'] ?? '').toString();
      final bUpdated = (b['updated_at'] ?? b['created_at'] ?? '').toString();
      return bUpdated.compareTo(aUpdated);
    });

    return matches.first;
  }

  bool _isBooked(Map<String, dynamic> classItem) {
    final booking = _bookingForClass(classItem['id'].toString());
    if (booking == null) return false;
    return (booking['status'] ?? '').toString() == 'booked';
  }

  bool _canCancelBooking(Map<String, dynamic> item) {
    try {
      final startsAt = DateTime.parse(item['starts_at'].toString()).toLocal();

      return DateTime.now().isBefore(startsAt);
    } catch (_) {
      return false;
    }
  }

  bool _isCheckedIn(Map<String, dynamic> classItem) {
    final booking = _bookingForClass(classItem['id'].toString());
    if (booking == null) return false;
    return (booking['status'] ?? '').toString() == 'attended';
  }

  bool _canCheckIn(Map<String, dynamic> classItem) {
    if (!_isBooked(classItem)) return false;

    try {
      final startsAt = DateTime.parse(
        classItem['starts_at'].toString(),
      ).toLocal();
      final durationMinutes = _asInt(classItem['duration_minutes'], 60);
      final checkInOpensAt = startsAt.subtract(const Duration(minutes: 10));
      final checkInClosesAt = startsAt.add(Duration(minutes: durationMinutes));
      final now = DateTime.now();

      return !now.isBefore(checkInOpensAt) && !now.isAfter(checkInClosesAt);
    } catch (_) {
      return false;
    }
  }

  bool _isClassFinished(Map<String, dynamic> item) {
    try {
      final startsAt = DateTime.parse(item['starts_at'].toString()).toLocal();
      final duration = _asInt(item['duration_minutes'], 60);
      final endsAt = startsAt.add(Duration(minutes: duration));

      return DateTime.now().isAfter(endsAt);
    } catch (_) {
      return false;
    }
  }

  bool _isBookingClosed(Map<String, dynamic> classItem) {
    if (_isBooked(classItem) || _isCheckedIn(classItem)) return false;

    try {
      final startsAt = DateTime.parse(
        classItem['starts_at'].toString(),
      ).toLocal();
      return !startsAt.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  void _applyLocalBookedState(String classId) {
    final bookingIndex = _myBookings.indexWhere(
      (b) => (b['class_id'] ?? '').toString() == classId,
    );

    if (bookingIndex >= 0) {
      final updated = Map<String, dynamic>.from(_myBookings[bookingIndex]);
      updated['status'] = 'booked';
      _myBookings[bookingIndex] = updated;
    } else {
      _myBookings.insert(0, {'class_id': classId, 'status': 'booked'});
    }

    final classIndex = _classes.indexWhere(
      (c) => (c['id'] ?? '').toString() == classId,
    );
    if (classIndex >= 0) {
      final updatedClass = Map<String, dynamic>.from(_classes[classIndex]);
      final currentRemaining = _asInt(updatedClass['remaining_spots'], 0);
      if (currentRemaining > 0) {
        updatedClass['remaining_spots'] = currentRemaining - 1;
      }
      _classes[classIndex] = updatedClass;
    }
  }

  void _applyLocalCancelledState(String classId) {
    final bookingIndex = _myBookings.indexWhere(
      (b) => (b['class_id'] ?? '').toString() == classId,
    );

    if (bookingIndex >= 0) {
      final updated = Map<String, dynamic>.from(_myBookings[bookingIndex]);
      updated['status'] = 'cancelled';
      _myBookings[bookingIndex] = updated;
    }

    final classIndex = _classes.indexWhere(
      (c) => (c['id'] ?? '').toString() == classId,
    );
    if (classIndex >= 0) {
      final updatedClass = Map<String, dynamic>.from(_classes[classIndex]);
      final currentRemaining = _asInt(updatedClass['remaining_spots'], 0);
      final total = _asInt(updatedClass['max_spots'], currentRemaining);
      if (currentRemaining < total) {
        updatedClass['remaining_spots'] = currentRemaining + 1;
      }
      _classes[classIndex] = updatedClass;
    }
  }

  Future<void> _bookClass(Map<String, dynamic> classItem) async {
    final classId = classItem['id'].toString();
    if (_busyClassId == classId) return;

    setState(() {
      _busyClassId = classId;
    });

    try {
      await _classRepo.bookClass(classId);

      if (!mounted) return;
      setState(() {
        _applyLocalBookedState(classId);
      });

      _showToast(context.appText.classBooked);
    } catch (e) {
      if (!mounted) return;
      _showToast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _busyClassId = null;
        });
      }
    }
  }

  Future<void> _cancelBooking(Map<String, dynamic> classItem) async {
    final t = context.appText;
    final classId = classItem['id'].toString();
    if (_busyClassId == classId) return;

    setState(() {
      _busyClassId = classId;
    });

    try {
      var booking = _bookingForClass(classId);
      if (booking == null || (booking['id'] ?? '').toString().isEmpty) {
        await _load();
        booking = _bookingForClass(classId);
      }

      if (booking == null) throw Exception(t.bookingNotFound);
      if ((booking['id'] ?? '').toString().isEmpty) {
        throw Exception(t.bookingIdNotFound);
      }

      await _bookingRepo.cancelBooking(booking['id'].toString());

      if (!mounted) return;
      setState(() {
        _applyLocalCancelledState(classId);
      });

      _showToast(context.appText.bookingCancelled);
    } catch (e) {
      if (!mounted) return;
      _showToast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _busyClassId = null;
        });
      }
    }
  }

  Future<void> _checkIn(Map<String, dynamic> classItem) async {
    try {
      await _attendanceRepo.checkInToClass(classItem['id'].toString());

      if (!mounted) return;
      _showToast(context.appText.checkedInSuccess);
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showToast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  List<DateTime> _days() {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    final startOffset = _isAdmin ? -_adminPastDays : 0;
    final totalDays = _isAdmin
        ? (_adminPastDays + _adminFutureDays + 1)
        : _athleteVisibleDays;

    return List.generate(
      totalDays,
      (i) => DateTime(base.year, base.month, base.day + startOffset + i),
    );
  }

  void _scrollToSelectedDay({bool animated = false}) {
    if (!_daysScrollController.hasClients) return;

    final days = _days();
    final selectedIso = _dateIso(_selectedDay);
    final selectedIndex = days.indexWhere((d) => _dateIso(d) == selectedIso);
    if (selectedIndex < 0) return;

    final target = (selectedIndex * 54.0) - 108.0;

    if (animated) {
      _daysScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return;
    }

    _daysScrollController.jumpTo(target);
  }

  String _dayName(DateTime d) {
    return DateFormat('E').format(d).substring(0, 1).toUpperCase();
  }

  String _dayNumber(DateTime d) {
    return DateFormat('d').format(d);
  }

  Widget _dayChip(DateTime d) {
    final selected = _dateIso(d) == _dateIso(_selectedDay);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedDay = d;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scrollToSelectedDay(animated: true);
        });
        _load();
      },
      child: Container(
        width: 54,
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(
              _dayName(d),
              style: _font(
                13,
                weight: FontWeight.w700,
                color: selected
                    ? const Color(0xFFB59B6A)
                    : const Color(0xFF8F909A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFB59B6A) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _dayNumber(d),
                style: _font(
                  15,
                  weight: FontWeight.w800,
                  color: selected ? Colors.white : const Color(0xFF111318),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaItem({
    required String label,
    required String value,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: _font(
            11,
            weight: FontWeight.w700,
            color: const Color(0xFF9AA0AC),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: _font(
            13,
            weight: FontWeight.w700,
            color: const Color(0xFF111318),
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String text,
    required VoidCallback? onPressed,
    bool filled = false,
    Color? fillColor,
    Color? textColor,
  }) {
    final bg =
        fillColor ??
        (filled ? const Color(0xFFB59B6A) : const Color(0xFFF2F3F6));
    final fg = textColor ?? (filled ? Colors.white : const Color(0xFF344054));

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Center(
            child: Text(
              text.toUpperCase(),
              style: _font(
                16,
                weight: FontWeight.w800,
                color: onPressed == null ? const Color(0xFF98A2B3) : fg,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String text, {required bool success}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: success ? const Color(0xFFE7F6EC) : const Color(0xFFF5EFE3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: _font(
          9.5,
          weight: FontWeight.w800,
          color: success ? const Color(0xFF1F8A4C) : const Color(0xFF9C865A),
          letterSpacing: 0.9,
        ),
      ),
    );
  }

  Widget _brandLogo() {
    return SizedBox(
      width: 132,
      child: Text(
        'ATHLETE LAB',
        style: _font(
          18,
          weight: FontWeight.w800,
          color: const Color(0xFF0E0E11),
          letterSpacing: -0.3,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _topHeader() {
    final monthText = DateFormat(
      'MMMM yyyy',
    ).format(_selectedDay).toUpperCase();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          monthText,
                          style: _font(
                            18,
                            weight: FontWeight.w800,
                            color: const Color(0xFF0E0E11),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, MMM d').format(_selectedDay),
                          style: _font(
                            12,
                            weight: FontWeight.w500,
                            color: const Color(0xFF8F96A3),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _brandLogo(),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: 132,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F3EA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            size: 20,
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
          const SizedBox(height: 14),
          SizedBox(
            height: 64,
            child: ListView.separated(
              controller: _daysScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: _days().length,
              separatorBuilder: (context, index) => const SizedBox(width: 2),
              itemBuilder: (context, i) => _dayChip(_days()[i]),
            ),
          ),
        ],
      ),
    );
  }

  String _classTimeStatus(Map<String, dynamic> item) {
    final t = context.appText;
    try {
      final startsAt = DateTime.parse(item['starts_at'].toString()).toLocal();
      final duration = _asInt(item['duration_minutes'], 60);
      final endsAt = startsAt.add(Duration(minutes: duration));

      final now = DateTime.now();

      if (now.isAfter(endsAt)) {
        return t.finished;
      }

      if (now.isAfter(startsAt) && now.isBefore(endsAt)) {
        return t.inProgress;
      }

      final diff = startsAt.difference(now);

      final today = DateTime(now.year, now.month, now.day);
      final classDay = DateTime(startsAt.year, startsAt.month, startsAt.day);

      if (classDay.isAfter(today)) {
        final daysDiff = classDay.difference(today).inDays;

        if (daysDiff == 1) {
          return t.tomorrow;
        }

        return t.inDays(daysDiff);
      }

      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;

      if (hours <= 0) {
        return t.startsInMinutes(minutes);
      }

      return t.startsInHoursMinutes(hours, minutes);
    } catch (_) {
      return '';
    }
  }

  Widget _classCard(Map<String, dynamic> item) {
    final t = context.appText;
    final titleRaw = (item['title'] ?? 'Class').toString().trim();
    final programRaw = (item['program_name'] ?? 'Class').toString().trim();
    final coach = (item['coach_name'] ?? 'TBD').toString().trim();
    final remaining = _asInt(item['remaining_spots'], 0);
    final total = _asInt(item['max_spots'], 0);
    final booking = _bookingForClass(item['id'].toString());

    final sameTitleAndProgram =
        titleRaw.toLowerCase() == programRaw.toLowerCase();

    final overline = sameTitleAndProgram ? null : programRaw.toUpperCase();

    String timeLabel = '-';
    try {
      final dt = DateTime.parse(item['starts_at'].toString()).toLocal();
      timeLabel = DateFormat('HH:mm').format(dt);
    } catch (_) {}

    String topStatus = '';
    if (_isCheckedIn(item)) {
      topStatus = 'checked_in';
    } else if (_isBooked(item)) {
      topStatus = 'booked';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeLabel,
                        style: _font(
                          31,
                          weight: FontWeight.w900,
                          color: const Color(0xFF111318),
                          letterSpacing: -1.0,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _classTimeStatus(item),
                        style: _font(
                          12,
                          weight: FontWeight.w600,
                          color: const Color(0xFF8F96A3),
                        ),
                      ),
                    ],
                  ),
                ),
                if (topStatus == 'checked_in')
                  _statusPill(t.checkedInUpper, success: true)
                else if (topStatus == 'booked')
                  _statusPill(t.bookedUpper, success: false),
              ],
            ),
            const SizedBox(height: 14),
            if (overline != null) ...[
              Text(
                overline,
                style: _font(
                  18,
                  weight: FontWeight.w700,
                  color: _programColor(programRaw),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
            ],
            const SizedBox(height: 12),
            Container(height: 0.8, color: const Color(0xFFEFF1F4)),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _metaItem(label: t.coach.toUpperCase(), value: coach),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metaItem(
                    label: t.spots.toUpperCase(),
                    value: '$remaining / $total',
                    crossAxisAlignment: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_isAdmin) ...[
              _actionButton(
                text: t.roster,
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ClassAttendanceScreen(classItem: item),
                    ),
                  );
                  await _load();
                },
              ),
              const SizedBox(height: 6),
            ],
            if (_isCheckedIn(item))
              _actionButton(text: t.checkedIn, onPressed: null)
            else if (_canCheckIn(item))
              _actionButton(
                text: t.imHere,
                filled: true,
                onPressed: _busyClassId == item['id'].toString()
                    ? null
                    : () => _checkIn(item),
              )
            else if (_isBooked(item) && _canCancelBooking(item))
              _actionButton(
                text: t.cancelBooking,
                onPressed: _busyClassId == item['id'].toString()
                    ? null
                    : () => _cancelBooking(item),
              )
            else if (_isClassFinished(item))
              _actionButton(text: t.classFinished, onPressed: null)
            else if (_isBookingClosed(item))
              _actionButton(text: t.bookingClosed, onPressed: null)
            else if (_activeMembership == null)
              _actionButton(text: t.membershipRequired, onPressed: null)
            else if (_asInt(item['remaining_spots'], 0) <= 0)
              _actionButton(text: t.classFull, onPressed: null)
            else
              _actionButton(
                text: t.bookClass,
                filled: true,
                onPressed: _busyClassId == item['id'].toString()
                    ? null
                    : () => _bookClass(item),
              ),
            if (booking != null &&
                (booking['status'] ?? '').toString() == 'cancelled') ...[
              const SizedBox(height: 6),
              Text(
                t.bookingWasCancelled,
                style: _font(
                  12,
                  weight: FontWeight.w500,
                  color: const Color(0xFF9AA3AF),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _skeletonLine({
    double? width,
    double height = 12,
    double radius = 999,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEAECEF),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _skeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skeletonLine(width: 110, height: 12),
          const SizedBox(height: 12),
          _skeletonLine(width: double.infinity, height: 22, radius: 8),
          const SizedBox(height: 10),
          _skeletonLine(width: 180, height: 14, radius: 8),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: 16),
          _skeletonLine(width: double.infinity, height: 12, radius: 8),
          const SizedBox(height: 8),
          _skeletonLine(width: 220, height: 12, radius: 8),
        ],
      ),
    );
  }

  List<Widget> _skeletonList({int count = 3}) {
    return List.generate(count, (_) => _skeletonCard());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appText;
    final membershipName =
        ((_activeMembership?['membership_plans'] ?? const {})['name'] ??
                _activeMembership?['plan_name'] ??
                'No active plan')
            .toString();
    final hasActiveMembership = _activeMembership != null;
    final membershipText = hasActiveMembership
        ? '${t.membershipActive} · $membershipName'
        : t.noActiveMembership;

    return Scaffold(
      body: Column(
        children: [
          _topHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFFB59B6A),
              backgroundColor: Colors.white,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F3EA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.card_membership_outlined,
                            color: Color(0xFFB59B6A),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            membershipText,
                            style: _font(
                              16,
                              weight: FontWeight.w600,
                              color: const Color(0xFF1F8A4C),
                              height: 1.2,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_loading) ...[
                    const SizedBox(height: 4),
                    ..._skeletonList(),
                  ] else if (_error != null)
                    Center(
                      child: Text(
                        _error!,
                        style: _font(
                          14,
                          weight: FontWeight.w500,
                          color: const Color(0xFFB42318),
                        ),
                      ),
                    )
                  else if (_classes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(
                          'No classes for this day',
                          style: _font(
                            16,
                            weight: FontWeight.w500,
                            color: const Color(0xFF667085),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._classes.map(_classCard),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
