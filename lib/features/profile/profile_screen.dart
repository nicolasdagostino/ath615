import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/locale/locale_controller.dart';
import '../../l10n/app_text.dart';

import '../../core/auth/user_session.dart';
import '../../core/constants/app_colors.dart';
import '../../core/supabase/achievement_repository.dart';
import '../../core/supabase/auth_repository.dart';
import '../../core/supabase/profile_repository.dart';
import '../../shared/widgets/app_card.dart';
import 'achievements_screen.dart';
import 'athlete_history/athlete_history_screen.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final profile = await ProfileRepository().getMyProfile();
    final stats = await AchievementRepository().myStats();
    return {'profile': profile, 'stats': stats};
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  Future<void> _logout() async {
    try {
      await AuthRepository().signOut();
    } catch (_) {}
    UserSession().clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<void> _showLanguageSheet() async {
    final t = context.appText;
    final controller = LocaleController.instance;
    final currentCode = controller.languageCode;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
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
                  const SizedBox(height: 18),
                  Text(
                    t.chooseLanguage,
                    style: _font(
                      24,
                      weight: FontWeight.w800,
                      color: const Color(0xFF111318),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.appLanguage,
                    style: _font(
                      13,
                      weight: FontWeight.w500,
                      color: const Color(0xFF8F96A3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () async {
                            await controller.setLanguageCode('en');
                            if (!sheetContext.mounted) return;
                            Navigator.of(sheetContext).pop();
                            if (mounted) setState(() {});
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t.english,
                                    style: _font(
                                      16,
                                      weight: FontWeight.w700,
                                      color: const Color(0xFF111318),
                                    ),
                                  ),
                                ),
                                if (currentCode == 'en')
                                  const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const _SoftDivider(),
                        InkWell(
                          onTap: () async {
                            await controller.setLanguageCode('es');
                            if (!sheetContext.mounted) return;
                            Navigator.of(sheetContext).pop();
                            if (mounted) setState(() {});
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t.spanish,
                                    style: _font(
                                      16,
                                      weight: FontWeight.w700,
                                      color: const Color(0xFF111318),
                                    ),
                                  ),
                                ),
                                if (currentCode == 'es')
                                  const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.primary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
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
    final t = context.appText;
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.profileUpper,
                      style: _font(
                        17,
                        weight: FontWeight.w800,
                        color: const Color(0xFF0E0E11),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.accountUpper,
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
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: 132,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _TopSquareButton(
                      icon: Icons.notifications_none_rounded,
                      badge: '2',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
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

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: _font(
        11,
        weight: FontWeight.w700,
        color: const Color(0xFF98A2B3),
        letterSpacing: 1.1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appText;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          final waiting = snapshot.connectionState == ConnectionState.waiting;
          final data = snapshot.data ?? <String, dynamic>{};
          final profile =
              (data['profile'] as Map<String, dynamic>?) ?? <String, dynamic>{};
          final stats =
              (data['stats'] as Map<String, dynamic>?) ?? <String, dynamic>{};

          final fullName =
              (profile['full_name'] ?? '').toString().trim().isEmpty
              ? (waiting ? '' : t.athlete)
              : profile['full_name'].toString().trim();

          final email = (profile['email'] ?? '').toString().trim().isEmpty
              ? '-'
              : profile['email'].toString().trim();

          final initials = _initialsFromName(
            fullName.isEmpty ? t.athlete : fullName,
          );
          final avatarUrl = (profile['avatar_url'] ?? '').toString().trim();
          final avatarDisplayUrl = avatarUrl.isEmpty
              ? ''
              : '$avatarUrl${avatarUrl.contains('?') ? '&' : '?'}v=${DateTime.now().millisecondsSinceEpoch}';

          final totalClasses = (stats['classes_count'] ?? 0).toString();
          final recordsCount = (stats['prs_count'] ?? 0).toString();
          final strengthCount = (stats['strength_count'] ?? 0).toString();
          final milestonesCount = (stats['milestones_count'] ?? 0).toString();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refreshProfile,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _topHeader(),
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
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                color: const Color(0xFFB0B4BF),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              clipBehavior: Clip.antiAlias,
                              alignment: Alignment.center,
                              child: avatarDisplayUrl.isNotEmpty
                                  ? Image.network(
                                      avatarDisplayUrl,
                                      width: 108,
                                      height: 108,
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
                            const SizedBox(height: 18),
                            Text(
                              fullName.toUpperCase(),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _font(
                                26,
                                weight: FontWeight.w800,
                                color: const Color(0xFF0E0E11),
                                letterSpacing: -0.3,
                                height: 0.96,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              email,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _font(
                                14,
                                weight: FontWeight.w500,
                                color: const Color(0xFF98A2B3),
                                letterSpacing: 0.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      _sectionLabel(t.profile),
                      const SizedBox(height: 6),
                      _ProfilePrimaryCard(
                        children: [
                          _PrimaryActionRow(
                            title: t.account,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );
                            },
                          ),
                          const _SoftDivider(),
                          _PrimaryActionRow(
                            title:
                                '${t.language} · ${LocaleController.instance.isSpanish ? t.spanish : t.english}',
                            onTap: _showLanguageSheet,
                          ),
                          const _SoftDivider(),
                          _PrimaryActionRow(
                            title: t.records,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AchievementsScreen(),
                                ),
                              );
                            },
                          ),
                          const _SoftDivider(),
                          _PrimaryActionRow(
                            title: t.classHistory,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AthleteHistoryScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _sectionLabel(t.yourStats),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              value: totalClasses,
                              label: t.classes,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              value: recordsCount,
                              label: t.records,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              value: strengthCount,
                              label: t.strength,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              value: milestonesCount,
                              label: t.milestones,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _sectionLabel(t.more),
                      const SizedBox(height: 6),
                      _ProfilePrimaryCard(
                        children: [
                          _PrimaryActionRow(
                            title: t.helpCenter,
                            compact: false,
                          ),
                          _SoftDivider(),
                          _PrimaryActionRow(
                            title: t.privacyPolicy,
                            compact: false,
                          ),
                          _SoftDivider(),
                          _PrimaryActionRow(
                            title: t.termsOfService,
                            compact: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _ProfilePrimaryCard(
                        children: [
                          _PrimaryActionRow(
                            title: t.logOut,
                            danger: true,
                            compact: false,
                            showChevron: false,
                            onTap: _logout,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopSquareButton extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;

  const _TopSquareButton({required this.icon, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8EBF0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D0D1210),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF111318), size: 24),
          ),
          if (badge != null)
            Positioned(
              right: -3,
              top: -4,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFB59B6A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge!,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfilePrimaryCard extends StatelessWidget {
  final List<Widget> children;

  const _ProfilePrimaryCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(children: children),
    );
  }
}

class _PrimaryActionRow extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool danger;
  final bool compact;
  final bool showChevron;

  const _PrimaryActionRow({
    required this.title,
    this.onTap,
    this.danger = false,
    this.compact = false,
    this.showChevron = true,
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
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 10 : 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _font(
                      compact ? 15 : 15,
                      weight: FontWeight.w800,
                      color: titleColor,
                      letterSpacing: 0.0,
                      height: 0.98,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron) ...[
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: danger
                    ? const Color(0xFFCC6B5A)
                    : const Color(0xFF98A2B3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;

  const _StatTile({required this.value, required this.label});

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
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: _font(
              28,
              weight: FontWeight.w800,
              color: const Color(0xFF0E0E11),
              height: 0.96,
              letterSpacing: -0.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: _font(
              13,
              weight: FontWeight.w600,
              color: const Color(0xFF667085),
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFFEFF1F4), thickness: 1);
  }
}
