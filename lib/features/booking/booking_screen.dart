import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_text.dart';

import '../../core/supabase/booking_repository.dart';
import '../../core/supabase/class_attendance_repository.dart';
import '../../core/supabase/class_repository.dart';
import '../../core/supabase/gym_repository.dart';
import '../../core/supabase/membership_repository.dart';
import '../../core/supabase/program_repository.dart';
import '../../core/supabase/profile_repository.dart';
import '../../core/supabase/supabase_bootstrap.dart';
import '../admin/class_attendance_screen.dart';
import 'widgets/create_class_sheet.dart';
import '../../shared/widgets/app_card.dart';
import 'widgets/create_recurring_classes_sheet.dart';

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
  final _gymRepo = GymRepository();
  final _bookingRepo = BookingRepository();
  final _attendanceRepo = ClassAttendanceRepository();
  final _membershipRepo = MembershipRepository();
  final _programRepo = ProgramRepository();
  final _profileRepo = ProfileRepository();

  bool _loading = true;
  String? _error;

  DateTime _selectedDay = DateTime.now();
  final ScrollController _daysScrollController = ScrollController();
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _myBookings = [];
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _coaches = [];
  Map<String, dynamic>? _activeMembership;
  String? _busyClassId;
  bool _canManageAttendance = false;
  String _gymName = '';
  String? _gymId;

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

  String _buildUtcIsoFromDateAndTime(String date, String time) {
    final dateParts = date.trim().split('-');
    final timeParts = time.trim().split(':');

    final local = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    return local.toUtc().toIso8601String();
  }

  Future<void> _updateClass(String id, Map<String, dynamic> data) async {
    await _classRepo.updateClass(
      gymId: _gymId!,
      id: id,
      programId: (data['programId'] ?? '').toString(),
      coachId: (data['coachId'] ?? '').toString().trim().isEmpty
          ? null
          : (data['coachId'] ?? '').toString(),
      startsAtIso: _buildUtcIsoFromDateAndTime(
        (data['date'] ?? '').toString(),
        (data['time'] ?? '').toString(),
      ),
      durationMinutes: int.parse((data['duration'] ?? '0').toString()),
      maxSpots: int.parse((data['maxSpots'] ?? '0').toString()),
      status: 'scheduled',
    );
  }

  Future<void> _deleteClass(Map<String, dynamic> item) async {
    final classId = (item['id'] ?? '').toString().trim();
    final gymId = (_gymId ?? '').trim();

    if (classId.isEmpty || gymId.isEmpty) {
      _showToast('Error', isError: true);
      return;
    }

    try {
      await _classRepo.deleteClass(gymId: gymId, id: classId);
      if (!mounted) return;
      final isSpanish = Localizations.localeOf(
        context,
      ).languageCode.toLowerCase().startsWith('es');
      _showToast(isSpanish ? 'Clase eliminada' : 'Class deleted');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showToast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _deleteThisAndFutureClasses(Map<String, dynamic> item) async {
    final classId = (item['id'] ?? '').toString().trim();
    if (classId.isEmpty) {
      _showToast('Error', isError: true);
      return;
    }

    try {
      final deleted = await _classRepo.deleteFutureClassesForProgramSlot(
        classId,
      );
      if (!mounted) return;
      final isSpanish = Localizations.localeOf(
        context,
      ).languageCode.toLowerCase().startsWith('es');
      _showToast(
        isSpanish
            ? 'Se eliminaron $deleted clases'
            : '$deleted classes deleted',
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showToast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _confirmDeleteThisAndFuture(Map<String, dynamic> item) async {
    final isSpanish = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('es');

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF6F7F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7DBE1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isSpanish
                      ? 'Eliminar esta y futuras'
                      : 'Delete this and future',
                  style: _font(
                    22,
                    weight: FontWeight.w800,
                    color: const Color(0xFF111318),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isSpanish
                      ? 'Esto eliminará esta clase y las próximas del mismo slot.'
                      : 'This will delete this class and the upcoming classes in the same slot.',
                  style: _font(
                    13,
                    weight: FontWeight.w500,
                    color: const Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        text: isSpanish ? 'Cancelar' : 'Cancel',
                        onPressed: () => Navigator.pop(sheetContext, false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionButton(
                        text: isSpanish ? 'Eliminar' : 'Delete',
                        filled: true,
                        fillColor: const Color(0xFFB42318),
                        onPressed: () => Navigator.pop(sheetContext, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      await _deleteThisAndFutureClasses(item);
    }
  }

  Future<void> _confirmDeleteClass(Map<String, dynamic> item) async {
    final isSpanish = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('es');

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF6F7F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7DBE1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isSpanish ? 'Eliminar clase' : 'Delete class',
                  style: _font(
                    22,
                    weight: FontWeight.w800,
                    color: const Color(0xFF111318),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isSpanish
                      ? '¿Seguro que quieres eliminar esta clase?'
                      : 'Are you sure you want to delete this class?',
                  style: _font(
                    13,
                    weight: FontWeight.w500,
                    color: const Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        text: isSpanish ? 'Cancelar' : 'Cancel',
                        onPressed: () => Navigator.pop(sheetContext, false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionButton(
                        text: isSpanish ? 'Eliminar' : 'Delete',
                        filled: true,
                        fillColor: const Color(0xFFB42318),
                        onPressed: () => Navigator.pop(sheetContext, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      await _deleteClass(item);
    }
  }

  Future<void> _openClassActions(Map<String, dynamic> item) async {
    final isSpanish = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('es');

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        Widget actionTile({
          required IconData icon,
          required String title,
          required VoidCallback onTap,
          Color iconBg = const Color(0xFFF3F4F6),
          Color iconColor = const Color(0xFF111318),
          Color titleColor = const Color(0xFF111318),
        }) {
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEAECEF)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: _font(
                        15,
                        weight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF6F7F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7DBE1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                actionTile(
                  icon: Icons.edit_rounded,
                  title: isSpanish ? 'Editar clase' : 'Edit class',
                  iconBg: const Color(0xFFF7F3EA),
                  iconColor: const Color(0xFFB59B6A),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final result = await showCreateClassSheet(
                      context: context,
                      programs: _programs,
                      coaches: _coaches,
                      initialData: item,
                    );
                    if (result != null) {
                      await _updateClass(item['id'].toString(), result);
                      if (!mounted) return;
                      _showToast(
                        isSpanish ? 'Clase actualizada' : 'Class updated',
                      );
                      await _load();
                    }
                  },
                ),
                const SizedBox(height: 10),
                actionTile(
                  icon: Icons.delete_outline_rounded,
                  title: isSpanish ? 'Eliminar clase' : 'Delete class',
                  iconBg: const Color(0xFFFEE4E2),
                  iconColor: const Color(0xFFB42318),
                  titleColor: const Color(0xFFB42318),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _confirmDeleteClass(item);
                  },
                ),
                const SizedBox(height: 10),
                actionTile(
                  icon: Icons.delete_sweep_rounded,
                  title: isSpanish
                      ? 'Eliminar esta y futuras'
                      : 'Delete this and future',
                  iconBg: const Color(0xFFFEE4E2),
                  iconColor: const Color(0xFFB42318),
                  titleColor: const Color(0xFFB42318),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _confirmDeleteThisAndFuture(item);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreateRecurringClassesSheet() async {
    final gymId = (_gymId ?? '').trim();
    if (gymId.isEmpty) {
      _showToast('Error', isError: true);
      return;
    }

    final result = await showCreateRecurringClassesSheet(
      context: context,
      programs: _programs,
      coaches: _coaches,
    );

    if (result == null) return;

    try {
      await _classRepo.createRecurringClasses(
        gymId: gymId,
        programId: (result['programId'] ?? '').toString(),
        coachId: (result['coachId'] ?? '').toString().trim().isEmpty
            ? null
            : (result['coachId'] ?? '').toString(),
        weekdays: List<int>.from(result['weekdays'] ?? const []),
        times: List<String>.from(result['times'] ?? const []),
        startDate: (result['startDate'] ?? '').toString(),
        endDate: (result['endDate'] ?? '').toString(),
        durationMinutes: int.parse((result['duration'] ?? '0').toString()),
        maxSpots: int.parse((result['maxSpots'] ?? '0').toString()),
      );
      if (!mounted) return;
      final isSpanish = Localizations.localeOf(
        context,
      ).languageCode.toLowerCase().startsWith('es');
      _showToast(isSpanish ? 'Agenda creada' : 'Schedule created');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showToast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _openCreateClassFlow() async {
    final isSpanish = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('es');

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        Widget actionTile({
          required IconData icon,
          required String title,
          required VoidCallback onTap,
          Color iconBg = const Color(0xFFF3F4F6),
          Color iconColor = const Color(0xFF111318),
        }) {
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEAECEF)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: _font(
                        15,
                        weight: FontWeight.w700,
                        color: const Color(0xFF111318),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF6F7F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7DBE1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                actionTile(
                  icon: Icons.add_circle_outline_rounded,
                  title: isSpanish ? 'Clase individual' : 'Single class',
                  iconBg: const Color(0xFFF7F3EA),
                  iconColor: const Color(0xFFB59B6A),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _openCreateClassSheet();
                  },
                ),
                const SizedBox(height: 10),
                actionTile(
                  icon: Icons.event_repeat_rounded,
                  title: isSpanish
                      ? 'Clases recurrentes'
                      : 'Recurring schedule',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _openCreateRecurringClassesSheet();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreateClassSheet() async {
    final gymId = (_gymId ?? '').trim();

    if (gymId.isEmpty) {
      _showToast(context.appText.gymIdRequiredError, isError: true);
      return;
    }

    if (_programs.isEmpty) {
      final isSpanish = Localizations.localeOf(
        context,
      ).languageCode.toLowerCase().startsWith('es');
      _showToast(
        isSpanish
            ? 'Primero crea al menos un programa.'
            : 'Create at least one program first.',
        isError: true,
      );
      return;
    }

    final result = await showCreateClassSheet(
      context: context,
      programs: _programs,
      coaches: _coaches,
    );

    if (result == null) return;

    try {
      await _classRepo.createClass(
        gymId: gymId,
        programId: (result['programId'] ?? '').toString(),
        coachId: (result['coachId'] ?? '').toString().trim().isEmpty
            ? null
            : (result['coachId'] ?? '').toString(),
        startsAtIso: _buildUtcIsoFromDateAndTime(
          (result['date'] ?? '').toString(),
          (result['time'] ?? '').toString(),
        ),
        durationMinutes: int.parse((result['duration'] ?? '0').toString()),
        maxSpots: int.parse((result['maxSpots'] ?? '0').toString()),
      );

      if (!mounted) return;
      final isSpanish = Localizations.localeOf(
        context,
      ).languageCode.toLowerCase().startsWith('es');
      _showToast(isSpanish ? 'Clase creada' : 'Class created');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showToast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      var canManageAttendance = false;
      final user = sb.auth.currentUser;
      if (user != null) {
        final byId = await sb
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        final role = (byId?['role'] ?? '').toString().toLowerCase().trim();
        canManageAttendance = role == 'admin' || role == 'coach';
      }

      final resolvedGymId = canManageAttendance
          ? (await _gymRepo.resolveGymId() ?? '').trim()
          : '';
      final programs = canManageAttendance && resolvedGymId.isNotEmpty
          ? await _programRepo.listPrograms(resolvedGymId)
          : <Map<String, dynamic>>[];
      final coaches = canManageAttendance && resolvedGymId.isNotEmpty
          ? await _profileRepo.listCoaches(resolvedGymId)
          : <Map<String, dynamic>>[];

      final classes = await _classRepo.listClassesForDate(
        _dateIso(_selectedDay),
        includePast: canManageAttendance,
      );
      final bookings = await _bookingRepo.listMyBookings();
      final activeMembership = await _membershipRepo.myActiveMembership();
      final gymName = (await _gymRepo.myGymName() ?? '').trim();

      if (!mounted) return;
      setState(() {
        _classes = classes;
        _myBookings = bookings;
        _programs = programs;
        _coaches = coaches;
        _activeMembership = activeMembership;
        _canManageAttendance = canManageAttendance;
        _gymName = gymName;
        _gymId = resolvedGymId.isEmpty ? null : resolvedGymId;
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
    final startOffset = _canManageAttendance ? -_adminPastDays : 0;
    final totalDays = _canManageAttendance
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
    final isSpanish = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('es');

    if (isSpanish) {
      switch (d.weekday) {
        case DateTime.monday:
          return 'L';
        case DateTime.tuesday:
          return 'M';
        case DateTime.wednesday:
          return 'M';
        case DateTime.thursday:
          return 'J';
        case DateTime.friday:
          return 'V';
        case DateTime.saturday:
          return 'S';
        case DateTime.sunday:
          return 'D';
      }
    }

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
    bool loading = false,
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
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: onPressed == null && !loading ? 0.72 : 1,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: loading ? null : onPressed,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Center(
                key: ValueKey('${text}_$loading'),
                child: loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            filled ? Colors.white : const Color(0xFF344054),
                          ),
                        ),
                      )
                    : Text(
                        text.toUpperCase(),
                        style: _font(
                          16,
                          weight: FontWeight.w800,
                          color: onPressed == null
                              ? const Color(0xFF98A2B3)
                              : fg,
                          letterSpacing: 0.8,
                        ),
                      ),
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

  String _capitalizeDateLabel(String raw) {
    final parts = raw.split(' ');
    final normalized = parts
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1);
        })
        .join(' ');
    return normalized.replaceAllMapped(RegExp(r'(^|\s)([a-záéíóúñ])'), (m) {
      return '${m.group(1)}${m.group(2)!.toUpperCase()}';
    });
  }

  Widget _brandLogo() {
    final trimmedGymName = _gymName.trim();

    if (trimmedGymName.isEmpty && _loading) {
      return const SizedBox(width: 132, height: 28);
    }

    final gymName = trimmedGymName.isEmpty ? 'ATHLETE LAB' : trimmedGymName;

    return SizedBox(
      width: 132,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gymName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _font(
              16,
              weight: FontWeight.w800,
              color: const Color(0xFF0E0E11),
              letterSpacing: -0.2,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'ATHLETE LAB',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _font(
              10,
              weight: FontWeight.w700,
              color: const Color(0xFF8F96A3),
              letterSpacing: 0.7,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topHeader() {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final monthText = _capitalizeDateLabel(
      DateFormat('MMMM yyyy', localeTag).format(_selectedDay),
    ).toUpperCase();

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
                          _capitalizeDateLabel(
                            DateFormat(
                              'EEEE, MMMM d',
                              localeTag,
                            ).format(_selectedDay),
                          ),
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

  Widget _restDayState() {
    final t = context.appText;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
        child: Column(
          children: [
            Text(
              t.restDayUpper,
              textAlign: TextAlign.center,
              style: _font(
                28,
                weight: FontWeight.w800,
                color: const Color(0xFF111318),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              t.restDayMessage,
              textAlign: TextAlign.center,
              style: _font(
                13,
                weight: FontWeight.w500,
                color: const Color(0xFF667085),
                height: 1.45,
              ),
            ),
          ],
        ),
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
    final programRaw = (item['program_name'] ?? t.classLabel).toString().trim();
    final remaining = _asInt(item['remaining_spots'], 0);
    final total = _asInt(item['max_spots'], 0);
    final booking = _bookingForClass(item['id'].toString());

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
                  child: Text(
                    timeLabel,
                    style: _font(
                      31,
                      weight: FontWeight.w900,
                      color: const Color(0xFF111318),
                      letterSpacing: -1.0,
                      height: 1.0,
                    ),
                  ),
                ),
                if (_canManageAttendance) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openClassActions(item),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.more_horiz_rounded,
                        size: 20,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (topStatus == 'checked_in')
                  _statusPill(t.checkedInUpper, success: true)
                else if (topStatus == 'booked')
                  _statusPill(t.bookedUpper, success: true),
              ],
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
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        programRaw,
                        style: _font(
                          24,
                          weight: FontWeight.w800,
                          color: const Color(0xFF111318),
                          letterSpacing: -0.3,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 92,
                  child: _metaItem(
                    label: t.spots.toUpperCase(),
                    value: '$remaining / $total',
                    crossAxisAlignment: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 0.8, color: const Color(0xFFEFF1F4)),
            const SizedBox(height: 16),
            if (_canManageAttendance) ...[
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
                loading: _busyClassId == item['id'].toString(),
                onPressed: _busyClassId == item['id'].toString()
                    ? null
                    : () => _checkIn(item),
              )
            else if (_isBooked(item) && _canCancelBooking(item))
              _actionButton(
                text: t.cancelBooking,
                loading: _busyClassId == item['id'].toString(),
                onPressed: _busyClassId == item['id'].toString()
                    ? null
                    : () => _cancelBooking(item),
              )
            else if (_isClassFinished(item))
              _actionButton(text: t.classFinished, onPressed: null)
            else if (_isBookingClosed(item))
              _actionButton(text: t.bookingClosed, onPressed: null)
            else if (_loading)
              _actionButton(text: '...', onPressed: null)
            else if (_activeMembership == null)
              _actionButton(text: t.membershipRequired, onPressed: null)
            else if (_asInt(item['remaining_spots'], 0) <= 0)
              _actionButton(text: t.classFull, onPressed: null)
            else
              _actionButton(
                text: t.bookClass,
                filled: true,
                loading: _busyClassId == item['id'].toString(),
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
                t.noActivePlan)
            .toString();
    final hasActiveMembership = _activeMembership != null;
    final membershipText = hasActiveMembership
        ? '${t.membershipActive} · $membershipName'
        : t.noActiveMembership;

    return Scaffold(
      floatingActionButton: _canManageAttendance && !_loading && _error == null
          ? FloatingActionButton(
              onPressed: _openCreateClassFlow,
              backgroundColor: const Color(0xFFB59B6A),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded),
            )
          : null,
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
                    child: _loading
                        ? Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F5F7),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _skeletonLine(
                                      width: 170,
                                      height: 16,
                                      radius: 8,
                                    ),
                                    const SizedBox(height: 8),
                                    _skeletonLine(
                                      width: 110,
                                      height: 12,
                                      radius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Row(
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
                                    color: hasActiveMembership
                                        ? const Color(0xFF1F8A4C)
                                        : const Color(0xFF667085),
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
                    _restDayState()
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
