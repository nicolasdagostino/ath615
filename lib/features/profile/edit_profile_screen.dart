import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
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
    setState(() => _saving = true);
    try {
      final file = await _avatarRepo.pickImage();
      if (file == null) {
        if (mounted) setState(() => _saving = false);
        return;
      }

      final url = await _avatarRepo.uploadAvatar(file);
      if (url == null || url.trim().isEmpty) {
        throw Exception('Could not upload avatar');
      }

      await _reload();
      if (!mounted) return;
      _toast('Profile photo updated');
    } catch (e) {
      if (!mounted) return;
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
      if (parts.length >= 2)
        return (parts.first[0] + parts.last[0]).toUpperCase();
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
      throw Exception('No authenticated user');
    }

    final payload = <String, dynamic>{};

    if (values.containsKey('full_name')) {
      final fullName = _stringValue(values['full_name']);
      payload['full_name'] = fullName.isEmpty ? null : fullName;
    }

    if (values.containsKey('date_of_birth')) {
      payload['date_of_birth'] = values['date_of_birth'];
    }

    if (payload.isEmpty) return;

    await sb.from('profiles').update(payload).eq('id', user.id);
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
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

    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF6F7F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
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
                    title.toUpperCase(),
                    style: _font(
                      18,
                      weight: FontWeight.w800,
                      color: const Color(0xFF111318),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEAECEF)),
                    ),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: capitalizeWords
                          ? TextCapitalization.words
                          : TextCapitalization.none,
                      style: _font(
                        18,
                        weight: FontWeight.w600,
                        color: const Color(0xFF111318),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter $title',
                        hintStyle: _font(
                          16,
                          weight: FontWeight.w500,
                          color: const Color(0xFF98A2B3),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext, controller.text.trim());
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF111318),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'SAVE',
                        style: _font(
                          15,
                          weight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
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
      if (!mounted) return;
      _toast('$title updated');
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editBirthDate(DateTime? initialDate) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1920, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Select date of birth',
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
      if (!mounted) return;
      _toast('Date of birth updated');
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showChangePasswordSheet() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showModalBottomSheet<Map<String, String>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool obscure1 = true;
        bool obscure2 = true;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: SafeArea(
                top: false,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF6F7F9),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
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
                        'CHANGE PASSWORD',
                        style: _font(
                          18,
                          weight: FontWeight.w800,
                          color: const Color(0xFF111318),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFEAECEF)),
                        ),
                        child: TextField(
                          controller: passwordController,
                          obscureText: obscure1,
                          autofocus: true,
                          style: _font(
                            18,
                            weight: FontWeight.w600,
                            color: const Color(0xFF111318),
                          ),
                          decoration: InputDecoration(
                            hintText: 'New password',
                            hintStyle: _font(
                              16,
                              weight: FontWeight.w500,
                              color: const Color(0xFF98A2B3),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setModalState(() => obscure1 = !obscure1);
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
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFEAECEF)),
                        ),
                        child: TextField(
                          controller: confirmController,
                          obscureText: obscure2,
                          style: _font(
                            18,
                            weight: FontWeight.w600,
                            color: const Color(0xFF111318),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Confirm new password',
                            hintStyle: _font(
                              16,
                              weight: FontWeight.w500,
                              color: const Color(0xFF98A2B3),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setModalState(() => obscure2 = !obscure2);
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
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext, {
                              'password': passwordController.text,
                              'confirm': confirmController.text,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF111318),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'UPDATE PASSWORD',
                            style: _font(
                              15,
                              weight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
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
      _toast('Please complete both password fields');
      return;
    }
    if (password.length < 6) {
      _toast('Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      _toast('Passwords do not match');
      return;
    }

    setState(() => _saving = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      if (!mounted) return;
      _toast('Password updated');
    } catch (e) {
      if (!mounted) return;
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
                                      'ACCOUNT',
                                      style: _font(
                                        17,
                                        weight: FontWeight.w800,
                                        color: const Color(0xFF0E0E11),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'PROFILE',
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
                          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFA4A7B3),
                                      borderRadius: BorderRadius.circular(26),
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
                                            width: 96,
                                            height: 96,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, error, stackTrace) {
                                                  return Center(
                                                    child: Text(
                                                      initials,
                                                      style: _font(
                                                        34,
                                                        weight: FontWeight.w800,
                                                        color: Colors.white,
                                                        letterSpacing: -0.4,
                                                      ),
                                                    ),
                                                  );
                                                },
                                          )
                                        : Text(
                                            initials,
                                            style: _font(
                                              34,
                                              weight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: -0.4,
                                            ),
                                          ),
                                  ),
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFEAECEF),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: Color(0xFFB42318),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              GestureDetector(
                                onTap: _saving ? null : _pickAndUploadAvatar,
                                child: Text(
                                  _saving ? 'UPLOADING...' : 'UPLOAD NEW PHOTO',
                                  style: _font(
                                    14,
                                    weight: FontWeight.w700,
                                    color: const Color(0xFFB59B6A),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                email,
                                textAlign: TextAlign.center,
                                style: _font(
                                  14,
                                  weight: FontWeight.w500,
                                  color: const Color(0xFF98A2B3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SectionLabel('PERSONAL'),
                        const SizedBox(height: 6),
                        _SectionCard(
                          children: [
                            _AccountRow(
                              title: 'Full Name',
                              value: fullName,
                              onTap: waiting || _saving
                                  ? null
                                  : () => _editTextField(
                                      title: 'Full Name',
                                      fieldKey: 'full_name',
                                      initialValue: fullName,
                                    ),
                            ),
                            const _SectionDivider(),
                            _AccountRow(
                              title: 'Date of Birth',
                              value: birthDate,
                              onTap: waiting || _saving
                                  ? null
                                  : () => _editBirthDate(birthDateValue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _SectionLabel('SECURITY'),
                        const SizedBox(height: 6),
                        _SectionCard(
                          children: [
                            _AccountRow(
                              title: 'Change Password',
                              onTap: _saving ? null : _showChangePasswordSheet,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _SectionLabel('APP'),
                        const SizedBox(height: 6),
                        const _SectionCard(
                          children: [_AccountRow(title: 'Settings')],
                        ),
                        const SizedBox(height: 18),
                        _SectionLabel('DANGER ZONE'),
                        const SizedBox(height: 6),
                        const _SectionCard(
                          children: [
                            _AccountRow(
                              title: 'Delete Account',
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
  final String title;
  final String? value;
  final bool danger;
  final bool showChevron;
  final VoidCallback? onTap;

  const _AccountRow({
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
