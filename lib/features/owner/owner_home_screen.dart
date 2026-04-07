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

  bool _loading = false;
  late Future<List<Map<String, dynamic>>> _futureGyms;

  @override
  void initState() {
    super.initState();
    _futureGyms = _repo.listGyms();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
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
      _futureGyms = _repo.listGyms();
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
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Gym name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final currentSlug = _slugCtrl.text.trim();
                      if (currentSlug.isEmpty) {
                        _slugCtrl.text = _slugify(value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _slugCtrl,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Slug',
                      hintText: 'crossfit-sitges',
                      border: OutlineInputBorder(),
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
                  TextField(
                    controller: _adminNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Admin full name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _adminEmailCtrl,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Admin email',
                      border: OutlineInputBorder(),
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

  Widget _gymCard(Map<String, dynamic> gym) {
    final name = (gym['name'] ?? 'Gym').toString().trim();
    final slug = (gym['slug'] ?? '').toString().trim();

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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showInviteAdminModal(gym),
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
                'Invite admin',
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
