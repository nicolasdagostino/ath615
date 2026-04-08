import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/supabase/owner_repository.dart';
import '../../core/supabase/auth_repository.dart';
import '../../core/auth/user_session.dart';
import '../../shared/widgets/app_toast.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  final _repo = OwnerRepository();
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _adminNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  bool _loading = false;
  late Future<List<Map<String, dynamic>>> _futureGyms;

  @override
  void initState() {
    super.initState();
    _futureGyms = _repo.listGymMetrics();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
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

  void _toast(String msg, {bool isError = false, IconData? icon}) {
    if (!mounted) return;
    AppToast.show(context, msg, isError: isError, icon: icon);
  }

  Future<void> _refresh() async {
    setState(() {
      _futureGyms = _repo.listGymMetrics();
    });
    await _futureGyms;
  }

  String _slugify(String input) {
    var value = input.trim().toLowerCase();
    value = value.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    value = value.replaceAll(RegExp(r'-+'), '-');
    value = value.replaceAll(RegExp(r'^-|-$'), '');
    return value;
  }

  Future<void> _showCreateGymModal() async {
    _nameCtrl.clear();
    _slugCtrl.clear();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> submit() async {
                final name = _nameCtrl.text.trim();
                final slug = _slugify(_slugCtrl.text.trim());

                if (name.isEmpty) {
                  _toast('Gym name is required');
                  return;
                }
                if (slug.isEmpty) {
                  _toast('Gym slug is required');
                  return;
                }

                setModalState(() => _loading = true);
                try {
                  await _repo.createGym(name: name, slug: slug);
                  if (!mounted) return;
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  _toast('Gym created successfully');
                  await _refresh();
                } catch (e) {
                  _toast(e.toString().replaceFirst('Exception: ', ''));
                } finally {
                  if (mounted) {
                    setModalState(() => _loading = false);
                  }
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create gym',
                    style: _font(
                      22,
                      weight: FontWeight.w800,
                      color: const Color(0xFF111318),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create a new gym tenant and turn this owner into its admin.',
                    style: _font(
                      13,
                      weight: FontWeight.w600,
                      color: const Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'GYM NAME',
                    style: _font(
                      12,
                      weight: FontWeight.w700,
                      color: const Color(0xFF98A2B3),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: _font(
                      16,
                      weight: FontWeight.w600,
                      color: const Color(0xFF111318),
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Athlete Lab Sitges',
                      hintStyle: _font(
                        15,
                        weight: FontWeight.w500,
                        color: const Color(0xFF98A2B3),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFB59B6A),
                          width: 1.4,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      final currentSlug = _slugCtrl.text.trim();
                      if (currentSlug.isEmpty ||
                          currentSlug == _slugify(_nameCtrl.text)) {
                        final next = _slugify(value);
                        _slugCtrl.value = TextEditingValue(
                          text: next,
                          selection: TextSelection.collapsed(offset: next.length),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'SLUG',
                    style: _font(
                      12,
                      weight: FontWeight.w700,
                      color: const Color(0xFF98A2B3),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _slugCtrl,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: _font(
                      16,
                      weight: FontWeight.w600,
                      color: const Color(0xFF111318),
                    ),
                    decoration: InputDecoration(
                      hintText: 'auto-generated',
                      hintStyle: _font(
                        15,
                        weight: FontWeight.w500,
                        color: const Color(0xFF98A2B3),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFB59B6A),
                          width: 1.4,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      final next = _slugify(value);
                      if (next != value) {
                        _slugCtrl.value = TextEditingValue(
                          text: next,
                          selection: TextSelection.collapsed(offset: next.length),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Used for URLs and internal identification.',
                    style: _font(
                      12,
                      weight: FontWeight.w500,
                      color: const Color(0xFF98A2B3),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111318),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _loading ? 'Creating...' : 'Create gym',
                        style: _font(
                          14,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }


  Future<void> _showInviteAdminModal(Map<String, dynamic> gym) async {
    _adminNameCtrl.clear();
    _adminEmailCtrl.clear();

    final gymId = (gym['id'] ?? '').toString().trim();
    final gymName = (gym['name'] ?? 'Gym').toString().trim();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> submit() async {
                final fullName = _adminNameCtrl.text.trim();
                final email = _adminEmailCtrl.text.trim().toLowerCase();

                if (gymId.isEmpty) {
                  _toast('Gym not found');
                  return;
                }
                if (fullName.isEmpty) {
                  _toast('Admin full name is required');
                  return;
                }
                if (email.isEmpty) {
                  _toast('Admin email is required');
                  return;
                }

                setModalState(() => _loading = true);
                try {
                  await _repo.inviteGymAdmin(
                    gymId: gymId,
                    fullName: fullName,
                    email: email,
                  );
                  if (!mounted) return;
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  _toast('Admin invitation sent');
                } catch (e) {
                  _toast(e.toString().replaceFirst('Exception: ', ''));
                } finally {
                  if (mounted) {
                    setModalState(() => _loading = false);
                  }
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite admin',
                    style: _font(
                      22,
                      weight: FontWeight.w800,
                      color: const Color(0xFF111318),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Send the first admin invitation for ${gymName.isEmpty ? 'this gym' : gymName}.',
                    style: _font(
                      13,
                      weight: FontWeight.w600,
                      color: const Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'ADMIN FULL NAME',
                    style: _font(
                      12,
                      weight: FontWeight.w700,
                      color: const Color(0xFF98A2B3),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _adminNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    style: _font(
                      16,
                      weight: FontWeight.w600,
                      color: const Color(0xFF111318),
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. John Doe',
                      hintStyle: _font(
                        15,
                        weight: FontWeight.w500,
                        color: const Color(0xFF98A2B3),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFB59B6A),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'ADMIN EMAIL',
                    style: _font(
                      12,
                      weight: FontWeight.w700,
                      color: const Color(0xFF98A2B3),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _adminEmailCtrl,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.emailAddress,
                    style: _font(
                      16,
                      weight: FontWeight.w600,
                      color: const Color(0xFF111318),
                    ),
                    decoration: InputDecoration(
                      hintText: 'admin@email.com',
                      hintStyle: _font(
                        15,
                        weight: FontWeight.w500,
                        color: const Color(0xFF98A2B3),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFB59B6A),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111318),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _loading ? 'Sending...' : 'Invite admin',
                        style: _font(
                          14,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }





  Future<void> _runGymAction(
    Map<String, dynamic> gym,
    String action, {
    String? reason,
    String? successMessage,
  }) async {
    final gymId = (gym['id'] ?? '').toString().trim();
    if (gymId.isEmpty) {
      _toast('Gym not found');
      return;
    }

    setState(() => _loading = true);
    try {
      await _repo.updateGymStatus(
        gymId: gymId,
        action: action,
        reason: reason,
      );
      _toast(successMessage ?? 'Gym updated');
      await _refresh();
    } catch (e) {
      _toast(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Widget> _gymActions(Map<String, dynamic> gym) {
    return [
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : () => _showGymActionsSheet(gym),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF111318),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            'Manage gym',
            style: _font(
              14,
              weight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _metricTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EBF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: _font(
              16,
              weight: FontWeight.w800,
              color: const Color(0xFF111318),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: _font(
              11,
              weight: FontWeight.w600,
              color: const Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _seedTestAthletes(Map<String, dynamic> gym) async {
    final gymId = (gym['id'] ?? '').toString().trim();
    if (gymId.isEmpty) {
      _toast('Gym not found', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await _repo.seedTestAthletes(gymId: gymId, count: 10);
      final created = result['created_count'] ?? 10;
      _toast('$created test athletes created');
      await _refresh();
    } catch (e) {
      _toast(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showGymActionsSheet(Map<String, dynamic> gym) {
    final gymName = (gym['name'] ?? 'Gym').toString().trim();
    final gymSlug = (gym['slug'] ?? '').toString().trim();
    final isActive = gym['is_active'] == true;
    final isBlocked = gym['is_blocked'] == true;

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
        final maxHeight = media.size.height * 0.82;

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
                                Icons.storefront_outlined,
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
                                    gymName.isEmpty ? 'Gym' : gymName,
                                    style: _font(
                                      18,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFF111318),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (gymSlug.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      gymSlug,
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
                        'OPERATIONS',
                        style: _font(
                          12,
                          weight: FontWeight.w700,
                          color: const Color(0xFF98A2B3),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      actionTile(
                        icon: Icons.person_add_alt_1_outlined,
                        title: 'Invite admin',
                        subtitle: 'Send the first admin invitation for this gym',
                        iconBg: const Color(0xFFF7F3EA),
                        iconColor: const Color(0xFFB59B6A),
                        onTap: _loading
                            ? null
                            : () {
                                Navigator.pop(context);
                                _showInviteAdminModal(gym);
                              },
                      ),
                      const SizedBox(height: 10),
                      actionTile(
                        icon: Icons.group_add_outlined,
                        title: 'Seed 10 athletes',
                        subtitle: 'Create 10 test athletes with a fixed password',
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF245BEB),
                        onTap: _loading
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await _seedTestAthletes(gym);
                              },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'STATUS',
                        style: _font(
                          12,
                          weight: FontWeight.w700,
                          color: const Color(0xFF98A2B3),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      actionTile(
                        icon: isActive
                            ? Icons.pause_circle_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        title: isActive ? 'Deactivate gym' : 'Activate gym',
                        subtitle: isActive
                            ? 'Disable active access for this gym'
                            : 'Restore access and mark this gym as active',
                        iconBg: isActive
                            ? const Color(0xFFFEE4E2)
                            : const Color(0xFFDDF5E5),
                        iconColor: isActive
                            ? const Color(0xFFE11D48)
                            : const Color(0xFF16A34A),
                        onTap: _loading
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await _runGymAction(
                                  gym,
                                  isActive ? 'deactivate' : 'activate',
                                  successMessage: isActive
                                      ? 'Gym deactivated'
                                      : 'Gym activated',
                                );
                              },
                      ),
                      const SizedBox(height: 10),
                      actionTile(
                        icon: isBlocked
                            ? Icons.lock_open_outlined
                            : Icons.block_outlined,
                        title: isBlocked ? 'Unblock gym' : 'Block gym',
                        subtitle: isBlocked
                            ? 'Allow this gym to use the platform again'
                            : 'Temporarily suspend access for this gym',
                        iconBg: const Color(0xFFFFFAEB),
                        iconColor: const Color(0xFFB54708),
                        onTap: _loading
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await _runGymAction(
                                  gym,
                                  isBlocked ? 'unblock' : 'block',
                                  successMessage: isBlocked
                                      ? 'Gym unblocked'
                                      : 'Gym blocked',
                                );
                              },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'DANGER ZONE',
                        style: _font(
                          12,
                          weight: FontWeight.w700,
                          color: const Color(0xFF98A2B3),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      actionTile(
                        icon: Icons.archive_outlined,
                        title: 'Archive gym',
                        subtitle: 'Hide this gym from normal active operations',
                        iconBg: const Color(0xFFF2F4F7),
                        iconColor: const Color(0xFF344054),
                        titleColor: const Color(0xFF344054),
                        onTap: _loading
                            ? null
                            : () async {
                                Navigator.pop(context);
                                await _runGymAction(
                                  gym,
                                  'archive',
                                  successMessage: 'Gym archived',
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

  Widget _statusChip(
    String label, {
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: _font(
          11,
          weight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  List<Widget> _gymStatusChips(Map<String, dynamic> gym) {
    final isActive = gym['is_active'] == true;
    final isBlocked = gym['is_blocked'] == true;
    final deletedAt = (gym['deleted_at'] ?? '').toString().trim();
    final isArchived = deletedAt.isNotEmpty;

    final chips = <Widget>[
      _statusChip(
        isActive ? 'ACTIVE' : 'INACTIVE',
        textColor: isActive ? const Color(0xFF067647) : const Color(0xFFB42318),
        backgroundColor: isActive
            ? const Color(0xFFECFDF3)
            : const Color(0xFFFEF3F2),
      ),
    ];

    if (isBlocked) {
      chips.add(
        _statusChip(
          'BLOCKED',
          textColor: const Color(0xFFB54708),
          backgroundColor: const Color(0xFFFFFAEB),
        ),
      );
    }

    if (isArchived) {
      chips.add(
        _statusChip(
          'ARCHIVED',
          textColor: const Color(0xFF344054),
          backgroundColor: const Color(0xFFF2F4F7),
        ),
      );
    }

    return chips;
  }

  Widget _gymCard(Map<String, dynamic> gym) {
    final name = (gym['name'] ?? 'Gym').toString().trim();
    final slug = (gym['slug'] ?? '').toString().trim();
    final blockedReason = (gym['blocked_reason'] ?? '').toString().trim();
    final statusChips = _gymStatusChips(gym);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EBF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? 'Gym' : name,
            style: _font(
              16,
              weight: FontWeight.w800,
              color: const Color(0xFF111318),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            slug.isEmpty ? '—' : slug,
            style: _font(
              13,
              weight: FontWeight.w600,
              color: const Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statusChips,
          ),
          if (blockedReason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Reason: $blockedReason',
              style: _font(
                12,
                weight: FontWeight.w600,
                color: const Color(0xFF667085),
              ),
            ),
          ],
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.3,
            children: [
              _metricTile(
                'Active members',
                '${gym['active_members'] ?? 0}',
              ),
              _metricTile(
                'Total members',
                '${gym['total_members'] ?? 0}',
              ),
              _metricTile(
                'Admins / coaches',
                '${gym['admins_coaches'] ?? 0}',
              ),
              _metricTile(
                'Classes this week',
                '${gym['classes_this_week'] ?? 0}',
              ),
              _metricTile(
                'Bookings this week',
                '${gym['bookings_this_week'] ?? 0}',
              ),
              _metricTile(
                'Created',
                ((gym['created_at'] ?? '').toString().length >= 10)
                    ? (gym['created_at'] ?? '').toString().substring(0, 10)
                    : '—',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._gymActions(gym),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: const Color(0xFF111318),
        title: Text(
          'Owner',
          style: _font(
            22,
            weight: FontWeight.w800,
            color: const Color(0xFF111318),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await AuthRepository().signOut();
              UserSession().clear();
              if (!mounted) return;
              navigator.pushNamedAndRemoveUntil('/login', (_) => false);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _futureGyms,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final gyms = snapshot.data ?? const <Map<String, dynamic>>[];

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE7EBF0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Platform onboarding',
                        style: _font(
                          18,
                          weight: FontWeight.w800,
                          color: const Color(0xFF111318),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create gyms and prepare the initial admin setup.',
                        style: _font(
                          13,
                          weight: FontWeight.w600,
                          color: const Color(0xFF667085),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showCreateGymModal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF111318),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Create gym',
                            style: _font(
                              14,
                              weight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Gyms',
                  style: _font(
                    16,
                    weight: FontWeight.w800,
                    color: const Color(0xFF111318),
                  ),
                ),
                const SizedBox(height: 8),
                if (gyms.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE7EBF0)),
                    ),
                    child: Text(
                      'No gyms created yet',
                      style: _font(
                        14,
                        weight: FontWeight.w600,
                        color: const Color(0xFF667085),
                      ),
                    ),
                  )
                else
                  ...gyms.map(_gymCard),
              ],
            );
          },
        ),
      ),
    );
  }
}
