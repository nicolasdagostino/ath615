import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_models.dart';
import 'dashboard_repository.dart';
import 'widgets/dashboard_action_tile.dart';
import 'widgets/dashboard_alert_tile.dart';
import 'widgets/dashboard_kpi_card.dart';
import 'widgets/dashboard_loading_state.dart';
import 'widgets/dashboard_member_activity_tile.dart';
import 'widgets/dashboard_next_class_card.dart';
import 'widgets/dashboard_section_header.dart';
import 'widgets/dashboard_today_highlights_card.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenAdmin;
  final VoidCallback? onOpenAdminClasses;
  final VoidCallback? onOpenAdminMembers;
  final ValueChanged<String>? onOpenAdminMemberDetail;
  final void Function(String classId, bool openAssignWorkout)?
  onOpenAdminClassDetail;

  const DashboardScreen({
    super.key,
    this.onOpenAdmin,
    this.onOpenAdminClasses,
    this.onOpenAdminMembers,
    this.onOpenAdminMemberDetail,
    this.onOpenAdminClassDetail,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = DashboardRepository();
  final _scrollController = ScrollController();
  final _todaySectionKey = GlobalKey();

  late Future<DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.loadDashboard();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final next = _repo.loadDashboard();
    setState(() {
      _future = next;
    });
    await next;
  }

  Future<void> _scrollToToday() async {
    final context = _todaySectionKey.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
  }

  void _showActionMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _showTomorrowRiskSheet(DashboardTomorrowStats tomorrow) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF7F8FA),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text('Tomorrow risk', style: _sheetTitleStyle()),
                const SizedBox(height: 8),
                Text(
                  'Classes that may need promotion, review or schedule adjustments before tomorrow.',
                  style: _subtitleStyle(),
                ),
                const SizedBox(height: 16),
                if (tomorrow.riskClasses.isEmpty)
                  _emptyPanel('Tomorrow looks healthy right now.')
                else ...[
                  for (var i = 0; i < tomorrow.riskClasses.length; i++) ...[
                    DashboardAlertTile(
                      icon: Icons.event_busy_outlined,
                      title: tomorrow.riskClasses[i].title,
                      subtitle: tomorrow.riskClasses[i].subtitle,
                    ),
                    if (i != tomorrow.riskClasses.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (widget.onOpenAdminClasses != null) {
                      widget.onOpenAdminClasses!.call();
                    } else {
                      _showActionMessage(
                        'Classes navigation is not available.',
                      );
                    }
                  },
                  child: const Text('Open Classes'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInactiveMembersSheet(List<DashboardMemberActivityItem> items) {
    final atRisk = items.where((e) => e.isAtRisk).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF7F8FA),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: ListView(
              shrinkWrap: true,
              children: [
                Text('Inactive members', style: _sheetTitleStyle()),
                const SizedBox(height: 8),
                Text(
                  'Members who may need a follow-up message or personal check-in.',
                  style: _subtitleStyle(),
                ),
                const SizedBox(height: 16),
                if (atRisk.isEmpty)
                  _emptyPanel('No inactive members right now.')
                else ...[
                  for (var i = 0; i < atRisk.length; i++) ...[
                    DashboardMemberActivityTile(
                      name: atRisk[i].name,
                      subtitle: atRisk[i].subtitle,
                      isAtRisk: atRisk[i].isAtRisk,
                    ),
                    if (i != atRisk.length - 1) const SizedBox(height: 10),
                  ],
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (widget.onOpenAdminMembers != null) {
                      widget.onOpenAdminMembers!.call();
                    } else {
                      _showActionMessage(
                        'Members navigation is not available.',
                      );
                    }
                  },
                  child: const Text('Open Members'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  TextStyle _titleStyle() {
    return GoogleFonts.barlowCondensed(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF111318),
      height: 1.0,
    );
  }

  TextStyle _sheetTitleStyle() {
    return GoogleFonts.barlowCondensed(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF111318),
      height: 1.0,
    );
  }

  TextStyle _subtitleStyle() {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF8F96A3),
      height: 1.45,
    );
  }

  String _percent(double value) {
    if (value.isNaN || value.isInfinite) return '0%';
    return '${value.toStringAsFixed(0)}%';
  }

  String _decimal(double value) {
    if (value.isNaN || value.isInfinite) return '0.0';
    return value.toStringAsFixed(1);
  }

  String _deltaInt(int current, int previous) {
    final diff = current - previous;
    if (diff == 0) return 'No change vs last week';
    final sign = diff > 0 ? '+' : '';
    return '$sign$diff vs last week';
  }

  String _deltaPercentPoints(double current, double previous) {
    final diff = current - previous;
    if (diff.abs() < 0.05) return 'No change vs last week';
    final sign = diff > 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(0)} pts vs last week';
  }

  String _deltaDecimal(double current, double previous) {
    final diff = current - previous;
    if (diff.abs() < 0.05) return 'No change vs last week';
    final sign = diff > 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(1)} vs last week';
  }

  Widget _twoCards({required Widget left, required Widget right}) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _emptyPanel(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAECEF), width: 1),
      ),
      child: Text(text, style: _subtitleStyle()),
    );
  }

  Widget _alerts(List<DashboardAlertItem> alerts) {
    if (alerts.isEmpty) {
      return _emptyPanel('No urgent alerts right now.');
    }

    return Column(
      children: [
        for (var i = 0; i < alerts.length; i++) ...[
          DashboardAlertTile(
            icon: _iconForType(alerts[i].type),
            title: alerts[i].title,
            subtitle: alerts[i].subtitle,
          ),
          if (i != alerts.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _tomorrowRisk(DashboardTomorrowStats tomorrow) {
    if (tomorrow.riskClasses.isEmpty) {
      return _emptyPanel('Tomorrow looks healthy right now.');
    }

    return Column(
      children: [
        for (var i = 0; i < tomorrow.riskClasses.length; i++) ...[
          GestureDetector(
            onTap: () {
              final classId = tomorrow.riskClasses[i].id.trim();
              if (classId.isEmpty) {
                _showActionMessage('Class detail is not available.');
                return;
              }
              if (widget.onOpenAdminClassDetail != null) {
                widget.onOpenAdminClassDetail!.call(
                  classId,
                  tomorrow.riskClasses[i].needsWorkoutAssignment,
                );
              } else if (widget.onOpenAdminClasses != null) {
                widget.onOpenAdminClasses!.call();
              } else {
                _showActionMessage('Classes navigation is not available.');
              }
            },
            child: DashboardAlertTile(
              icon: Icons.event_busy_outlined,
              title: tomorrow.riskClasses[i].title,
              subtitle: tomorrow.riskClasses[i].subtitle,
            ),
          ),
          if (i != tomorrow.riskClasses.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _memberActivity(List<DashboardMemberActivityItem> items) {
    if (items.isEmpty) {
      return _emptyPanel('No active member data yet.');
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          DashboardMemberActivityTile(
            name: items[i].name,
            subtitle: items[i].subtitle,
            isAtRisk: items[i].isAtRisk,
            onTap: () {
              final memberId = items[i].id.trim();
              if (memberId.isEmpty) {
                _showActionMessage('Member detail is not available.');
                return;
              }
              if (widget.onOpenAdminMemberDetail != null) {
                widget.onOpenAdminMemberDetail!.call(memberId);
              } else if (widget.onOpenAdminMembers != null) {
                widget.onOpenAdminMembers!.call();
              } else {
                _showActionMessage('Members navigation is not available.');
              }
            },
          ),
          if (i != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _actions(DashboardData data) {
    final inactiveCount = data.memberActivity.where((e) => e.isAtRisk).length;

    return Column(
      children: [
        DashboardActionTile(
          icon: Icons.campaign_outlined,
          title: 'Review tomorrow risk',
          subtitle:
              '${data.tomorrow.lowOccupancyTomorrow} classes may need promotion.',
          onTap: () => _showTomorrowRiskSheet(data.tomorrow),
        ),
        const SizedBox(height: 10),
        DashboardActionTile(
          icon: Icons.people_alt_outlined,
          title: 'Check inactive members',
          subtitle: '$inactiveCount members may need a follow-up message.',
          onTap: () => _showInactiveMembersSheet(data.memberActivity),
        ),
        const SizedBox(height: 10),
        DashboardActionTile(
          icon: Icons.today_outlined,
          title: 'Review today bookings',
          subtitle:
              '${data.today.bookingsToday} bookings currently on today schedule.',
          onTap: () async {
            await _scrollToToday();
            if (widget.onOpenAdminClasses != null) {
              widget.onOpenAdminClasses!.call();
            }
          },
        ),
        const SizedBox(height: 10),
        DashboardActionTile(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Open admin',
          subtitle: 'Go to admin tools to manage classes, members and plans.',
          onTap: () {
            if (widget.onOpenAdmin != null) {
              widget.onOpenAdmin!.call();
            } else {
              _showActionMessage(
                'Admin navigation is not available right now.',
              );
            }
          },
        ),
      ],
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'birthday':
        return Icons.cake_outlined;
      case 'inactive_member':
        return Icons.person_search_outlined;
      case 'low_occupancy':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  Widget _content(DashboardData data) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('Dashboard', style: _titleStyle()),
          const SizedBox(height: 8),
          Text('Business insights for your gym.', style: _subtitleStyle()),
          const SizedBox(height: 24),

          if (data.nextClass != null) ...[
            DashboardNextClassCard(
              title: data.nextClass!.title,
              subtitle: data.nextClass!.subtitle,
              occupancyLabel: data.nextClass!.occupancyLabel,
              hasWorkout: data.nextClass!.hasWorkout,
              onTap: () {
                final classId = data.nextClass!.id.trim();
                if (classId.isEmpty) return;
                if (widget.onOpenAdminClassDetail != null) {
                  widget.onOpenAdminClassDetail!.call(
                    classId,
                    !data.nextClass!.hasWorkout,
                  );
                } else if (widget.onOpenAdminClasses != null) {
                  widget.onOpenAdminClasses!.call();
                }
              },
            ),
            const SizedBox(height: 16),
          ],

          DashboardTodayHighlightsCard(items: data.todayHighlights),
          const SizedBox(height: 28),

          KeyedSubtree(
            key: _todaySectionKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DashboardSectionHeader(
                  title: 'Today',
                  subtitle: 'Quick operational snapshot.',
                ),
                const SizedBox(height: 14),
                _twoCards(
                  left: DashboardKpiCard(
                    label: 'Classes',
                    value: data.today.classesToday.toString(),
                    helper: 'Scheduled today',
                  ),
                  right: DashboardKpiCard(
                    label: 'Bookings',
                    value: data.today.bookingsToday.toString(),
                    helper: 'Reserved spots',
                  ),
                ),
                const SizedBox(height: 12),
                _twoCards(
                  left: DashboardKpiCard(
                    label: 'Attendance',
                    value: data.today.attendanceToday.toString(),
                    helper: 'Checked in',
                  ),
                  right: DashboardKpiCard(
                    label: 'Full classes',
                    value: data.today.fullClassesToday.toString(),
                    helper: 'At capacity',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          const DashboardSectionHeader(
            title: 'Members',
            subtitle: 'How your community is moving.',
          ),
          const SizedBox(height: 14),
          _twoCards(
            left: DashboardKpiCard(
              label: 'Active members',
              value: data.members.activeMembers.toString(),
              helper: 'Currently enabled profiles',
            ),
            right: DashboardKpiCard(
              label: 'New this month',
              value: data.members.newMembersThisMonth.toString(),
              helper: 'Joined during current month',
            ),
          ),

          const SizedBox(height: 28),
          const DashboardSectionHeader(
            title: 'Engagement',
            subtitle: 'Useful retention signals.',
          ),
          const SizedBox(height: 14),
          _twoCards(
            left: DashboardKpiCard(
              label: 'Inactive 7d',
              value: data.engagement.inactive7Days.toString(),
              helper: 'No recent booking activity',
            ),
            right: DashboardKpiCard(
              label: 'Inactive 14d',
              value: data.engagement.inactive14Days.toString(),
              helper: 'Longer inactivity window',
            ),
          ),

          const SizedBox(height: 28),
          const DashboardSectionHeader(
            title: 'Performance',
            subtitle: 'Weekly business indicators.',
          ),
          const SizedBox(height: 14),
          _twoCards(
            left: DashboardKpiCard(
              label: 'Bookings this week',
              value: data.performance.bookingsThisWeek.toString(),
              helper: _deltaInt(
                data.performance.bookingsThisWeek,
                data.performance.bookingsLastWeek,
              ),
            ),
            right: DashboardKpiCard(
              label: 'Attendance rate',
              value: _percent(data.performance.attendanceRate),
              helper: _deltaPercentPoints(
                data.performance.attendanceRate,
                data.performance.attendanceRateLastWeek,
              ),
            ),
          ),
          const SizedBox(height: 12),
          DashboardKpiCard(
            label: 'Avg athletes / class',
            value: _decimal(data.performance.avgAthletesPerClass),
            helper: _deltaDecimal(
              data.performance.avgAthletesPerClass,
              data.performance.avgAthletesPerClassLastWeek,
            ),
          ),

          const SizedBox(height: 28),
          const DashboardSectionHeader(
            title: 'Tomorrow risk',
            subtitle: 'Classes that may need attention before tomorrow.',
          ),
          const SizedBox(height: 14),
          _twoCards(
            left: DashboardKpiCard(
              label: 'Classes tomorrow',
              value: data.tomorrow.classesTomorrow.toString(),
              helper: 'Scheduled for tomorrow',
            ),
            right: DashboardKpiCard(
              label: 'Low occupancy',
              value: data.tomorrow.lowOccupancyTomorrow.toString(),
              helper: 'Need promotion or review',
            ),
          ),
          const SizedBox(height: 12),
          _tomorrowRisk(data.tomorrow),

          const SizedBox(height: 28),
          const DashboardSectionHeader(
            title: 'Members activity',
            subtitle: 'Quick CRM-style view of your community.',
          ),
          const SizedBox(height: 14),
          _memberActivity(data.memberActivity),

          const SizedBox(height: 28),
          const DashboardSectionHeader(
            title: 'Recommended actions',
            subtitle: 'Fast next steps for the owner or admin.',
          ),
          const SizedBox(height: 14),
          _actions(data),

          const SizedBox(height: 28),
          const DashboardSectionHeader(
            title: 'Alerts',
            subtitle: 'Useful things to review soon.',
          ),
          const SizedBox(height: 14),
          _alerts(data.alerts),
        ],
      ),
    );
  }

  Widget _errorState(Object error) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          Text('Dashboard', style: _titleStyle()),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEAECEF), width: 1),
            ),
            child: Text(
              'Could not load dashboard data. Pull to refresh.\n\n$error',
              style: _subtitleStyle(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: FutureBuilder<DashboardData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const DashboardLoadingState();
            }

            if (snapshot.hasError) {
              return _errorState(snapshot.error!);
            }

            final data = snapshot.data;
            if (data == null) {
              return _errorState('No dashboard data available.');
            }

            return _content(data);
          },
        ),
      ),
    );
  }
}
