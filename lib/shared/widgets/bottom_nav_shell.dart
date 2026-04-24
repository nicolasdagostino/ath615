import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/admin/admin_screen.dart';
import '../../features/booking/booking_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/explore/explore_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/workouts/workouts_screen.dart';
import '../../features/owner/owner_home_screen.dart';
import '../../l10n/app_text.dart';

class BottomNavShell extends StatefulWidget {
  final int initialIndex;

  const BottomNavShell({super.key, this.initialIndex = 1});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  late int index;
  final _sb = Supabase.instance.client;

  late Future<String> _roleFuture;

  String? _resolvedRole;
  String? _cachedLanguageCode;
  List<Widget>? _cachedScreens;
  List<_NavItemData>? _cachedItems;
  int _bookingScreenSeed = 0;
  int _adminInitialTabIndex = 0;
  String? _adminInitialMemberId;
  String? _adminInitialClassId;
  bool _adminOpenAssignWorkout = false;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    _roleFuture = _resolveRole();
  }

  Future<String> _resolveRole() async {
    final user = _sb.auth.currentUser;
    if (user == null) return 'athlete';

    try {
      final byId = await _sb
          .from('profiles')
          .select('role, email')
          .eq('id', user.id)
          .maybeSingle();

      if (byId != null) {
        final role = (byId['role'] ?? '').toString().toLowerCase().trim();
        debugPrint('BOTTOM_NAV byId role=$role email=${byId['email']}');
        if (role.isNotEmpty) return role;
      }

      if ((user.email ?? '').trim().isNotEmpty) {
        final byEmail = await _sb
            .from('profiles')
            .select('role, email')
            .eq('email', user.email!.trim())
            .maybeSingle();

        if (byEmail != null) {
          final role = (byEmail['role'] ?? '').toString().toLowerCase().trim();
          debugPrint('BOTTOM_NAV byEmail role=$role email=${byEmail['email']}');
          if (role.isNotEmpty) return role;
        }
      }
    } catch (e) {
      debugPrint('BOTTOM_NAV _resolveRole error: $e');
    }

    return 'athlete';
  }

  bool _canSeeDashboard(String role) => role == 'admin' || role == 'coach';

  bool _canSeeAdmin(String role) => role == 'admin';

  void _goToAdminTab({
    int initialTabIndex = 0,
    String? initialMemberId,
    String? initialClassId,
    bool openAssignWorkout = false,
  }) {
    final items = _cachedItems;
    if (items == null) return;

    final adminIndex = items.indexWhere(
      (item) => item.icon == Icons.admin_panel_settings_outlined,
    );
    if (adminIndex < 0) return;

    setState(() {
      _adminInitialTabIndex = initialTabIndex;
      _adminInitialMemberId = initialMemberId;
      _adminInitialClassId = initialClassId;
      _adminOpenAssignWorkout = openAssignWorkout;
      _cachedScreens = _screens(_resolvedRole ?? 'athlete');
      index = adminIndex;
    });
  }

  List<Widget> _screens(String role) {
    final base = <Widget>[
      const WorkoutsScreen(),
      BookingScreen(key: ValueKey('booking_$_bookingScreenSeed')),
      const ExploreScreen(),
    ];

    if (_canSeeDashboard(role)) {
      base.add(
        DashboardScreen(
          onOpenAdminMembers: () => _goToAdminTab(initialTabIndex: 0),
          onOpenAdminMemberDetail: (memberId) =>
              _goToAdminTab(initialTabIndex: 0, initialMemberId: memberId),
          onOpenAdminClassDetail: (classId, openAssignWorkout) => _goToAdminTab(
            initialTabIndex: 0,
            initialClassId: classId,
            openAssignWorkout: openAssignWorkout,
          ),
        ),
      );
      if (_canSeeAdmin(role)) {
        base.add(
          AdminScreen(
            key: ValueKey(
              'admin_${_adminInitialTabIndex}_${_adminInitialMemberId ?? ''}_${_adminInitialClassId ?? ''}_${_adminOpenAssignWorkout ? 'assign' : 'actions'}',
            ),
            initialTabIndex: _adminInitialTabIndex,
            initialMemberId: _adminInitialMemberId,
            initialClassId: _adminInitialClassId,
            initialOpenAssignWorkout: _adminOpenAssignWorkout,
          ),
        );
      }
    }

    base.add(const ProfileScreen());
    return base;
  }

  List<_NavItemData> _items(String role) {
    final t = context.appText;

    final base = <_NavItemData>[
      _NavItemData(
        icon: Icons.fitness_center_outlined,
        activeIcon: Icons.fitness_center,
        label: t.navWorkouts,
      ),
      _NavItemData(
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        label: t.navBooking,
      ),
      _NavItemData(
        icon: Icons.search_outlined,
        activeIcon: Icons.search,
        label: t.navExplore,
      ),
    ];

    if (_canSeeDashboard(role)) {
      base.add(
        _NavItemData(
          icon: Icons.space_dashboard_outlined,
          activeIcon: Icons.space_dashboard,
          label: t.navDashboard,
        ),
      );
      if (_canSeeAdmin(role)) {
        base.add(
          _NavItemData(
            icon: Icons.admin_panel_settings_outlined,
            activeIcon: Icons.admin_panel_settings,
            label: t.navAdmin,
          ),
        );
      }
    }

    base.add(
      _NavItemData(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: t.navProfile,
      ),
    );

    return base;
  }

  void _ensureCache(String role) {
    final languageCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();

    if (_resolvedRole == role &&
        _cachedLanguageCode == languageCode &&
        _cachedScreens != null &&
        _cachedItems != null) {
      return;
    }

    _resolvedRole = role;
    _cachedLanguageCode = languageCode;
    _cachedScreens = _screens(role);
    _cachedItems = _items(role);

    if (index >= _cachedScreens!.length) {
      index = _cachedScreens!.length - 1;
    }
  }

  TextStyle _labelStyle({required bool selected}) {
    return GoogleFonts.barlowCondensed(
      fontSize: 11.5,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      color: selected ? const Color(0xFF111318) : const Color(0xFF8F96A3),
      letterSpacing: 0.1,
      height: 1.0,
    );
  }

  Widget _navItem({
    required _NavItemData item,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: _PressableNavItem(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.0 : 1.0,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                child: Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 24,
                  color: selected
                      ? const Color(0xFF111318)
                      : const Color(0xFF8F96A3),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _labelStyle(selected: selected),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(List<_NavItemData> items) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final height = bottomInset > 0 ? 82.0 : 68.0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEAECEF), width: 0.8)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(items.length, (i) {
                final item = items[i];
                final selected = index == i;
                return _navItem(
                  item: item,
                  selected: selected,
                  onTap: () {
                    if (index == i) return;

                    final isBooking =
                        items[i].label == context.appText.navBooking;

                    setState(() {
                      if (isBooking) {
                        _bookingScreenSeed++;
                        _cachedScreens = _screens(_resolvedRole ?? 'athlete');
                      }
                      index = i;
                    });
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedScreens == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data ?? _resolvedRole ?? 'athlete';
        if (role == 'owner') {
          return const OwnerHomeScreen();
        }
        _ensureCache(role);

        final currentScreens = _cachedScreens!;
        final currentItems = _cachedItems!;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: IndexedStack(index: index, children: currentScreens),
          bottomNavigationBar: _bottomBar(currentItems),
        );
      },
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _PressableNavItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressableNavItem({required this.child, required this.onTap});

  @override
  State<_PressableNavItem> createState() => _PressableNavItemState();
}

class _PressableNavItemState extends State<_PressableNavItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: _pressed ? const Offset(0, 0.03) : Offset.zero,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
