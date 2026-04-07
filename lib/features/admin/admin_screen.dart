import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_text.dart';
import '../../l10n/app_strings.dart';

import '../../core/supabase/class_repository.dart';
import '../../core/supabase/admin_member_repository.dart';
import '../../core/supabase/notification_repository.dart';
import '../../core/supabase/auth_repository.dart';
import '../../core/supabase/gym_repository.dart';
import '../../core/supabase/membership_repository.dart';
import '../../core/supabase/profile_repository.dart';
import '../../core/supabase/program_repository.dart';
import '../../core/supabase/storage_repository.dart';
import '../../core/supabase/workout_repository.dart';
import '../../features/notifications/admin_notifications_tab.dart';
import 'member_detail/admin_member_detail_screen.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/input_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/search_field.dart';
import '../../shared/widgets/secondary_button.dart';
import 'class_attendance_screen.dart';
part 'admin_program_modal.dart';
part 'admin_class_modal.dart';
part 'admin_workout_modal.dart';
part 'admin_assign_workout_modal.dart';
part 'admin_plan_actions.dart';
part 'admin_plan_modal.dart';

class AdminScreen extends StatefulWidget {
  final int initialTabIndex;
  final String? initialMemberId;
  final String? initialClassId;
  final bool initialOpenAssignWorkout;

  const AdminScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialMemberId,
    this.initialClassId,
    this.initialOpenAssignWorkout = false,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _membershipRepo = MembershipRepository();
  final _authRepo = AuthRepository();
  final _adminMemberRepo = AdminMemberRepository();
  final _notificationRepo = NotificationRepository();
  final _profileRepo = ProfileRepository();
  final _classRepo = ClassRepository();
  final _programRepo = ProgramRepository();
  final _gymRepo = GymRepository();
  final _workoutRepo = WorkoutRepository();
  final _storageRepo = StorageRepository();
  final _picker = ImagePicker();

  late int tabIndex;
  String? _pendingOpenMemberId;
  String? _pendingOpenClassId;
  bool _pendingOpenAssignWorkout = false;
  bool _loading = true;
  bool _adminActionBusy = false;
  String? _error;
  String? _adminGymId;
  String _classesFilter = 'today';

  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _coaches = [];
  List<Map<String, dynamic>> _workouts = [];
  final Map<String, Map<String, dynamic>?> _memberActiveMembership = {};

  String? _lastClassProgramId;
  String? _lastClassCoachId;
  String? _lastClassDuration;

  final tabs = const [
    'Programs',
    'Classes',
    'Workouts',
    'Members',
    'Plans',
    'Notifications',
  ];
  late final List<GlobalKey> _tabChipKeys;

  AppStrings get t => context.appText;

  bool get _isSpanish => Localizations.localeOf(
    context,
  ).languageCode.toLowerCase().startsWith('es');

  String _uiText(String es, String en) => _isSpanish ? es : en;

