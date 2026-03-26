import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/admin/admin_screen.dart';
import '../../features/booking/booking_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/explore/explore_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/workouts/workouts_screen.dart';

class BottomNavShell extends StatefulWidget {
  const BottomNavShell({super.key});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  int index = 1;
  final _sb = Supabase.instance.client;

  late Future<bool> _isAdminFuture;

  bool? _resolvedIsAdmin;
  List<Widget>? _cachedScreens;
  List<_NavItemData>? _cachedItems;
  int _bookingScreenSeed = 0;

  @override
  void initState() {
    super.initState();
    _isAdminFuture = _isAdmin();
  }

  Future<bool> _isAdmin() async {
    final user = _sb.auth.currentUser;
    if (user == null) return false;

    try {
      final byId = await _sb
          .from('profiles')
          .select('role, email')
          .eq('id', user.id)
          .maybeSingle();

      if (byId != null) {
        final role = (byId['role'] ?? '').toString().toLowerCase().trim();
        debugPrint('BOTTOM_NAV byId role=$role email=${byId['email']}');
        if (role == 'admin') return true;
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
          if (role == 'admin') return true;
        }
      }
    } catch (e) {
      debugPrint('BOTTOM_NAV _isAdmin error: $e');
    }

    return false;
  }

  List<Widget> _screens(bool isAdmin) {
    final base = <Widget>[
      const WorkoutsScreen(),
      BookingScreen(key: ValueKey('booking_$_bookingScreenSeed')),
      const ExploreScreen(),
    ];

    if (isAdmin) {
      base.add(const DashboardScreen());
      base.add(const AdminScreen());
    }

    base.add(const ProfileScreen());
    return base;
  }

  List<_NavItemData> _items(bool isAdmin) {
    final base = <_NavItemData>[
      const _NavItemData(
        icon: Icons.fitness_center_outlined,
        activeIcon: Icons.fitness_center,
        label: 'Workouts',
      ),
      const _NavItemData(
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        label: 'Booking',
      ),
      const _NavItemData(
        icon: Icons.search_outlined,
        activeIcon: Icons.search,
        label: 'Explore',
      ),
    ];

    if (isAdmin) {
      base.add(
        const _NavItemData(
          icon: Icons.space_dashboard_outlined,
          activeIcon: Icons.space_dashboard,
          label: 'Dashboard',
        ),
      );
      base.add(
        const _NavItemData(
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings,
          label: 'Admin',
        ),
      );
    }

    base.add(
      const _NavItemData(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
      ),
    );

    return base;
  }

  void _ensureCache(bool isAdmin) {
    if (_resolvedIsAdmin == isAdmin &&
        _cachedScreens != null &&
        _cachedItems != null) {
      return;
    }

    _resolvedIsAdmin = isAdmin;
    _cachedScreens = _screens(isAdmin);
    _cachedItems = _items(isAdmin);

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

                    final isBooking = items[i].label == 'Booking';

                    setState(() {
                      if (isBooking) {
                        _bookingScreenSeed++;
                        _cachedScreens = _screens(_resolvedIsAdmin ?? false);
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
    return FutureBuilder<bool>(
      future: _isAdminFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedScreens == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAdmin = snapshot.data ?? _resolvedIsAdmin ?? false;
        _ensureCache(isAdmin);

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
