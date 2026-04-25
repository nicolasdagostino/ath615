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
import '../../core/supabase/auth_repository.dart';
import '../../core/supabase/gym_repository.dart';
import '../../core/supabase/membership_repository.dart';
import '../../core/supabase/profile_repository.dart';
import '../../core/supabase/storage_repository.dart';
import '../../features/notifications/admin_notifications_tab.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/input_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/secondary_button.dart';
import '../../shared/widgets/app_toast.dart';
part 'admin_plan_actions.dart';
part 'admin_plan_modal.dart';
part 'admin_gym_modal.dart';
part 'admin_screen_shell.dart';

part 'admin_plans_tab.dart';

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
  final _profileRepo = ProfileRepository();
  final _classRepo = ClassRepository();
  final _gymRepo = GymRepository();
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
  String _adminGymName = '';
  String _adminGymLogoUrl = '';

  List<Map<String, dynamic>> _plans = [];
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _classes = [];
  final Map<String, Map<String, dynamic>?> _memberActiveMembership = {};

  final tabs = const ['Plans', 'Notifications'];
  late final List<GlobalKey> _tabChipKeys;

  AppStrings get t => context.appText;

  bool get _isSpanish => Localizations.localeOf(
    context,
  ).languageCode.toLowerCase().startsWith('es');

  String _formatShortDate(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty || raw == 'null') return '';
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return raw;
    return DateFormat('dd-MM-yyyy').format(parsed);
  }

  String _uiText(String es, String en) => _isSpanish ? es : en;

  String _adminTabLabel(String raw) {
    switch (raw) {
      case 'Programs':
        return _uiText('Programas', 'Programs');
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
        } else {}
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
    final brandName = _adminGymName.trim().isEmpty
        ? 'ATHLETE LAB'
        : _adminGymName.trim().toUpperCase();

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
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 132,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brandName,
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
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _adminActionBusy ? null : _showGymModal,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String message, {bool isError = false, IconData? icon}) {
    AppToast.show(context, message, isError: isError, icon: icon);
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
                                    Localizations.localeOf(
                                      context,
                                    ).toLanguageTag(),
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
      final gymInfo = await _gymRepo.myGymInfo();
      _adminGymName = (gymInfo?['name'] ?? '').toString().trim();
      _adminGymLogoUrl = (gymInfo?['logo_url'] ?? '').toString().trim();

      try {
        _plans = await _membershipRepo.listPlans(_adminGymId!);
      } catch (_) {
        _plans = [];
      }

      try {
        _members = [];
      } catch (_) {
        _members = [];
      }

      try {
        _classes = await _classRepo.listClassesAdmin(_adminGymId!);
      } catch (_) {
        _classes = [];
      }

      // removed memberActiveMembership logic

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
      billingPeriod: type.trim() == 'drop_in'
          ? 'one_time'
          : type.trim() == 'class_pack'
          ? 'monthly'
          : 'monthly',
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
      billingPeriod: type.trim() == 'drop_in'
          ? 'one_time'
          : type.trim() == 'class_pack'
          ? 'monthly'
          : 'monthly',
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

  Future<void> _deleteClass(String id) async {
    await _classRepo.deleteClass(gymId: _adminGymId!, id: id);
  }

  Future<int> _deleteFutureClassesForProgramSlot(String classId) async {
    return _classRepo.deleteFutureClassesForProgramSlot(classId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Column(children: [_topHeader(), _adminBody()]));
  }

  void _setAdminTab(int i) {
    setState(() => tabIndex = i);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToActiveTab();
    });
  }
}
