import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../l10n/app_text.dart';
import '../../core/supabase/avatar_repository.dart';
import '../../core/supabase/profile_repository.dart';
import '../../shared/widgets/app_card.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late Future<Map<String, dynamic>?> _future;
  final _avatarRepo = AvatarRepository();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = ProfileRepository().getMyProfile();
  }

  Future<void> _reload() async {
    setState(() {
      _future = ProfileRepository().getMyProfile();
    });
    await _future;
  }

  Future<void> _pickAndUploadAvatar() async {
    final t = context.appText;
    setState(() => _saving = true);
    try {
      final file = await _avatarRepo.pickImage();
      if (file == null) {
        if (mounted) setState(() => _saving = false);
        return;
      }

      final url = await _avatarRepo.uploadAvatar(file);
      if (url == null || url.trim().isEmpty) {
        throw Exception(t.couldNotUploadAvatar);
      }

      await _reload();
      if (!mounted) {
        return;
      }
      _toast(t.profilePhotoUpdated);
    } catch (e) {
      if (!mounted) {
        return;
      }
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

  String _stringValue(dynamic value) {
    return (value ?? '').toString().trim();
  }

  String _displayOrDash(dynamic value) {
    final text = _stringValue(value);
    return text.isEmpty ? '-' : text;
  }

  String _fullName(Map<String, dynamic> profile) {
    final fullName = _stringValue(profile['full_name']);
    return fullName.isEmpty ? '-' : fullName;
  }

  String _initials(Map<String, dynamic> profile) {
    final fullName = _stringValue(profile['full_name']);
    if (fullName.isNotEmpty) {
      final parts = fullName
          .split(RegExp(r'\s+'))
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.length == 1) return parts.first[0].toUpperCase();
      if (parts.length >= 2) {
        return (parts.first[0] + parts.last[0]).toUpperCase();
      }
    }
    return 'A';
  }

  String _birthDate(Map<String, dynamic> profile) {
    final raw = _stringValue(
      profile['date_of_birth'] ?? profile['birth_date'] ?? profile['dob'],
    );

    if (raw.isEmpty) return '-';

    final dt = DateTime.tryParse(raw);
    if (dt != null) {
      return DateFormat('d MMMM yyyy').format(dt.toLocal());
    }

    return raw;
  }

  String _gymName(Map<String, dynamic> profile) {
    final direct = _stringValue(profile['gym_name']);
    if (direct.isNotEmpty) return direct;

    final gym = profile['gyms'];
    if (gym is Map<String, dynamic>) {
      return _stringValue(gym['name']);
    }
    if (gym is Map) {
      return _stringValue(gym['name']);
    }
    return '';
  }

  DateTime? _birthDateValue(Map<String, dynamic> profile) {
    final raw = _stringValue(
      profile['date_of_birth'] ?? profile['birth_date'] ?? profile['dob'],
    );
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _saveProfileFields(Map<String, dynamic> values) async {
    final sb = Supabase.instance.client;
    final user = sb.auth.currentUser;
    if (user == null) {
      throw Exception(context.appText.noAuthenticatedUser);
    }

    final payload = <String, dynamic>{};

    if (values.containsKey('full_name')) {
      final fullName = _stringValue(values['full_name']);
      payload['full_name'] = fullName.isEmpty ? null : fullName;
    }

    if (values.containsKey('date_of_birth')) {
      payload['date_of_birth'] = values['date_of_birth'];
    }

    if (values.containsKey('phone')) {
      final phone = _stringValue(values['phone']);
      payload['phone'] = phone.isEmpty ? null : phone;
    }

    if (payload.isEmpty) return;

    await sb.from('profiles').update(payload).eq('id', user.id);
  }

  void _toast(String message, {bool isError = false}) {
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

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFD7DBE1),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _sheetHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onClose,
  }) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F3EA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFFB59B6A), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: _font(
                  24,
                  weight: FontWeight.w800,
                  color: const Color(0xFF111318),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
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
          onTap: onClose,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EBF0)),
            ),
            child: const Icon(
              Icons.close_rounded,
              size: 22,
              color: Color(0xFF111318),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _sheetInputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: _font(
        13,
        weight: FontWeight.w500,
        color: const Color(0xFF9AA3AF),
      ),
      filled: true,
      fillColor: const Color(0xFFFCFDFE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFB59B6A), width: 1.2),
      ),
    );
  }

  Widget _sheetSectionTitle(String text) {
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

  Widget _sheetPrimaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFB59B6A),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          text,
          style: _font(
            16,
            weight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.15,
          ),
        ),
      ),
    );
  }

  Future<void> _editTextField({
    required String title,
    required String fieldKey,
    required String initialValue,
    bool capitalizeWords = true,
  }) async {
    final controller = TextEditingController(
      text: initialValue == '-' ? '' : initialValue,
    );
    final scrollCtrl = ScrollController();
    final focusNode = FocusNode();

    focusNode.addListener(() {
      if (focusNode.hasFocus && scrollCtrl.hasClients) {
        Future.delayed(const Duration(milliseconds: 180), () {
          if (!scrollCtrl.hasClients) return;
          scrollCtrl.animateTo(
            scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
          );
        });
      }
    });

    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(top: 36, bottom: bottomInset),
          child: SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF7F8FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(sheetContext).unfocus(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(bottom: bottomInset + 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetHandle(),
                        const SizedBox(height: 16),
                        _sheetHeader(
                          icon: Icons.person_outline_rounded,
                          title: title,
                          subtitle: context.appText.updateAccountInformation,
                          onClose: () => Navigator.pop(sheetContext),
                        ),
                        const SizedBox(height: 18),
                        _sheetSectionTitle(context.appText.details),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE8ECF1)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x080D1210),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            autofocus: true,
                            onTapOutside: (_) =>
                                FocusScope.of(sheetContext).unfocus(),
                            textCapitalization: capitalizeWords
                                ? TextCapitalization.words
                                : TextCapitalization.none,
                            keyboardType: fieldKey == 'phone'
                                ? TextInputType.phone
                                : TextInputType.text,
                            style: _font(
                              14,
                              weight: FontWeight.w600,
                              color: const Color(0xFF111318),
                            ),
                            decoration: _sheetInputDecoration(
                              hintText: context.appText.enterField(title),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _sheetPrimaryButton(
                          text: context.appText.saveChanges,
                          onPressed: () {
                            Navigator.pop(sheetContext, controller.text.trim());
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (value == null) return;

    setState(() => _saving = true);
    try {
      await _saveProfileFields({fieldKey: value});
      await _reload();
      if (!mounted) {
        return;
      }
      _toast(context.appText.fieldUpdated(title));
    } catch (e) {
      if (!mounted) {
        return;
      }
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editBirthDate(DateTime? initialDate) async {
    final now = DateTime.now();
    DateTime selectedDate = initialDate ?? DateTime(1990, 1, 1);

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7F8FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sheetHandle(),
                      const SizedBox(height: 16),
                      _sheetHeader(
                        icon: Icons.event_rounded,
                        title: context.appText.dateOfBirth,
                        subtitle: context.appText.chooseBirthDate,
                        onClose: () => Navigator.pop(sheetContext),
                      ),
                      const SizedBox(height: 18),
                      _sheetSectionTitle(context.appText.selectDate),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFEAECEF)),
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
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.date,
                                  initialDateTime: selectedDate,
                                  minimumDate: DateTime(1920, 1, 1),
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
                              DateFormat('d MMMM yyyy').format(selectedDate),
                              style: _font(
                                13,
                                weight: FontWeight.w600,
                                color: const Color(0xFF667085),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sheetPrimaryButton(
                        text: context.appText.saveChanges,
                        onPressed: () =>
                            Navigator.pop(sheetContext, selectedDate),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    if (picked == null) return;

    setState(() => _saving = true);
    try {
      await _saveProfileFields({
        'date_of_birth': DateTime(
          picked.year,
          picked.month,
          picked.day,
        ).toIso8601String().split('T').first,
      });
      await _reload();
      if (!mounted) {
        return;
      }
      _toast(context.appText.dateOfBirthUpdated);
    } catch (e) {
      if (!mounted) {
        return;
      }
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showChangePasswordSheet() async {
    final t = context.appText;
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showModalBottomSheet<Map<String, String>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool obscure1 = true;
        bool obscure2 = true;
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(top: 36, bottom: bottomInset),
              child: SafeArea(
                top: false,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => FocusScope.of(sheetContext).unfocus(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.only(bottom: bottomInset + 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sheetHandle(),
                            const SizedBox(height: 16),
                            _sheetHeader(
                              icon: Icons.lock_outline_rounded,
                              title: context.appText.changePassword,
                              subtitle: context.appText.setNewPasswordSubtitle,
                              onClose: () => Navigator.pop(sheetContext),
                            ),
                            const SizedBox(height: 18),
                            _sheetSectionTitle(context.appText.security),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFFEAECEF),
                                ),
                              ),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: passwordController,
                                    obscureText: obscure1,
                                    autofocus: true,
                                    onTapOutside: (_) =>
                                        FocusScope.of(sheetContext).unfocus(),
                                    style: _font(
                                      13,
                                      weight: FontWeight.w500,
                                      color: const Color(0xFF111318),
                                    ),
                                    decoration: _sheetInputDecoration(
                                      hintText: context.appText.newPassword,
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setModalState(
                                            () => obscure1 = !obscure1,
                                          );
                                        },
                                        icon: Icon(
                                          obscure1
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: const Color(0xFF98A2B3),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: confirmController,
                                    obscureText: obscure2,
                                    onTapOutside: (_) =>
                                        FocusScope.of(sheetContext).unfocus(),
                                    style: _font(
                                      13,
                                      weight: FontWeight.w500,
                                      color: const Color(0xFF111318),
                                    ),
                                    decoration: _sheetInputDecoration(
                                      hintText: context.appText.confirmNewPassword,
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setModalState(
                                            () => obscure2 = !obscure2,
                                          );
                                        },
                                        icon: Icon(
                                          obscure2
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: const Color(0xFF98A2B3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _sheetPrimaryButton(
                              text: context.appText.updatePassword,
                              onPressed: () {
                                Navigator.pop(sheetContext, {
                                  'password': passwordController.text,
                                  'confirm': confirmController.text,
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) return;

    final password = (result['password'] ?? '').trim();
    final confirm = (result['confirm'] ?? '').trim();

    if (password.isEmpty || confirm.isEmpty) {
      _toast(t.completeBothPasswordFields);
      return;
    }
    if (password.length < 6) {
      _toast(t.passwordMinLength);
      return;
    }
    if (password != confirm) {
      _toast(t.passwordsDoNotMatch);
      return;
    }

    setState(() => _saving = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      if (!mounted) {
        return;
      }
      _toast(t.passwordUpdated);
    } catch (e) {
      if (!mounted) {
        return;
      }
      _toast(
        e
            .toString()
            .replaceFirst('AuthException: ', '')
            .replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appText;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _future,
            builder: (context, snapshot) {
              final waiting =
                  snapshot.connectionState == ConnectionState.waiting;
              final profile = snapshot.data ?? <String, dynamic>{};

              final initials = _initials(profile);
              final email = waiting ? '' : _displayOrDash(profile['email']);
              final fullName = waiting ? '' : _fullName(profile);
              final phone = waiting ? '' : _displayOrDash(profile['phone']);
              final gymName = waiting ? '' : _gymName(profile);
              final birthDate = waiting ? '' : _birthDate(profile);
              final birthDateValue = waiting ? null : _birthDateValue(profile);
              final avatarUrl = waiting
                  ? ''
                  : _stringValue(profile['avatar_url']);
              final avatarDisplayUrl = avatarUrl.isEmpty
                  ? ''
                  : '$avatarUrl${avatarUrl.contains('?') ? '&' : '?'}v=${DateTime.now().millisecondsSinceEpoch}';

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    color: Colors.white,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
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
                                    child: GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: const Icon(
                                        Icons.arrow_back_rounded,
                                        size: 28,
                                        color: Color(0xFFB59B6A),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      t.accountUpper,
                                      style: _font(
                                        17,
                                        weight: FontWeight.w800,
                                        color: const Color(0xFF0E0E11),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      t.edit,
                                      style: _font(
                                        11,
                                        weight: FontWeight.w500,
                                        color: const Color(0xFF8F96A3),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppCard(
                          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                          child: Column(
                            children: [
                              Container(
                                width: 118,
                                height: 118,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBF5),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: const Color(0xFFE7D7B0),
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA4A7B3),
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  alignment: Alignment.center,
                                  child: waiting
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : avatarDisplayUrl.isNotEmpty
                                      ? Image.network(
                                          avatarDisplayUrl,
                                          width: 110,
                                          height: 110,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, error, stackTrace) {
                                            return Center(
                                              child: Text(
                                                initials,
                                                style: _font(
                                                  38,
                                                  weight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : Text(
                                          initials,
                                          style: _font(
                                            38,
                                            weight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (gymName.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F3EA),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    gymName.toUpperCase(),
                                    style: _font(
                                      11,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFF8A6F3E),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              if (gymName.isNotEmpty) const SizedBox(height: 14),
                              Text(
                                fullName == '-' ? t.athlete.toUpperCase() : fullName.toUpperCase(),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: _font(
                                  28,
                                  weight: FontWeight.w800,
                                  color: const Color(0xFF0E0E11),
                                  letterSpacing: -0.35,
                                  height: 0.96,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: _saving ? null : _pickAndUploadAvatar,
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F3EA),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFE7D7B0),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _saving
                                        ? t.uploadingUpper
                                        : t.uploadNewPhotoUpper,
                                    style: _font(
                                      14,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFF8A6F3E),
                                      letterSpacing: -0.05,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const SizedBox(height: 18),
                        _SectionLabel(t.personalUpper),
                        const SizedBox(height: 6),
                        _SectionCard(
                          children: [
                            _AccountRow(
                              icon: Icons.badge_outlined,
                              title: t.fullName,
                              value: fullName,
                              onTap: waiting || _saving
                                  ? null
                                  : () => _editTextField(
                                      title: t.fullName,
                                      fieldKey: 'full_name',
                                      initialValue: fullName,
                                    ),
                            ),
                            const _SectionDivider(),
                            _AccountRow(
                              icon: Icons.call_outlined,
                              title: context.appText.phone,
                              value: phone,
                              onTap: waiting || _saving
                                  ? null
                                  : () => _editTextField(
                                      title: context.appText.phone,
                                      fieldKey: 'phone',
                                      initialValue: phone,
                                      capitalizeWords: false,
                                    ),
                            ),
                            const _SectionDivider(),
                            _AccountRow(
                              icon: Icons.event_rounded,
                              title: context.appText.dateOfBirth,
                              value: birthDate,
                              onTap: waiting || _saving
                                  ? null
                                  : () => _editBirthDate(birthDateValue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _SectionLabel(t.securityUpper),
                        const SizedBox(height: 6),
                        _SectionCard(
                          children: [
                            _AccountRow(
                              icon: Icons.lock_outline_rounded,
                              title: context.appText.changePassword,
                              onTap: _saving ? null : _showChangePasswordSheet,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const SizedBox(height: 18),
                        _SectionLabel(t.dangerZoneUpper),
                        const SizedBox(height: 6),
                        _SectionCard(
                          children: [
                            _AccountRow(
                              icon: Icons.delete_outline_rounded,
                              title: t.deleteAccount,
                              danger: true,
                              showChevron: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          if (_saving)
            IgnorePointer(
              child: Container(
                color: const Color(0x22000000),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

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

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _font(
        11,
        weight: FontWeight.w700,
        color: const Color(0xFF98A2B3),
        letterSpacing: 1.0,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(children: children),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? value;
  final bool danger;
  final bool showChevron;
  final VoidCallback? onTap;

  const _AccountRow({
    this.icon,
    required this.title,
    this.value,
    this.danger = false,
    this.showChevron = true,
    this.onTap,
  });

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

  @override
  Widget build(BuildContext context) {
    final titleColor = danger
        ? const Color(0xFFB42318)
        : const Color(0xFF111318);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: danger
                      ? const Color(0xFFFFF1F0)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: danger
                        ? const Color(0xFFF3C7C2)
                        : const Color(0xFFE7EBF0),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: danger
                      ? const Color(0xFFB42318)
                      : const Color(0xFF667085),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: _font(
                  15,
                  weight: FontWeight.w700,
                  color: titleColor,
                  letterSpacing: 0.0,
                ),
              ),
            ),
            if (value != null) ...[
              Flexible(
                child: Text(
                  value!,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: _font(
                    15,
                    weight: FontWeight.w500,
                    color: const Color(0xFF98A2B3),
                  ),
                ),
              ),
              if (showChevron) const SizedBox(width: 8),
            ],
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: danger
                    ? const Color(0xFFB42318)
                    : const Color(0xFFB0B7C3),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFEAECEF));
  }
}