  String _adminTabLabel(String raw) {
    switch (raw) {
      case 'Programs':
        return _uiText('Programas', 'Programs');
      case 'Classes':
        return _uiText('Clases', 'Classes');
      case 'Workouts':
        return _uiText('Workouts', 'Workouts');
      case 'Members':
        return _uiText('Miembros', 'Members');
      case 'Plans':
        return _uiText('Planes', 'Plans');
      case 'Notifications':
        return _uiText('Notificaciones', 'Notifications');
      default:
        return raw;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabChipKeys = List.generate(tabs.length, (_) => GlobalKey());
    tabIndex = widget.initialTabIndex;
    _pendingOpenMemberId = widget.initialMemberId;
    _pendingOpenClassId = widget.initialClassId;
    _pendingOpenAssignWorkout = widget.initialOpenAssignWorkout;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveTab();
    });
    _loadAdminData();
  }

  @override
  void didUpdateWidget(covariant AdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialMemberId != widget.initialMemberId) {
      _pendingOpenMemberId = widget.initialMemberId;
    }
    if (oldWidget.initialClassId != widget.initialClassId) {
      _pendingOpenClassId = widget.initialClassId;
    }
    if (oldWidget.initialOpenAssignWorkout != widget.initialOpenAssignWorkout) {
      _pendingOpenAssignWorkout = widget.initialOpenAssignWorkout;
    }

    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      final nextIndex = widget.initialTabIndex.clamp(0, tabs.length - 1);
      if (tabIndex != nextIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => tabIndex = nextIndex);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _scrollToActiveTab();
            _openPendingMemberIfNeeded();
            _openPendingClassIfNeeded();
          });
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _openPendingMemberIfNeeded();
          _openPendingClassIfNeeded();
        });
      }
    } else if (oldWidget.initialMemberId != widget.initialMemberId ||
        oldWidget.initialClassId != widget.initialClassId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openPendingMemberIfNeeded();
        _openPendingClassIfNeeded();
      });
    }
  }

  void _openPendingMemberIfNeeded() {
    if (tabIndex != 3) return;

    final memberId = _pendingOpenMemberId?.trim() ?? '';
    if (memberId.isEmpty) return;

    Map<String, dynamic>? target;
    for (final member in _members) {
      if ((member['id'] ?? '').toString() == memberId) {
        target = member;
        break;
      }
    }

    _pendingOpenMemberId = null;

    if (target == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showMemberActions(target!);
    });
  }

  void _openPendingClassIfNeeded() {
    if (tabIndex != 1) return;

    final rawClassId = _pendingOpenClassId?.trim() ?? '';
    if (rawClassId.isEmpty) return;

    final classId = rawClassId.startsWith('tomorrow-risk-')
        ? rawClassId.substring('tomorrow-risk-'.length)
        : rawClassId;

    Map<String, dynamic>? target;
    for (final item in _classes) {
      if ((item['id'] ?? '').toString() == classId) {
        target = item;
        break;
      }
    }

    final openAssignWorkout = _pendingOpenAssignWorkout;
    _pendingOpenClassId = null;
    _pendingOpenAssignWorkout = false;

    if (target == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        if (openAssignWorkout) {
          _showAssignWorkoutModal(target!);
        } else {
          _showClassActions(target!);
        }
      });
    });
  }

  void _scrollToActiveTab() {
    if (tabIndex < 0 || tabIndex >= _tabChipKeys.length) return;
    final context = _tabChipKeys[tabIndex].currentContext;
    if (context == null) return;

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      alignment: 0.5,
    );
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

  Widget _topHeader() {

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: 132,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ATHLETE LAB',
                      style: _font(
                        17,
                        weight: FontWeight.w800,
                        color: const Color(0xFF0E0E11),
                        letterSpacing: -0.2,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  'ADMIN',
                  style: _font(
                    17,
                    weight: FontWeight.w800,
                    color: const Color(0xFF0E0E11),
                    letterSpacing: -0.2,
                  ),
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
                        Icons.admin_panel_settings_outlined,
                        size: 19,
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
    );
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF111318),
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: _font(14, weight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  String _friendlyAdminError(Object e) {
    final raw = e.toString().replaceFirst('Exception: ', '').toLowerCase();

    if (raw.contains('foreign key') ||
        raw.contains('violates foreign key constraint') ||
        raw.contains('update or delete on table')) {
      return t.linkedDataDeleteError;
    }
    if (raw.contains('program') && raw.contains('delete')) {
      return t.deleteProgramLinkedError;
    }
    if (raw.contains('membership') ||
        (raw.contains('plan') && raw.contains('delete'))) {
      return t.deletePlanLinkedError;
    }
    if (raw.contains('class') && raw.contains('delete')) {
      return t.deleteClassLinkedError;
    }
    if (raw.contains('workout') && raw.contains('delete')) {
      return t.deleteWorkoutLinkedError;
    }

    return e.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _runAdminAction(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    if (_adminActionBusy) return;

    setState(() {
      _adminActionBusy = true;
    });

    try {
      await action();
      if (!mounted) return;
      if (successMessage != null && successMessage.isNotEmpty) {
        _toast(successMessage);
      }
      await _loadAdminData();
    } catch (e) {
      if (!mounted) return;
      _toast(_friendlyAdminError(e));
    } finally {
      if (mounted) {
        setState(() {
          _adminActionBusy = false;
        });
      }
    }
  }

  bool _isValidEmail(String value) {
    final email = value.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _createMemberByAdmin({
    required String fullName,
    required String email,
    required String role,
    String? phone,
    String? dateOfBirth,
    String? notes,
    bool isActive = true,
  }) async {
    await _adminMemberRepo.createMember(
      fullName: fullName,
      email: email,
      role: role,
      phone: phone,
      dateOfBirth: dateOfBirth,
      notes: notes,
      isActive: isActive,
    );
  }

  void _showMemberOnboardingModal() {
    final fullNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final dobCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    String selectedRole = 'athlete';
    bool isActive = true;
    String? localError;

    Future<void> pickDate(
      BuildContext context,
      TextEditingController controller, {
      String? title,
      String? subtitle,
    }) async {
      final resolvedTitle =
          title ?? _uiText('Fecha de nacimiento', 'Date of Birth');
      final resolvedSubtitle =
          subtitle ??
          _uiText(
            'Elige la fecha de nacimiento del atleta.',
            'Choose the athlete birth date.',
          );
      final now = DateTime.now();
      DateTime selectedDate =
          DateTime.tryParse(controller.text.trim()) ?? DateTime(1990, 1, 1);

      final picked = await showModalBottomSheet<DateTime>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF6F7F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return SingleChildScrollView(
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
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F3EA),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.event_rounded,
                                  color: Color(0xFFB59B6A),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resolvedTitle,
                                      style: _font(
                                        24,
                                        weight: FontWeight.w800,
                                        color: const Color(0xFF111318),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      resolvedSubtitle,
                                      style: _font(
                                        13,
                                        weight: FontWeight.w500,
                                        color: const Color(0xFF8F96A3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => Navigator.pop(sheetContext),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFE8EBF0),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 22,
                                    color: Color(0xFF111318),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t.selectDate,
                            style: _font(
                              15,
                              weight: FontWeight.w800,
                              color: const Color(0xFF111318),
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFEAECEF),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 220,
                                  child: CupertinoTheme(
                                    data: const CupertinoThemeData(
                                      primaryColor: Color(0xFFB59B6A),
                                      textTheme: CupertinoTextThemeData(
                                        dateTimePickerTextStyle: TextStyle(
                                          color: Color(0xFF111318),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                    child: CupertinoDatePicker(
                                      mode: CupertinoDatePickerMode.date,
                                      initialDateTime: selectedDate,
                                      minimumDate: DateTime(1900),
                                      maximumDate: DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                      ),
                                      onDateTimeChanged: (value) {
                                        setModalState(() {
                                          selectedDate = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat(
                                    'd MMMM yyyy',
                                  ).format(selectedDate),
                                  style: _font(
                                    13,
                                    weight: FontWeight.w600,
                                    color: const Color(0xFF667085),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(sheetContext, selectedDate),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: const Color(0xFFB59B6A),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                t.saveChanges,
                                style: _font(
                                  16,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );

      if (picked != null) {
        controller.text = picked.toIso8601String().split('T').first;
      }
    }

    InputDecoration inputDecoration(String label, {String? hint}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: _font(
          12,
          weight: FontWeight.w500,
          color: const Color(0xFF667085),
        ),
        hintStyle: _font(
          13,
          weight: FontWeight.w500,
          color: const Color(0xFF98A2B3),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFB59B6A), width: 1.2),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16 + MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.88,
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7F9),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD7DBE1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.appText.addMemberTitle,
                          style: _font(
                            22,
                            weight: FontWeight.w800,
                            color: const Color(0xFF111318),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _uiText(
                            'Crea una cuenta real de atleta y envía el email de invitación automáticamente.',
                            'Create a real athlete account and send the invitation email automatically.',
                          ),
                          style: _font(
                            13,
                            weight: FontWeight.w500,
                            color: const Color(0xFF667085),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: fullNameCtrl,
                          decoration: inputDecoration(
                            _uiText('Nombre completo', 'Full name'),
                            hint: _uiText('Nombre Apellido', 'John Doe'),
                          ),
                          style: _font(14, weight: FontWeight.w500),
                          textInputAction: TextInputAction.next,
                          onTapOutside: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: emailCtrl,
                          decoration: inputDecoration(
                            _uiText('Email', 'Email'),
                            hint: 'john@email.com',
                          ),
                          style: _font(14, weight: FontWeight.w500),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onTapOutside: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: phoneCtrl,
                          decoration: inputDecoration(
                            _uiText('Teléfono', 'Phone'),
                            hint: '+34 600 000 000',
                          ),
                          style: _font(14, weight: FontWeight.w500),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          onTapOutside: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: dobCtrl,
                          decoration:
                              inputDecoration(
                                _uiText('Fecha de nacimiento', 'Date of birth'),
                                hint: '1986-12-11',
                              ).copyWith(
                                suffixIcon: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: Color(0xFF98A2B3),
                                ),
                              ),
                          style: _font(14, weight: FontWeight.w500),
                          readOnly: true,
                          onTap: () async {
                            await pickDate(context, dobCtrl);
                            setLocalState(() {});
                          },
                          textInputAction: TextInputAction.next,
                          onTapOutside: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedRole,
                          decoration: inputDecoration(_uiText('Rol', 'Role')),
                          borderRadius: BorderRadius.circular(16),
                          dropdownColor: Colors.white,
                          iconEnabledColor: const Color(0xFF667085),
                          style: _font(
                            13,
                            weight: FontWeight.w500,
                            color: const Color(0xFF111318),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'athlete',
                              child: Text(_uiText('Atleta', 'Athlete')),
                            ),
                            DropdownMenuItem(
                              value: 'coach',
                              child: Text(_uiText('Coach', 'Coach')),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text(_uiText('Admin', 'Admin')),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setLocalState(() {
                                selectedRole = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: notesCtrl,
                          minLines: 3,
                          maxLines: 4,
                          decoration: inputDecoration(
                            _uiText('Notas', 'Notes'),
                            hint: _uiText('Notas opcionales', 'Optional notes'),
                          ),
                          style: _font(14, weight: FontWeight.w500),
                          textInputAction: TextInputAction.done,
                          onEditingComplete: () =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          onTapOutside: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _uiText(
                                        'Miembro activo',
                                        'Active member',
                                      ),
                                      style: _font(
                                        14,
                                        weight: FontWeight.w700,
                                        color: const Color(0xFF111318),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _uiText(
                                        'Permitir acceso a la app después de configurar la contraseña',
                                        'Allow access to the app after password setup',
                                      ),
                                      style: _font(
                                        12,
                                        weight: FontWeight.w500,
                                        color: const Color(0xFF8F96A3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isActive,
                                onChanged: (value) {
                                  setLocalState(() {
                                    isActive = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        if (localError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            localError!,
                            style: _font(
                              13,
                              weight: FontWeight.w600,
                              color: const Color(0xFFB42318),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                text: context.appText.cancel,
                                compact: true,
                                radius: 16,
                                textStyle: _font(
                                  16,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF344054),
                                  letterSpacing: -0.15,
                                ),
                                onPressed: () => Navigator.pop(sheetContext),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                text: context.appText.createMember,
                                compact: true,
                                radius: 16,
                                backgroundColor: const Color(0xFFB59B6A),
                                pressedColor: const Color(0xFFA88C59),
                                disabledColor: const Color(0xFFC9C9C9),
                                textColor: Colors.white,
                                textStyle: _font(
                                  16,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.15,
                                ),
                                boxShadow: const [],
                                onPressed: () async {
                                  final fullName = fullNameCtrl.text.trim();
                                  final email = emailCtrl.text
                                      .trim()
                                      .toLowerCase();
                                  final phone = phoneCtrl.text.trim();
                                  final dob = dobCtrl.text.trim();
                                  final notes = notesCtrl.text.trim();

                                  if (fullName.isEmpty) {
                                    setLocalState(() {
                                      localError =
                                          context.appText.fullNameRequiredError;
                                    });
                                    return;
                                  }

                                  if (!_isValidEmail(email)) {
                                    setLocalState(() {
                                      localError = context
                                          .appText
                                          .validEmailRequiredError;
                                    });
                                    return;
                                  }

                                  setLocalState(() {
                                    localError = null;
                                  });

                                  await _runAdminAction(
                                    () => _createMemberByAdmin(
                                      fullName: fullName,
                                      email: email,
                                      role: selectedRole,
                                      phone: phone.isEmpty ? null : phone,
                                      dateOfBirth: dob.isEmpty ? null : dob,
                                      notes: notes.isEmpty ? null : notes,
                                      isActive: isActive,
                                    ),
                                    successMessage: context
                                        .appText
                                        .memberCreatedInvitationSent,
                                  );

                                  if (!sheetContext.mounted) return;
                                  Navigator.pop(sheetContext);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _resolvedGymIdForAdmin() async {
    final current = _adminGymId?.trim();
    if (current != null && current.isNotEmpty) return current;

    final resolved = await _gymRepo.resolveGymId();
    if (resolved != null && resolved.isNotEmpty) return resolved;

    return null;
  }

  bool _isPastClassDateTime(String date, String time) {
    final cleanDate = date.trim();
    final cleanTime = time.trim();

    if (cleanDate.isEmpty || cleanTime.isEmpty) return false;

    final parts = cleanDate.split('-');
    final timeParts = cleanTime.split(':');

    if (parts.length != 3 || timeParts.length < 2) return false;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);

    if (year == null ||
        month == null ||
        day == null ||
        hour == null ||
        minute == null) {
      return false;
    }

    final localDateTime = DateTime(year, month, day, hour, minute);
    return localDateTime.isBefore(DateTime.now());
  }

  String _buildUtcIsoFromDateAndTime(String date, String time) {
    final cleanDate = date.trim();
    final cleanTime = time.trim();

    if (cleanDate.isEmpty) throw Exception(t.dateRequiredError);
    if (cleanTime.isEmpty) throw Exception(t.timeRequiredError);

    final parts = cleanDate.split('-');
    if (parts.length != 3) throw Exception(t.dateFormatYmdError);

    final timeParts = cleanTime.split(':');
    if (timeParts.length < 2) throw Exception(t.timeFormatHmError);

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);

    if (year == null || month == null || day == null) {
      throw Exception(t.invalidDateError);
    }
    if (hour == null || minute == null) {
      throw Exception(t.invalidTimeError);
    }

    final localDateTime = DateTime(year, month, day, hour, minute);
    return localDateTime.toUtc().toIso8601String();
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resolvedGymId = await _resolvedGymIdForAdmin();
      if (resolvedGymId == null || resolvedGymId.isEmpty) {
        throw Exception(t.adminGymNotFound);
      }
      _adminGymId = resolvedGymId;

      try {
        _plans = await _membershipRepo.listPlans(_adminGymId!);
      } catch (_) {
        _plans = [];
      }

      try {
        _members = await _profileRepo.listMembers(_adminGymId!);
      } catch (_) {
        _members = [];
      }

      try {
        _classes = await _classRepo.listClassesAdmin(_adminGymId!);
      } catch (_) {
        _classes = [];
      }

      try {
        _programs = await _programRepo.listPrograms(_adminGymId!);
      } catch (_) {
        _programs = [];
      }

      try {
        _coaches = await _profileRepo.listCoaches(_adminGymId!);
      } catch (_) {
        _coaches = [];
      }

      try {
        _workouts = await _workoutRepo.listWorkoutsAdmin(_adminGymId!);
      } catch (_) {
        _workouts = [];
      }

      _memberActiveMembership.clear();

      for (final member in _members) {
        final id = member['id']?.toString();
        if (id == null) continue;
        try {
          final list = await _membershipRepo.listMemberMemberships(id);
          Map<String, dynamic>? active;
          for (final item in list) {
            if ((item['status'] ?? '').toString() == 'active') {
              active = item;
              break;
            }
          }
          _memberActiveMembership[id] = active;
        } catch (_) {
          _memberActiveMembership[id] = null;
        }
      }
    } catch (_) {
      _error = t.adminDataLoadError;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _openPendingMemberIfNeeded();
          _openPendingClassIfNeeded();
        });
      }
    }
  }

  Future<void> _createProgram({
    required String name,
    required String description,
  }) async {
    final gymId = await _resolvedGymIdForAdmin();
    if (gymId == null || gymId.isEmpty) {
      throw Exception(t.gymIdRequiredError);
    }
    if (name.trim().isEmpty) {
      throw Exception(t.programNameRequiredError);
    }

    await _programRepo.createProgram(
      gymId: gymId,
      name: name.trim(),
      description: description.trim().isEmpty ? null : description.trim(),
      colorHex: null,
    );
  }

  Future<void> _updateProgram({
    required String id,
    required String name,
    required String description,
  }) async {
    if (name.trim().isEmpty) {
      throw Exception(t.programNameRequiredError);
    }

    await _programRepo.updateProgram(
      gymId: _adminGymId!,
      id: id,
      name: name.trim(),
      description: description.trim().isEmpty ? null : description.trim(),
      colorHex: null,
    );
  }

  Future<void> _deleteProgram(String id) async {
    await _programRepo.deleteProgram(gymId: _adminGymId!, id: id);
  }

  void _showWorkoutActions(Map<String, dynamic> item) {
    final title = (item['title'] ?? 'Workout').toString().trim();
    final program = (item['program_name'] ?? 'Workout').toString().trim();
    final date = (item['workout_date'] ?? '').toString().trim();

    Widget actionTile({
      required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback? onTap,
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
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECF1)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _font(
                        16,
                        weight: FontWeight.w800,
                        color: titleColor,
                        letterSpacing: -0.15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: _font(
                          12,
                          weight: FontWeight.w500,
                          color: const Color(0xFF8F96A3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF98A2B3),
                size: 22,
              ),
            ],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.78,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7F9),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7DBE1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFEAECEF)),
                        ),
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
                                Icons.fitness_center_rounded,
                                color: Color(0xFFB59B6A),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.isEmpty ? 'Workout' : title,
                                    style: _font(
                                      18,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFF111318),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (program.isNotEmpty ||
                                      date.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        program,
                                        date,
                                      ].where((e) => e.isNotEmpty).join(' · '),
                                      style: _font(
                                        13,
                                        weight: FontWeight.w500,
                                        color: const Color(0xFF8F96A3),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.appText.workoutActionsTitle,
                        style: _font(
                          14,
                          weight: FontWeight.w700,
                          color: const Color(0xFF8F96A3),
                        ),
                      ),
                      const SizedBox(height: 10),
                      actionTile(
                        icon: Icons.edit_rounded,
                        title: t.editWorkoutTitle,
                        subtitle: t.editWorkoutActionSubtitle,
                        iconBg: const Color(0xFFF7F3EA),
                        iconColor: const Color(0xFFB59B6A),
                        onTap: () {
                          Navigator.pop(context);
                          _showWorkoutModal(item: item);
                        },
                      ),
                      const SizedBox(height: 10),
                      actionTile(
                        icon: Icons.delete_outline_rounded,
                        title: t.deleteWorkoutTitle,
                        subtitle: t.deleteWorkoutActionSubtitle,
                        iconBg: const Color(0xFFFEE4E2),
                        iconColor: const Color(0xFFE11D48),
                        titleColor: const Color(0xFFE11D48),
                        onTap: _adminActionBusy
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await _runAdminAction(
                                  () => _deleteWorkout(item['id'].toString()),
                                  successMessage: t.workoutDeleted,
                                );
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showClassActions(Map<String, dynamic> item) {
    final title = (item['title'] ?? item['program_name'] ?? 'Class')
        .toString()
        .trim();
    final program = (item['program_name'] ?? '').toString().trim();
    final startsAt = DateTime.tryParse(
      (item['starts_at'] ?? '').toString(),
    )?.toLocal();
    final dateLabel = startsAt != null
        ? DateFormat('EEE, MMM d · HH:mm').format(startsAt)
        : '';

    Widget actionTile({
      required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback? onTap,
      Color iconBg = const Color(0xFFF3F4F6),
      Color iconColor = const Color(0xFF111318),
      Color titleColor = const Color(0xFF111318),
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECF1)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _font(
                        16,
                        weight: FontWeight.w800,
                        color: titleColor,
                        letterSpacing: -0.15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: _font(
                          12,
                          weight: FontWeight.w500,
                          color: const Color(0xFF8F96A3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF98A2B3),
                size: 22,
              ),
            ],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7F9),
                borderRadius: BorderRadius.circular(26),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD7DBE1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFEAECEF)),
                      ),
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
                              Icons.calendar_today_rounded,
                              color: Color(0xFFB59B6A),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title.isEmpty ? 'Class' : title,
                                  style: _font(
                                    18,
                                    weight: FontWeight.w800,
                                    color: const Color(0xFF111318),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                if (program.isNotEmpty ||
                                    dateLabel.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      program,
                                      dateLabel,
                                    ].where((e) => e.isNotEmpty).join(' · '),
                                    style: _font(
                                      13,
                                      weight: FontWeight.w500,
                                      color: const Color(0xFF8F96A3),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.appText.classActionsTitle,
                      style: _font(
                        14,
                        weight: FontWeight.w700,
                        color: const Color(0xFF8F96A3),
                      ),
                    ),
                    const SizedBox(height: 10),
                    actionTile(
                      icon: Icons.assignment_turned_in_rounded,
                      title: t.assignWorkoutModalTitle,
                      subtitle: t.assignWorkoutModalSubtitle,
                      iconBg: const Color(0xFFF7F3EA),
                      iconColor: const Color(0xFFB59B6A),
                      onTap: () {
                        Navigator.pop(context);
                        _showAssignWorkoutModal(item);
                      },
                    ),
                    const SizedBox(height: 10),
                    actionTile(
                      icon: Icons.groups_2_rounded,
                      title: t.attendanceTitle,
                      subtitle: t.attendanceActionSubtitle,
                      iconBg: const Color(0xFFF3F4F6),
                      iconColor: const Color(0xFF111318),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClassAttendanceScreen(
                              classItem: item,
                              gymId: _adminGymId,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    actionTile(
                      icon: Icons.edit_rounded,
                      title: t.editClassActionTitle,
                      subtitle: t.editClassActionSubtitle,
                      iconBg: const Color(0xFFF7F3EA),
                      iconColor: const Color(0xFFB59B6A),
                      onTap: () {
                        Navigator.pop(context);
                        _showClassModal(item: item);
                      },
                    ),
                    const SizedBox(height: 10),
                    actionTile(
                      icon: Icons.delete_outline_rounded,
                      title: t.deleteClassTitle,
                      subtitle: t.deleteClassActionSubtitle,
                      iconBg: const Color(0xFFFEE4E2),
                      iconColor: const Color(0xFFE11D48),
                      titleColor: const Color(0xFFE11D48),
                      onTap: _adminActionBusy
                          ? null
                          : () async {
                              Navigator.pop(context);
                              await _runAdminAction(
                                () => _deleteClass(item['id'].toString()),
                                successMessage: t.classDeleted,
                              );
                            },
                    ),
                    const SizedBox(height: 10),
                    actionTile(
                      icon: Icons.delete_sweep_rounded,
                      title: t.deleteThisAndFutureTitle,
                      subtitle: t.deleteThisAndFutureSubtitle,
                      iconBg: const Color(0xFFFEE4E2),
                      iconColor: const Color(0xFFE11D48),
                      titleColor: const Color(0xFFE11D48),
                      onTap: _adminActionBusy
                          ? null
                          : () async {
                              Navigator.pop(context);

                              setState(() {
                                _adminActionBusy = true;
                              });

                              try {
                                final deleted =
                                    await _deleteFutureClassesForProgramSlot(
                                      item['id'].toString(),
                                    );
                                await _loadAdminData();
                                if (!mounted) return;
                                _toast(t.deletedClassesCount(deleted));
                              } catch (e) {
                                if (!mounted) return;
                                _toast(
                                  e.toString().replaceFirst('Exception: ', ''),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _adminActionBusy = false;
                                  });
                                }
                              }
                            },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: SecondaryButton(
                        text: context.appText.cancel,
                        compact: true,
                        radius: 16,
                        textStyle: _font(
                          16,
                          weight: FontWeight.w700,
                          color: const Color(0xFF344054),
                          letterSpacing: -0.15,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProgramActions(Map<String, dynamic> item) {
    final title = (item['name'] ?? 'Program').toString().trim();
    final subtitle = (item['description'] ?? '').toString().trim();

    Widget actionTile({
      required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback? onTap,
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
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECF1)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _font(
                        16,
                        weight: FontWeight.w800,
                        color: titleColor,
                        letterSpacing: -0.15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: _font(
                          12,
                          weight: FontWeight.w500,
                          color: const Color(0xFF8F96A3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF98A2B3),
                size: 22,
              ),
            ],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final maxHeight = MediaQuery.of(context).size.height * 0.78;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7F9),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7DBE1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFEAECEF)),
                        ),
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
                                Icons.widgets_rounded,
                                color: Color(0xFFB59B6A),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.isEmpty ? 'Program' : title,
                                    style: _font(
                                      18,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFF111318),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: _font(
                                        13,
                                        weight: FontWeight.w500,
                                        color: const Color(0xFF8F96A3),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t.programActionsTitle,
                        style: _font(
                          14,
                          weight: FontWeight.w700,
                          color: const Color(0xFF8F96A3),
                        ),
                      ),
                      const SizedBox(height: 10),
                      actionTile(
                        icon: Icons.edit_rounded,
                        title: t.editProgramTitle,
                        subtitle: t.editProgramActionSubtitle,
                        iconBg: const Color(0xFFF7F3EA),
                        iconColor: const Color(0xFFB59B6A),
                        onTap: () {
                          Navigator.pop(context);
                          _showProgramModal(item: item);
                        },
                      ),
                      const SizedBox(height: 10),
                      actionTile(
                        icon: Icons.delete_outline_rounded,
                        title: t.deleteProgramTitle,
                        subtitle: t.deleteProgramActionSubtitle,
                        iconBg: const Color(0xFFFEE4E2),
                        iconColor: const Color(0xFFE11D48),
                        titleColor: const Color(0xFFE11D48),
                        onTap: _adminActionBusy
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await _runAdminAction(
                                  () => _deleteProgram(item['id'].toString()),
                                  successMessage: t.programDeleted,
                                );
                              },
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: SecondaryButton(
                          text: context.appText.cancel,
                          compact: true,
                          radius: 16,
                          textStyle: _font(
                            16,
                            weight: FontWeight.w700,
                            color: const Color(0xFF344054),
                            letterSpacing: -0.15,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _createPlan({
    required String name,
    required String type,
    required String billing,
    required String price,
    required String classesPerPeriod,
    required String creditsTotal,
    required String bookingWindowDays,
    required String description,
  }) async {
    final gymId = await _resolvedGymIdForAdmin();
    if (gymId == null || gymId.isEmpty) {
      throw Exception(t.gymIdRequiredError);
    }

    final parsedPrice = price.trim().isEmpty
        ? null
        : num.tryParse(price.trim());
    final parsedCredits = creditsTotal.trim().isEmpty
        ? null
        : int.tryParse(creditsTotal.trim());
    final parsedWindow = bookingWindowDays.trim().isEmpty
        ? 7
        : int.tryParse(bookingWindowDays.trim());

    if (name.trim().isEmpty) throw Exception(t.planNameRequiredError);
    if (type.trim().isEmpty) throw Exception(t.planTypeRequiredError);
    if (billing.trim().isEmpty) throw Exception(t.billingPeriodRequiredError);
    if (price.trim().isNotEmpty && parsedPrice == null) {
      throw Exception(t.invalidPriceError);
    }
    if (creditsTotal.trim().isNotEmpty && parsedCredits == null) {
      throw Exception(t.invalidCreditsTotalError);
    }
    if (parsedWindow == null) throw Exception(t.invalidBookingWindowError);

    await _membershipRepo.createPlan(
      gymId: gymId,
      name: name.trim(),
      planType: type.trim(),
      billingPeriod: type.trim() == 'class_pack' ? 'monthly' : billing.trim(),
      price: parsedPrice,
      classesPerPeriod: null,
      creditsTotal: parsedCredits,
      bookingWindowDays: parsedWindow,
      description: description.trim().isEmpty ? null : description.trim(),
    );
  }

  Future<void> _updatePlan({
    required String id,
    required String name,
    required String type,
    required String billing,
    required String price,
    required String classesPerPeriod,
    required String creditsTotal,
    required String bookingWindowDays,
    required String description,
  }) async {
    final parsedPrice = price.trim().isEmpty
        ? null
        : num.tryParse(price.trim());
    final parsedCredits = creditsTotal.trim().isEmpty
        ? null
        : int.tryParse(creditsTotal.trim());
    final parsedWindow = bookingWindowDays.trim().isEmpty
        ? 7
        : int.tryParse(bookingWindowDays.trim());

    if (name.trim().isEmpty) throw Exception(t.planNameRequiredError);
    if (type.trim().isEmpty) throw Exception(t.planTypeRequiredError);
    if (billing.trim().isEmpty) throw Exception(t.billingPeriodRequiredError);
    if (price.trim().isNotEmpty && parsedPrice == null) {
      throw Exception(t.invalidPriceError);
    }
    if (creditsTotal.trim().isNotEmpty && parsedCredits == null) {
      throw Exception(t.invalidCreditsTotalError);
    }
    if (parsedWindow == null) throw Exception(t.invalidBookingWindowError);

    await _membershipRepo.updatePlan(
      gymId: _adminGymId!,
      id: id,
      name: name.trim(),
      planType: type.trim(),
      billingPeriod: type.trim() == 'class_pack' ? 'monthly' : billing.trim(),
      price: parsedPrice,
      classesPerPeriod: null,
      creditsTotal: parsedCredits,
      bookingWindowDays: parsedWindow,
      description: description.trim().isEmpty ? null : description.trim(),
    );
  }

  Future<void> _deletePlan(String id) async {
    await _membershipRepo.deletePlan(gymId: _adminGymId!, id: id);
  }

  Future<void> _assignPlanToMember({
    required String memberId,
    required String planId,
    required String status,
    required String startDate,
    required String endDate,
    required String creditsRemaining,
    required String classesUsed,
  }) async {
    await _membershipRepo.assignPlanToMember(
      memberId: memberId,
      planId: planId,
      status: status,
      startDate: startDate,
      endDate: endDate.trim().isEmpty ? null : endDate.trim(),
      autoRenew: true,
      creditsRemaining: creditsRemaining.trim().isEmpty
          ? null
          : int.tryParse(creditsRemaining.trim()),
      classesUsedCurrentPeriod: int.tryParse(classesUsed.trim()) ?? 0,
    );
  }

  Future<void> _updateMemberRole({
    required String profileId,
    required String role,
  }) async {
    await _profileRepo.updateRole(
      gymId: _adminGymId!,
      profileId: profileId,
      role: role,
    );
  }

  Future<void> _createClass({
    required String programId,
    required String? coachId,
    required String title,
    required String description,
    required String date,
    required String time,
    required String duration,
    required String maxSpots,
    required String location,
  }) async {
    final gymId = await _resolvedGymIdForAdmin();
    if (gymId == null || gymId.isEmpty) {
      throw Exception(t.gymIdRequiredError);
    }

    final parsedDuration = int.tryParse(duration.trim());
    final parsedMaxSpots = int.tryParse(maxSpots.trim());

    if (programId.trim().isEmpty) throw Exception(t.programRequiredError);
    if (date.trim().isEmpty) throw Exception(t.dateRequiredError);
    if (time.trim().isEmpty) throw Exception(t.timeRequiredError);
    if (parsedDuration == null || parsedDuration <= 0) {
      throw Exception(t.invalidDurationError);
    }
    if (parsedMaxSpots == null || parsedMaxSpots <= 0) {
      throw Exception(t.invalidMaxSpotsError);
    }
    if (_isPastClassDateTime(date, time)) {
      throw Exception(t.classesCannotBeInPastError);
    }

    final startsAtIso = _buildUtcIsoFromDateAndTime(date, time);

    await _classRepo.createClass(
      gymId: gymId,
      programId: programId,
      coachId: (coachId ?? '').trim().isEmpty ? null : coachId,
      title: title.trim().isEmpty ? null : title.trim(),
      description: description.trim().isEmpty ? null : description.trim(),
      startsAtIso: startsAtIso,
      durationMinutes: parsedDuration,
      maxSpots: parsedMaxSpots,
      location: location.trim().isEmpty ? null : location.trim(),
    );
  }

  Future<void> _createRecurringClasses({
    required String programId,
    required String? coachId,
    required String title,
    required String description,
    required String startDate,
    required String endDate,
    required List<int> weekdays,
    required List<String> times,
    required String duration,
    required String maxSpots,
    required String location,
  }) async {
    final gymId = await _resolvedGymIdForAdmin();
    if (gymId == null || gymId.isEmpty) {
      throw Exception(t.gymIdRequiredError);
    }

    final parsedDuration = int.tryParse(duration.trim());
    final parsedMaxSpots = int.tryParse(maxSpots.trim());

    if (programId.trim().isEmpty) throw Exception(t.programRequiredError);
    if (startDate.trim().isEmpty) throw Exception(t.startDateRequiredError);
    if (endDate.trim().isEmpty) throw Exception(t.repeatUntilRequiredError);
    if (parsedDuration == null || parsedDuration <= 0) {
      throw Exception(t.invalidDurationError);
    }
    if (parsedMaxSpots == null || parsedMaxSpots <= 0) {
      throw Exception(t.invalidMaxSpotsError);
    }

    final start = DateTime.tryParse(startDate.trim());
    final end = DateTime.tryParse(endDate.trim());

    if (start == null) throw Exception(t.invalidStartDateError);
    if (end == null) throw Exception(t.invalidRepeatUntilDateError);
    if (end.isBefore(start)) {
      throw Exception(t.repeatUntilAfterStartError);
    }

    final selectedWeekdays =
        weekdays.toSet().where((d) => d >= 1 && d <= 7).toList()..sort();
    if (selectedWeekdays.isEmpty) {
      throw Exception(t.selectAtLeastOneWeekdayError);
    }

    final normalizedTimes =
        times.map((t) => t.trim()).where((t) => t.isNotEmpty).toSet().toList()
          ..sort();

    if (normalizedTimes.isEmpty) {
      throw Exception(t.addAtLeastOneTimeError);
    }

    final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    for (final time in normalizedTimes) {
      if (!timeRegex.hasMatch(time)) {
        throw Exception(t.invalidTimeValueError(time));
      }
    }

    final dates = <String>[];
    DateTime cursor = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);

    while (!cursor.isAfter(last)) {
      if (selectedWeekdays.contains(cursor.weekday)) {
        final yyyy = cursor.year.toString().padLeft(4, '0');
        final mm = cursor.month.toString().padLeft(2, '0');
        final dd = cursor.day.toString().padLeft(2, '0');
        dates.add('$yyyy-$mm-$dd');
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    if (dates.isEmpty) {
      throw Exception(t.noClassesGeneratedError);
    }

    for (final date in dates) {
      for (final time in normalizedTimes) {
        if (_isPastClassDateTime(date, time)) {
          continue;
        }

        final startsAtIso = _buildUtcIsoFromDateAndTime(date, time);

        await _classRepo.createClass(
          gymId: gymId,
          programId: programId,
          coachId: (coachId ?? '').trim().isEmpty ? null : coachId,
          title: title.trim().isEmpty ? null : title.trim(),
          description: description.trim().isEmpty ? null : description.trim(),
          startsAtIso: startsAtIso,
          durationMinutes: parsedDuration,
          maxSpots: parsedMaxSpots,
          location: location.trim().isEmpty ? null : location.trim(),
        );
      }
    }
  }

  Future<void> _updateClass({
    required String id,
    required String programId,
    required String? coachId,
    required String title,
    required String description,
    required String date,
    required String time,
    required String duration,
    required String maxSpots,
    required String location,
    required String status,
  }) async {
    final parsedDuration = int.tryParse(duration.trim());
    final parsedMaxSpots = int.tryParse(maxSpots.trim());

    if (programId.trim().isEmpty) throw Exception(t.programRequiredError);
    if (date.trim().isEmpty) throw Exception(t.dateRequiredError);
    if (time.trim().isEmpty) throw Exception(t.timeRequiredError);
    if (parsedDuration == null || parsedDuration <= 0) {
      throw Exception(t.invalidDurationError);
    }
    if (parsedMaxSpots == null || parsedMaxSpots <= 0) {
      throw Exception(t.invalidMaxSpotsError);
    }
    if (_isPastClassDateTime(date, time)) {
      throw Exception(t.classesCannotBeInPastError);
    }

    final startsAtIso = _buildUtcIsoFromDateAndTime(date, time);

    await _classRepo.updateClass(
      gymId: _adminGymId!,
      id: id,
      programId: programId,
      coachId: (coachId ?? '').trim().isEmpty ? null : coachId,
      title: title.trim(),
      description: description.trim(),
      startsAtIso: startsAtIso,
      durationMinutes: parsedDuration,
      maxSpots: parsedMaxSpots,
      location: location.trim(),
      status: status,
    );
  }

  Future<void> _deleteClass(String id) async {
    await _classRepo.deleteClass(gymId: _adminGymId!, id: id);
  }

  Future<int> _deleteFutureClassesForProgramSlot(String classId) async {
    return _classRepo.deleteFutureClassesForProgramSlot(classId);
  }

  Future<void> _createWorkout({
    required String? programId,
    required String title,
    required String description,
    required String workoutDate,
    required String workoutType,
    String? imageUrl,
  }) async {
    final gymId = await _resolvedGymIdForAdmin();
    if (gymId == null || gymId.isEmpty) {
      throw Exception(t.gymIdRequiredError);
    }
    if (title.trim().isEmpty) {
      throw Exception(t.workoutTitleRequiredError);
    }
    if (workoutDate.trim().isEmpty) {
      throw Exception(t.workoutDateRequiredError);
    }

    if (programId != null && programId.trim().isNotEmpty) {
      final existing = await _workoutRepo.findExistingWorkoutForProgramOnDate(
        gymId: gymId,
        programId: programId.trim(),
        workoutDate: workoutDate.trim(),
      );

      if (existing != null) {
        final existingTitle = (existing['title'] ?? 'Workout')
            .toString()
            .trim();
        throw Exception(t.duplicateWorkoutForProgramDateError(existingTitle));
      }
    }

    final workoutId = await _workoutRepo.createWorkout(
      gymId: gymId,
      programId: programId,
      title: title.trim(),
      description: description.trim().isEmpty ? null : description.trim(),
      workoutDate: workoutDate.trim(),
      timeCapMinutes: null,
      workoutType: workoutType.trim().isEmpty ? null : workoutType.trim(),
      createdBy: null,
      imageUrl: imageUrl,
    );

    var autoAssignedCount = 0;
    if (programId != null && programId.trim().isNotEmpty) {
      autoAssignedCount = await _workoutRepo
          .autoAssignWorkoutToProgramClassesOnDate(
            gymId: gymId,
            programId: programId.trim(),
            workoutId: workoutId,
            workoutDate: workoutDate.trim(),
          );
    }

    final selectedProgramName = programId != null && programId.trim().isNotEmpty
        ? (_programs.cast<Map<String, dynamic>?>().firstWhere(
                    (item) =>
                        (item?['id'] ?? '').toString().trim() ==
                        programId.trim(),
                    orElse: () => null,
                  )?['name'] ??
                  '')
              .toString()
              .trim()
        : '';

    try {
      await _notificationRepo.publishWorkoutNotificationIfNeeded(
        gymId: gymId,
        workoutId: workoutId,
        workoutTitle: title.trim(),
        workoutDate: workoutDate.trim(),
        programId: programId,
        programName: selectedProgramName,
      );
    } catch (e) {
      _toast(
        t.workoutNotificationError(
          e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      rethrow;
    }

    if (autoAssignedCount > 0) {
      _toast(t.workoutAutoAssignedMessage(autoAssignedCount));
    }
  }

  Future<void> _updateWorkout({
    required String id,
    required String? programId,
    required String title,
    required String description,
    required String workoutDate,
    required String workoutType,
    String? imageUrl,
  }) async {
    if (title.trim().isEmpty) {
      throw Exception(t.workoutTitleRequiredError);
    }
    if (workoutDate.trim().isEmpty) {
      throw Exception(t.workoutDateRequiredError);
    }

    final gymId = await _resolvedGymIdForAdmin();
    if (gymId == null || gymId.isEmpty) {
      throw Exception(t.gymIdRequiredError);
    }

    if (programId != null && programId.trim().isNotEmpty) {
      final existing = await _workoutRepo.findExistingWorkoutForProgramOnDate(
        gymId: gymId,
        programId: programId.trim(),
        workoutDate: workoutDate.trim(),
        excludeWorkoutId: id,
      );

      if (existing != null) {
        final existingTitle = (existing['title'] ?? 'Workout')
            .toString()
            .trim();
        throw Exception(t.duplicateWorkoutForProgramDateError(existingTitle));
      }
    }

    await _workoutRepo.updateWorkout(
      gymId: _adminGymId!,
      id: id,
      programId: programId,
      title: title.trim(),
      description: description.trim().isEmpty ? null : description.trim(),
      workoutDate: workoutDate.trim(),
      timeCapMinutes: null,
      workoutType: workoutType.trim().isEmpty ? null : workoutType.trim(),
      imageUrl: imageUrl,
    );
  }

  Future<void> _deleteWorkout(String id) async {
    await _workoutRepo.deleteWorkout(gymId: _adminGymId!, id: id);
  }

  Future<void> _assignWorkoutToClass({
    required String classId,
    required String workoutId,
  }) async {
    await _workoutRepo.assignWorkoutToClass(
      classId: classId,
      workoutId: workoutId,
    );
  }

  Widget _adminInfoChip({
    required IconData icon,
    required String text,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7EBF0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: foregroundColor ?? const Color(0xFF667085),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: _font(
                11,
                weight: FontWeight.w700,
                color: foregroundColor ?? const Color(0xFF475467),
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberStatusChip(bool isActive) {
    final bg = isActive ? const Color(0xFFE7F6EC) : const Color(0xFFFEE4E2);
    final fg = isActive ? const Color(0xFF1F8A4C) : const Color(0xFFB42318);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: _font(
          10,
          weight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _memberRoleChip(String role) {
    final normalizedRole = role.trim().toLowerCase();

    Color bg;
    Color fg;
    String label;

    switch (normalizedRole) {
      case 'admin':
        bg = const Color(0xFFF7F3EA);
        fg = const Color(0xFFB59B6A);
        label = 'ADMIN';
        break;
      case 'coach':
        bg = const Color(0xFFEFF4FB);
        fg = const Color(0xFF245BEB);
        label = 'COACH';
        break;
      default:
        bg = const Color(0xFFEFF4FB);
        fg = const Color(0xFF245BEB);
        label = 'ATHLETE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: _font(
          10,
          weight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _memberMembershipBanner({
    required String planName,
    required String planSummary,
    required String membershipMeta,
    required bool hasMembership,
  }) {
    final bg = hasMembership
        ? const Color(0xFFF7F3EA)
        : const Color(0xFFF6F7F9);
    final border = hasMembership
        ? const Color(0xFFE7D7B0)
        : const Color(0xFFE7EBF0);
    final accent = hasMembership
        ? const Color(0xFFB59B6A)
        : const Color(0xFF98A2B3);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: hasMembership ? 0.75 : 0.9,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 18,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  planName,
                  style: _font(
                    15,
                    weight: FontWeight.w800,
                    color: const Color(0xFF111318),
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            planSummary,
            style: _font(
              12,
              weight: FontWeight.w700,
              color: hasMembership
                  ? const Color(0xFF8A6F3E)
                  : const Color(0xFF667085),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            membershipMeta,
            style: _font(
              11,
              weight: FontWeight.w500,
              color: const Color(0xFF667085),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _membersTab() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.adminMembersTab,
                style: _font(
                  18,
                  weight: FontWeight.w800,
                  color: const Color(0xFF111318),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            GestureDetector(
              onTap: _adminActionBusy ? null : _loadAdminData,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE7EBF0)),
                ),
                alignment: Alignment.center,
                child: Text(
                  t.refresh,
                  style: _font(
                    14,
                    weight: FontWeight.w700,
                    color: const Color(0xFF111318),
                    letterSpacing: -0.05,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _adminActionBusy ? null : _showMemberOnboardingModal,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFB59B6A),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  t.addUpper,
                  style: _font(
                    15,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.05,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SearchField(hint: t.searchMembers),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_members.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEFF1F4)),
            ),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F3EA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.people_outline_rounded,
                    color: Color(0xFFB59B6A),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.noMembersYet,
                  style: _font(
                    18,
                    weight: FontWeight.w800,
                    color: const Color(0xFF111318),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.noMembersYetSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8F96A3),
                  ),
                ),
              ],
            ),
          )
        else
          ..._members.map((member) {
            final memberId = member['id']?.toString() ?? '';
            final activeMembership = _memberActiveMembership[memberId];
            final status = (member['is_active'] == true)
                ? 'active'
                : 'inactive';
            final role = (member['role'] ?? 'athlete').toString();

            final planName = activeMembership == null
                ? t.noPlanShort
                : ((activeMembership['membership_plans'] ?? {})['name'] ??
                          'Plan')
                      .toString();
            final rawPlanType =
                ((activeMembership?['membership_plans'] ?? {})['plan_type'] ??
                        '')
                    .toString();

            final planSummary = activeMembership == null
                ? t.cannotBookFutureClasses
                : (rawPlanType == 'class_pack' || rawPlanType == 'drop_in'
                      ? t.creditsRemainingText(
                          activeMembership['credits_remaining'] ?? 0,
                        )
                      : t.unlimitedAccess);

            final endDate = (activeMembership?['end_date'] ?? '').toString();
            final autoRenew = activeMembership?['auto_renew'] == true;
            final membershipMeta = activeMembership == null
                ? t.noActiveMembershipShort
                : (endDate.isNotEmpty
                      ? t.activeUntilAutoRenew(endDate, autoRenew)
                      : t.noEndDateAutoRenew(autoRenew));

            final fullName =
                (member['full_name'] ?? _uiText('Miembro', 'Member'))
                    .toString()
                    .trim();
            final email = (member['email'] ?? '-').toString();
            final phone =
                ((member['phone'] ?? '').toString().isEmpty
                        ? '-'
                        : member['phone'])
                    .toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: _adminActionBusy
                    ? null
                    : () {
                        final memberId = (member['id'] ?? '').toString().trim();
                        if (memberId.isEmpty) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminMemberDetailScreen(
                              gymId: _adminGymId!,
                              memberId: memberId,
                            ),
                          ),
                        );
                      },
                child: AppCard(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
                              Icons.person_rounded,
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
                                  fullName,
                                  style: _font(
                                    21,
                                    weight: FontWeight.w800,
                                    color: const Color(0xFF111318),
                                    letterSpacing: -0.22,
                                    height: 0.98,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  email,
                                  style: _font(
                                    13,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF667085),
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _adminActionBusy
                                ? null
                                : () => _showMemberActions(member),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: const Icon(
                                Icons.more_horiz_rounded,
                                size: 20,
                                color: Color(0xFF667085),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _memberStatusChip(status == 'active'),
                          _memberRoleChip(role),
                          if (phone != '-')
                            _adminInfoChip(
                              icon: Icons.call_outlined,
                              text: phone,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: activeMembership != null
                              ? const Color(0xFFFFFBF5)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: activeMembership != null
                                ? const Color(0xFFE7D7B0)
                                : const Color(0xFFE7EBF0),
                          ),
                        ),
                        child: _memberMembershipBanner(
                          planName: planName,
                          planSummary: planSummary,
                          membershipMeta: membershipMeta,
                          hasMembership: activeMembership != null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _adminTabChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: 46,
        constraints: const BoxConstraints(minWidth: 116),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFB59B6A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFB59B6A) : const Color(0xFFE2E8F0),
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        alignment: Alignment.center,
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _font(
            13,
            weight: FontWeight.w800,
            color: selected ? Colors.white : const Color(0xFF344054),
            letterSpacing: -0.05,
          ),
        ),
      ),
    );
  }

  void _showAssignPlanModal(Map<String, dynamic> member) {
    if (_plans.isEmpty) return;

    String selectedPlanId = _plans.first['id'].toString();
    String selectedStatus = 'active';
    final startCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );
    final endCtrl = TextEditingController(text: '');
    final creditsCtrl = TextEditingController(text: '');
    final usedCtrl = TextEditingController(text: '0');

    final memberName = member['full_name']?.toString().trim().isNotEmpty == true
        ? member['full_name'].toString().trim()
        : 'Member';
    final memberEmail = member['email']?.toString().trim() ?? '';
    final memberRole = (member['role'] ?? 'athlete').toString();

    Future<void> pickDate(
      BuildContext context,
      TextEditingController controller,
    ) async {
      DateTime initialDate = DateTime.now();
      final raw = controller.text.trim();
      if (raw.isNotEmpty) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) initialDate = parsed;
      }

      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2024),
        lastDate: DateTime(2035),
      );

      if (picked != null) {
        controller.text = picked.toIso8601String().split('T').first;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            top: 36,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF6F7F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SafeArea(
              top: false,
              child: StatefulBuilder(
                builder: (context, setLocalState) {
                  final selectedPlan = _plans.firstWhere(
                    (p) => p['id'].toString() == selectedPlanId,
                    orElse: () => _plans.first,
                  );
                  selectedPlan['description']?.toString().trim() ?? '';

                  Widget sectionTitle(String text) {
                    return Text(
                      text,
                      style: _font(
                        15,
                        weight: FontWeight.w800,
                        color: const Color(0xFF111318),
                        letterSpacing: -0.1,
                      ),
                    );
                  }

                  InputDecoration dropdownDecoration(String label) {
                    return InputDecoration(
                      labelText: label,
                      labelStyle: _font(
                        12,
                        weight: FontWeight.w500,
                        color: const Color(0xFF667085),
                      ),
                      floatingLabelStyle: _font(
                        12,
                        weight: FontWeight.w600,
                        color: const Color(0xFF667085),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFB59B6A),
                          width: 1.2,
                        ),
                      ),
                    );
                  }

                  Widget metricField({
                    required String label,
                    required TextEditingController controller,
                    required String hint,
                    TextInputType? keyboardType,
                    bool readOnly = false,
                    VoidCallback? onTap,
                    Widget? suffixIcon,
                  }) {
                    return InputField(
                      label: label,
                      controller: controller,
                      hint: hint,
                      keyboardType: keyboardType,
                      readOnly: readOnly,
                      onTap: onTap,
                      suffixIcon: suffixIcon,
                      fillColor: const Color(0xFFF8FAFC),
                      borderColor: const Color(0xFFE2E8F0),
                      focusedBorderColor: const Color(0xFFB59B6A),
                      radius: 16,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      labelStyle: _font(
                        12,
                        weight: FontWeight.w500,
                        color: const Color(0xFF667085),
                      ),
                      hintStyle: _font(
                        13,
                        weight: FontWeight.w500,
                        color: const Color(0xFF98A2B3),
                      ),
                      textStyle: _font(
                        13,
                        weight: FontWeight.w500,
                        color: const Color(0xFF111318),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    child: Column(
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
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F3EA),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.assignment_rounded,
                                color: Color(0xFFB59B6A),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.assignPlanTitle,
                                    style: _font(
                                      24,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFF111318),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    t.assignPlanSubtitle,
                                    style: _font(
                                      13,
                                      weight: FontWeight.w500,
                                      color: const Color(0xFF8F96A3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE8EBF0),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 22,
                                  color: Color(0xFF111318),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFEAECEF)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF111318),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      memberName,
                                      style: _font(
                                        18,
                                        weight: FontWeight.w800,
                                        color: const Color(0xFF111318),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    if (memberEmail.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        memberEmail,
                                        style: _font(
                                          13,
                                          weight: FontWeight.w500,
                                          color: const Color(0xFF8F96A3),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F3EA),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  memberRole.toUpperCase(),
                                  style: _font(
                                    11,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFFB59B6A),
                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        sectionTitle('Plan setup'),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFEAECEF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: selectedPlanId,
                                decoration: dropdownDecoration('Plan'),
                                borderRadius: BorderRadius.circular(16),
                                dropdownColor: Colors.white,
                                iconEnabledColor: const Color(0xFF667085),
                                style: _font(
                                  13,
                                  weight: FontWeight.w500,
                                  color: const Color(0xFF111318),
                                ),
                                items: _plans
                                    .map(
                                      (p) => DropdownMenuItem<String>(
                                        value: p['id'].toString(),
                                        child: Text(
                                          p['name'].toString(),
                                          style: _font(
                                            13,
                                            weight: FontWeight.w500,
                                            color: const Color(0xFF111318),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                selectedItemBuilder: (context) {
                                  return _plans
                                      .map(
                                        (p) => Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            p['name'].toString(),
                                            style: _font(
                                              13,
                                              weight: FontWeight.w500,
                                              color: const Color(0xFF111318),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList();
                                },
                                onChanged: (value) {
                                  if (value != null) {
                                    setLocalState(() {
                                      selectedPlanId = value;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: selectedStatus,
                                decoration: dropdownDecoration(t.statusLabel),
                                borderRadius: BorderRadius.circular(16),
                                dropdownColor: Colors.white,
                                iconEnabledColor: const Color(0xFF667085),
                                style: _font(
                                  13,
                                  weight: FontWeight.w500,
                                  color: const Color(0xFF111318),
                                ),
                                items:
                                    [
                                      DropdownMenuItem(
                                        value: 'active',
                                        child: Text(t.activeLabel),
                                      ),
                                      DropdownMenuItem(
                                        value: 'paused',
                                        child: Text(t.pausedLabel),
                                      ),
                                      DropdownMenuItem(
                                        value: 'expired',
                                        child: Text(t.expiredLabel),
                                      ),
                                      DropdownMenuItem(
                                        value: 'cancelled',
                                        child: Text(t.cancelledLabel),
                                      ),
                                      DropdownMenuItem(
                                        value: 'pending_payment',
                                        child: Text(t.pendingPaymentLabel),
                                      ),
                                    ].map((item) {
                                      return DropdownMenuItem<String>(
                                        value: item.value,
                                        child: Text(
                                          (item.child as Text).data ?? '',
                                          style: _font(
                                            13,
                                            weight: FontWeight.w500,
                                            color: const Color(0xFF111318),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                selectedItemBuilder: (context) {
                                  final labels = [
                                    t.activeLabel,
                                    t.pausedLabel,
                                    t.expiredLabel,
                                    t.cancelledLabel,
                                    t.pendingPaymentLabel,
                                  ];
                                  return labels
                                      .map(
                                        (label) => Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            label,
                                            style: _font(
                                              13,
                                              weight: FontWeight.w500,
                                              color: const Color(0xFF111318),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList();
                                },
                                onChanged: (value) {
                                  if (value != null) {
                                    setLocalState(() {
                                      selectedStatus = value;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        sectionTitle('Billing period'),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFEAECEF)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: metricField(
                                      label: t.startDateShort,
                                      controller: startCtrl,
                                      hint: '2026-03-12',
                                      readOnly: true,
                                      onTap: () async {
                                        await pickDate(context, startCtrl);
                                        setLocalState(() {});
                                      },
                                      suffixIcon: const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 18,
                                        color: Color(0xFF98A2B3),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: metricField(
                                      label: t.endDateShort,
                                      controller: endCtrl,
                                      hint: '2026-04-12',
                                      readOnly: true,
                                      onTap: () async {
                                        await pickDate(context, endCtrl);
                                        setLocalState(() {});
                                      },
                                      suffixIcon: const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 18,
                                        color: Color(0xFF98A2B3),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: metricField(
                                      label: t.creditsLabel,
                                      controller: creditsCtrl,
                                      hint: '10',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: metricField(
                                      label: t.usedLabel,
                                      controller: usedCtrl,
                                      hint: '0',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                text: context.appText.cancel,
                                compact: true,
                                radius: 16,
                                backgroundColor: const Color(0xFFF3F4F6),
                                pressedColor: const Color(0xFFE5E7EB),
                                textColor: const Color(0xFF344054),
                                textStyle: _font(
                                  16,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF344054),
                                  letterSpacing: -0.15,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                text: t.assignCta,
                                compact: true,
                                radius: 16,
                                backgroundColor: const Color(0xFFB59B6A),
                                pressedColor: const Color(0xFFA88C59),
                                disabledColor: const Color(0xFFC9C9C9),
                                textColor: Colors.white,
                                textStyle: _font(
                                  16,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.15,
                                ),
                                boxShadow: const [],
                                onPressed: () async {
                                  await _runAdminAction(
                                    () => _assignPlanToMember(
                                      memberId: member['id'].toString(),
                                      planId: selectedPlanId,
                                      status: selectedStatus,
                                      startDate: startCtrl.text.trim(),
                                      endDate: endCtrl.text.trim(),
                                      creditsRemaining: creditsCtrl.text.trim(),
                                      classesUsed: usedCtrl.text.trim(),
                                    ),
                                    successMessage: t.planAssigned,
                                  );
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateMemberActiveStatus({
    required String profileId,
    required bool isActive,
  }) async {
    await _profileRepo.updateMemberActiveStatus(
      gymId: _adminGymId!,
      profileId: profileId,
      isActive: isActive,
    );
  }

  Future<void> _sendMemberPasswordEmail({required String email}) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      throw Exception('This member does not have an email.');
    }

    await _authRepo.resetPassword(cleanEmail, redirectTo: 'athletelab://auth');
  }

  void _showMemberActions(Map<String, dynamic> member) {
    final memberId = member['id']?.toString() ?? '';
    final role = (member['role'] ?? 'athlete').toString();
    final memberName = member['full_name']?.toString().trim().isNotEmpty == true
        ? member['full_name'].toString().trim()
        : 'Member';
    final memberEmail = member['email']?.toString().trim() ?? '';

    Widget actionTile({
      required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback? onTap,
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
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECF1)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _font(
                        16,
                        weight: FontWeight.w800,
                        color: titleColor,
                        letterSpacing: -0.15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: _font(
                          12,
                          weight: FontWeight.w500,
                          color: const Color(0xFF8F96A3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF98A2B3),
                size: 22,
              ),
            ],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final media = MediaQuery.of(context);
        final maxHeight = media.size.height * 0.78;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7F9),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD7DBE1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFEAECEF)),
                        ),
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
                                Icons.person_rounded,
                                color: Color(0xFFB59B6A),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    memberName,
                                    style: _font(
                                      18,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFF111318),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (memberEmail.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      memberEmail,
                                      style: _font(
                                        13,
                                        weight: FontWeight.w500,
                                        color: const Color(0xFF8F96A3),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: _font(
                                  11,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF667085),
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t.memberActionsTitle,
                        style: _font(
                          14,
                          weight: FontWeight.w700,
                          color: const Color(0xFF8F96A3),
                        ),
                      ),
                      const SizedBox(height: 10),
                      actionTile(
                        icon: Icons.assignment_rounded,
                        title: t.assignPlanTitle,
                        subtitle: 'Add or change this athlete\'s membership',
                        iconBg: const Color(0xFFF7F3EA),
                        iconColor: const Color(0xFFB59B6A),
                        onTap: () {
                          Navigator.pop(context);
                          _showAssignPlanModal(member);
                        },
                      ),
                      const SizedBox(height: 10),
                      actionTile(
                        icon: Icons.mark_email_read_outlined,
                        title: t.sendPasswordEmailTitle,
                        subtitle: t.sendPasswordEmailSubtitle,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF245BEB),
                        onTap: _adminActionBusy
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await _runAdminAction(
                                  () => _sendMemberPasswordEmail(
                                    email: memberEmail,
                                  ),
                                  successMessage: t.passwordEmailSent,
                                );
                              },
                      ),
                      if (member['is_active'] == true) ...[
                        const SizedBox(height: 10),
                        actionTile(
                          icon: Icons.pause_circle_outline_rounded,
                          title: t.deactivateMemberTitle,
                          subtitle: t.deactivateMemberSubtitle,
                          iconBg: const Color(0xFFFEE4E2),
                          iconColor: const Color(0xFFE11D48),
                          onTap: _adminActionBusy
                              ? null
                              : () async {
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  await _runAdminAction(
                                    () => _updateMemberActiveStatus(
                                      profileId: memberId,
                                      isActive: false,
                                    ),
                                    successMessage: t.memberDeactivated,
                                  );
                                },
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        actionTile(
                          icon: Icons.check_circle_outline_rounded,
                          title: t.activateMemberTitle,
                          subtitle: t.activateMemberSubtitle,
                          iconBg: const Color(0xFFDDF5E5),
                          iconColor: const Color(0xFF16A34A),
                          onTap: _adminActionBusy
                              ? null
                              : () async {
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  await _runAdminAction(
                                    () => _updateMemberActiveStatus(
                                      profileId: memberId,
                                      isActive: true,
                                    ),
                                    successMessage: t.memberActivated,
                                  );
                                },
                        ),
                      ],
                      if (role != 'athlete') ...[
                        const SizedBox(height: 10),
                        actionTile(
                          icon: Icons.sports_gymnastics_rounded,
                          title: t.makeAthleteTitle,
                          subtitle: t.makeAthleteSubtitle,
                          onTap: _adminActionBusy
                              ? null
                              : () async {
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  await _runAdminAction(
                                    () => _updateMemberRole(
                                      profileId: memberId,
                                      role: 'athlete',
                                    ),
                                    successMessage: t.roleUpdatedToAthlete,
                                  );
                                },
                        ),
                      ],
                      if (role != 'coach') ...[
                        const SizedBox(height: 10),
                        actionTile(
                          icon: Icons.fitness_center_rounded,
                          title: _uiText('Convertir en coach', 'Make coach'),
                          subtitle: _uiText(
                            'Dar acceso como coach de este gym',
                            'Give this member coach access for this gym',
                          ),
                          onTap: _adminActionBusy
                              ? null
                              : () async {
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  await _runAdminAction(
                                    () => _updateMemberRole(
                                      profileId: memberId,
                                      role: 'coach',
                                    ),
                                    successMessage: _uiText(
                                      'Rol actualizado a coach',
                                      'Role updated to coach',
                                    ),
                                  );
                                },
                        ),
                      ],
                      if (role != 'admin') ...[
                        const SizedBox(height: 10),
                        actionTile(
                          icon: Icons.shield_rounded,
                          title: t.makeAdminTitle,
                          subtitle: t.makeAdminSubtitle,
                          onTap: _adminActionBusy
                              ? null
                              : () async {
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  await _runAdminAction(
                                    () => _updateMemberRole(
                                      profileId: memberId,
                                      role: 'admin',
                                    ),
                                    successMessage: t.roleUpdatedToAdmin,
                                  );
                                },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _programsTab() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.adminProgramsTab,
                style: _font(
                  18,
                  weight: FontWeight.w800,
                  color: const Color(0xFF111318),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            GestureDetector(
              onTap: _adminActionBusy ? null : () => _showProgramModal(),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFB59B6A),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  t.addUpper,
                  style: _font(
                    15,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.05,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_programs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEFF1F4)),
            ),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F3EA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_outlined,
                    color: Color(0xFFB59B6A),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.noProgramsYet,
                  style: _font(
                    18,
                    weight: FontWeight.w800,
                    color: const Color(0xFF111318),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.noProgramsYetSubtitle,
                  textAlign: TextAlign.center,
                  style: _font(
                    14,
                    weight: FontWeight.w500,
                    color: const Color(0xFF8F96A3),
                    height: 1.4,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          )
        else
          ..._programs.map((item) {
            final programName = (item['name'] ?? 'Program').toString();
            final description = (item['description'] ?? '').toString().trim();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: _adminActionBusy
                    ? null
                    : () => _showProgramModal(item: item),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              programName.toUpperCase(),
                              style: _font(
                                20,
                                weight: FontWeight.w800,
                                color: const Color(0xFF111318),
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                description,
                                style: _font(
                                  14,
                                  weight: FontWeight.w500,
                                  color: const Color(0xFF6F7782),
                                  height: 1.35,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _adminActionBusy
                            ? null
                            : () => _showProgramActions(item),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDEBE6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            size: 20,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  bool _isTodayClass(DateTime dt, DateTime now) {
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  bool _matchesClassesFilter(Map<String, dynamic> item, String filter) {
    final raw = (item['starts_at'] ?? '').toString().trim();
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final classDay = DateTime(dt.year, dt.month, dt.day);

    if (filter == 'today') {
      return _isTodayClass(dt, now);
    }

    if (filter == 'upcoming') {
      return classDay.isAfter(today);
    }

    if (filter == 'past') {
      return classDay.isBefore(today);
    }

    return true;
  }

  int _countClassesForFilter(String filter) {
    return _classes.where((item) => _matchesClassesFilter(item, filter)).length;
  }

  List<Map<String, dynamic>> _filterClassesList(
    List<Map<String, dynamic>> items,
  ) {
    final filtered = items
        .where((item) => _matchesClassesFilter(item, _classesFilter))
        .toList();

    filtered.sort((a, b) {
      final da = DateTime.parse(a['starts_at'].toString()).toLocal();
      final db = DateTime.parse(b['starts_at'].toString()).toLocal();
      if (_classesFilter == 'past') {
        return db.compareTo(da);
      }
      return da.compareTo(db);
    });

    return filtered;
  }

  Widget _buildClassesFilterTabs() {
    Widget chip(String key, String label) {
      final selected = _classesFilter == key;
      final count = _countClassesForFilter(key);
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _classesFilter = key),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF111318) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF111318)
                    : const Color(0xFFEAECEF),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              t.adminFilterWithCount(label, count),
              style: _font(
                13,
                weight: FontWeight.w800,
                color: selected ? Colors.white : const Color(0xFF111318),
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('today', t.todayUpperShort),
        const SizedBox(width: 8),
        chip('upcoming', t.upcomingUpper),
        const SizedBox(width: 8),
        chip('past', t.pastUpper),
      ],
    );
  }

  Widget _classesTab() {
    final filteredClasses = _filterClassesList(_classes);

    final emptyTitle = _classesFilter == 'today'
        ? t.noClassesToday
        : _classesFilter == 'upcoming'
        ? t.noUpcomingClasses
        : t.noPastClasses;

    final emptySubtitle = _classesFilter == 'today'
        ? t.noClassesTodaySubtitle
        : _classesFilter == 'upcoming'
        ? t.noUpcomingClassesSubtitle
        : t.noPastClassesSubtitle;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.adminClassesTab,
                style: _font(
                  18,
                  weight: FontWeight.w800,
                  color: const Color(0xFF111318),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            GestureDetector(
              onTap: _adminActionBusy ? null : () => _showClassModal(),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFB59B6A),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  t.addUpper,
                  style: _font(
                    15,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.05,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildClassesFilterTabs(),
        const SizedBox(height: 12),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (filteredClasses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEFF1F4)),
            ),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F3EA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFFB59B6A),
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  emptyTitle,
                  style: _font(
                    18,
                    weight: FontWeight.w800,
                    color: const Color(0xFF111318),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  emptySubtitle,
                  textAlign: TextAlign.center,
                  style: _font(
                    14,
                    weight: FontWeight.w500,
                    color: const Color(0xFF8F96A3),
                    height: 1.4,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          )
        else
          ...filteredClasses.map((item) {
            final dt = DateTime.tryParse(
              item['starts_at'].toString(),
            )?.toLocal();
            final dateLabel = dt != null
                ? DateFormat('EEE, MMM d · HH:mm').format(dt)
                : '-';
            final program = (item['program_name'] ?? context.appText.classLabel)
                .toString();
            final title = (item['title'] ?? '').toString();
            final coach = (item['coach_name'] ?? '').toString().trim();
            final coachLabel = coach.isEmpty
                ? _uiText('Sin coach', 'No coach')
                : coach;
            final remainingValue = item['remaining_spots'] ?? 0;
            final totalValue = item['max_spots'] ?? 0;
            final remaining = remainingValue.toString();
            final total = totalValue.toString();
            final workoutTitle = (item['workout_title'] ?? '')
                .toString()
                .trim();
            final hasWorkout = workoutTitle.isNotEmpty;
            final duration = (item['duration_minutes'] ?? 60).toString();
            final isFull = (item['remaining_spots'] ?? 0) <= 0;
            final classHeadline =
                title.isNotEmpty && title.toLowerCase() != program.toLowerCase()
                ? title
                : program;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: _adminActionBusy
                    ? null
                    : () => _showClassModal(item: item),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F3EA),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    program.toUpperCase(),
                                    style: _font(
                                      11,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFF8A6F3E),
                                      letterSpacing: 0.35,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasWorkout
                                        ? const Color(0xFFE7F6EC)
                                        : const Color(0xFFFEE4E2),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    hasWorkout
                                        ? _uiText(
                                            'Con workout',
                                            'Workout assigned',
                                          )
                                        : _uiText(
                                            'Sin workout',
                                            'Workout missing',
                                          ),
                                    style: _font(
                                      11,
                                      weight: FontWeight.w800,
                                      color: hasWorkout
                                          ? const Color(0xFF1F8A4C)
                                          : const Color(0xFFB42318),
                                      letterSpacing: 0.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              classHeadline,
                              style: _font(
                                20,
                                weight: FontWeight.w800,
                                color: const Color(0xFF111318),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateLabel,
                              style: _font(
                                13,
                                weight: FontWeight.w500,
                                color: const Color(0xFF667085),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _adminInfoChip(
                                  icon: Icons.schedule_rounded,
                                  text: t.durationMinutesShort(duration),
                                ),
                                _adminInfoChip(
                                  icon: Icons.person_outline_rounded,
                                  text: coachLabel,
                                ),
                                _adminInfoChip(
                                  icon: isFull
                                      ? Icons.block_rounded
                                      : Icons.groups_2_outlined,
                                  text: isFull
                                      ? _uiText(
                                          'Completa · $total/$total',
                                          'Full · $total/$total',
                                        )
                                      : t.spotsCountLabel(remaining, total),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: hasWorkout
                                    ? const Color(0xFFFFFBF5)
                                    : const Color(0xFFFFF6F5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: hasWorkout
                                      ? const Color(0xFFE7D7B0)
                                      : const Color(0xFFF3C7C2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    hasWorkout
                                        ? Icons.fitness_center_rounded
                                        : Icons.warning_amber_rounded,
                                    size: 18,
                                    color: hasWorkout
                                        ? const Color(0xFFB59B6A)
                                        : const Color(0xFFB42318),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      hasWorkout
                                          ? t.workoutTitleWithName(workoutTitle)
                                          : context
                                                .appText
                                                .workoutNotAssignedLabel,
                                      style: _font(
                                        13,
                                        weight: FontWeight.w700,
                                        color: hasWorkout
                                            ? const Color(0xFF8A6F3E)
                                            : const Color(0xFFB42318),
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _adminActionBusy
                            ? null
                            : () => _showClassActions(item),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            size: 20,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _workoutsTab() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.adminWorkoutsTab,
                style: _font(
                  18,
                  weight: FontWeight.w800,
                  color: const Color(0xFF111318),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            GestureDetector(
              onTap: _adminActionBusy ? null : () => _showWorkoutModal(),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFB59B6A),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  t.addUpper,
                  style: _font(
                    15,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.05,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_workouts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEFF1F4)),
            ),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F3EA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.fitness_center_outlined,
                    color: Color(0xFFB59B6A),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.noWorkoutsYet,
                  style: _font(
                    18,
                    weight: FontWeight.w800,
                    color: const Color(0xFF111318),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.noWorkoutsYetSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8F96A3),
                  ),
                ),
              ],
            ),
          )
        else
          ..._workouts.map((item) {
            final program =
                (item['program_name'] ?? _uiText('Workout', 'Workout'))
                    .toString()
                    .trim();
            final rawDate = (item['workout_date'] ?? '').toString();
            final title = (item['title'] ?? _uiText('Workout', 'Workout'))
                .toString()
                .trim();
            final description = (item['description'] ?? '').toString().trim();
            final imageUrl = (item['image_url'] ?? '').toString().trim();

            final parsedDate = DateTime.tryParse(rawDate)?.toLocal();
            final dateLabel = parsedDate != null
                ? DateFormat('EEE, MMM d').format(parsedDate)
                : '';
            final headline = title.isEmpty
                ? _uiText('Workout', 'Workout')
                : title;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: _adminActionBusy
                    ? null
                    : () => _showWorkoutModal(item: item),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (imageUrl.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  imageUrl,
                                  height: 148,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 148,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF2F4F7),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 32,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F3EA),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    program.toUpperCase(),
                                    style: _font(
                                      11,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFF8A6F3E),
                                      letterSpacing: 0.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              headline,
                              style: _font(
                                20,
                                weight: FontWeight.w800,
                                color: const Color(0xFF111318),
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (dateLabel.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                dateLabel,
                                style: _font(
                                  13,
                                  weight: FontWeight.w500,
                                  color: const Color(0xFF667085),
                                  height: 1.35,
                                ),
                              ),
                            ],
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: _font(
                                  13,
                                  weight: FontWeight.w500,
                                  color: const Color(0xFF667085),
                                  height: 1.32,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _adminActionBusy
                            ? null
                            : () => _showWorkoutActions(item),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            size: 20,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _plansTab() {
    String prettyType(String raw) {
      if (raw.trim().isEmpty) return 'PLAN';
      return raw.replaceAll('_', ' ').toUpperCase();
    }

    String prettyBilling(String raw) {
      if (raw.trim().isEmpty) return '-';
      final value = raw.replaceAll('_', ' ').trim();
      return value[0].toUpperCase() + value.substring(1);
    }

    String priceLabel(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) return '- €';
      return '${value.toString()} €';
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.adminPlansTab,
                style: _font(
                  18,
                  weight: FontWeight.w800,
                  color: const Color(0xFF111318),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            GestureDetector(
              onTap: _adminActionBusy ? null : () => _showPlanModal(),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFB59B6A),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  t.addUpper,
                  style: _font(
                    15,
                    weight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.05,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_plans.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEFF1F4)),
            ),
            child: Column(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F3EA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: Color(0xFFB59B6A),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.noPlansYet,
                  style: _font(
                    18,
                    weight: FontWeight.w800,
                    color: const Color(0xFF111318),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.noPlansYetSubtitle,
                  textAlign: TextAlign.center,
                  style: _font(
                    13,
                    weight: FontWeight.w500,
                    color: const Color(0xFF8F96A3),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          )
        else
          ..._plans.map((plan) {
            final name = (plan['name'] ?? t.planFallbackLabel).toString();
            final description = (plan['description'] ?? '').toString().trim();
            final planType = (plan['plan_type'] ?? '').toString();
            final billing = (plan['billing_period'] ?? '').toString();
            final price = plan['price'];
            final bookingWindow = (plan['booking_window_days'] ?? '7')
                .toString();
            final classesPerPeriod = (plan['classes_per_period'] ?? '')
                .toString();
            final creditsTotal = (plan['credits_total'] ?? '').toString();

            String accessLine = t.bookingWindowDaysText(bookingWindow);
            if (classesPerPeriod.isNotEmpty && classesPerPeriod != 'null') {
              accessLine = t.classesPerPeriodText(classesPerPeriod, accessLine);
            } else if (creditsTotal.isNotEmpty && creditsTotal != 'null') {
              accessLine = t.creditsTotalText(creditsTotal, accessLine);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F3EA),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              prettyType(planType),
                              style: _font(
                                10,
                                weight: FontWeight.w700,
                                color: const Color(0xFFB59B6A),
                                letterSpacing: 0.35,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name.toUpperCase(),
                            style: _font(
                              20,
                              weight: FontWeight.w800,
                              color: const Color(0xFF111318),
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _font(
                                13,
                                weight: FontWeight.w500,
                                color: const Color(0xFF8F96A3),
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: const Color(0xFFEFF1F4),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '${priceLabel(price)} · ${prettyBilling(billing)}',
                            style: _font(
                              13,
                              weight: FontWeight.w700,
                              color: const Color(0xFFB59B6A),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            accessLine,
                            style: _font(
                              13,
                              weight: FontWeight.w500,
                              color: const Color(0xFF667085),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _adminActionBusy
                          ? null
                          : () => _showPlanActions(plan),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDEBE6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.more_horiz_rounded,
                          size: 20,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _topHeader(),
          Expanded(
            child: IgnorePointer(
              ignoring: _adminActionBusy,
              child: RefreshIndicator(
                color: const Color(0xFFB59B6A),
                backgroundColor: Colors.white,
                onRefresh: _loadAdminData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(tabs.length, (i) {
                          return Padding(
                            key: _tabChipKeys[i],
                            padding: EdgeInsets.only(
                              right: i == tabs.length - 1 ? 0 : 8,
                            ),
                            child: _adminTabChip(
                              label: tabs[i],
                              selected: i == tabIndex,
                              onTap: () {
                                setState(() => tabIndex = i);
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!mounted) return;
                                  _scrollToActiveTab();
                                });
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (tabIndex == 0) _programsTab(),
                    if (tabIndex == 1) _classesTab(),
                    if (tabIndex == 2) _workoutsTab(),
                    if (tabIndex == 3) _membersTab(),
                    if (tabIndex == 4) _plansTab(),
                    if (tabIndex == 5) const AdminNotificationsTab(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
