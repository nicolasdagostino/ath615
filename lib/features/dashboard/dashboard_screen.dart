import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_models.dart';
import 'dashboard_repository.dart';
import 'widgets/dashboard_alert_tile.dart';
import 'widgets/dashboard_alerts_section.dart';
import 'widgets/dashboard_loading_state.dart';
import 'widgets/dashboard_member_activity_tile.dart';
import 'widgets/dashboard_member_activity_section.dart';
import 'widgets/dashboard_morning_overview.dart';
import 'widgets/dashboard_recommended_actions_section.dart';
import 'widgets/dashboard_section_header.dart';
import 'widgets/dashboard_tomorrow_risk_section.dart';

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

  IconData _iconForActionType(String type) {
    switch (type) {
      case 'tomorrow_risk':
        return Icons.campaign_outlined;
      case 'inactive_members':
        return Icons.people_alt_outlined;
      case 'next_class_workout':
      case 'today_workout_missing':
        return Icons.fitness_center_outlined;
      case 'today_bookings':
        return Icons.today_outlined;
      case 'birthday':
        return Icons.cake_outlined;
      case 'open_admin':
      default:
        return Icons.admin_panel_settings_outlined;
    }
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

  Widget _softDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: const Color(0xFFEAECEF),
    );
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

          KeyedSubtree(
            key: _todaySectionKey,
            child: DashboardMorningOverview(
              nextClass: data.nextClass,
              highlights: data.todayHighlights,
              milestones: data.milestones,
              onNextClassTap: () {
                final classId = data.nextClass?.id.trim();
                if (classId == null || classId.isEmpty) return;
                if (widget.onOpenAdminClassDetail != null) {
                  widget.onOpenAdminClassDetail!.call(
                    classId,
                    !(data.nextClass?.hasWorkout ?? true),
                  );
                } else if (widget.onOpenAdminClasses != null) {
                  widget.onOpenAdminClasses!.call();
                }
              },
            ),
          ),
          const SizedBox(height: 30),

          _softDivider(),
          const SizedBox(height: 22),

          const DashboardSectionHeader(
            title: 'Tomorrow risk',
            subtitle: 'Classes that may need attention before tomorrow.',
          ),
          const SizedBox(height: 14),
          DashboardTomorrowRiskSection(
            tomorrow: data.tomorrow,
            emptyPanel: _emptyPanel,
            twoCards: _twoCards,
            onClassTap: (classId, needsWorkoutAssignment) {
              if (widget.onOpenAdminClassDetail != null) {
                widget.onOpenAdminClassDetail!.call(
                  classId,
                  needsWorkoutAssignment,
                );
              } else if (widget.onOpenAdminClasses != null) {
                widget.onOpenAdminClasses!.call();
              } else {
                _showActionMessage('Classes navigation is not available.');
              }
            },
            onUnavailable: () {
              _showActionMessage('Class detail is not available.');
            },
          ),

          const SizedBox(height: 28),
          _softDivider(),
          const SizedBox(height: 22),

          const DashboardSectionHeader(
            title: 'Members activity',
            subtitle: 'Quick CRM-style view of your community.',
          ),
          const SizedBox(height: 14),
          DashboardMemberActivitySection(
            items: data.memberActivity,
            emptyPanel: _emptyPanel,
            onMemberTap: (memberId) {
              if (widget.onOpenAdminMemberDetail != null) {
                widget.onOpenAdminMemberDetail!.call(memberId);
              } else if (widget.onOpenAdminMembers != null) {
                widget.onOpenAdminMembers!.call();
              } else {
                _showActionMessage('Members navigation is not available.');
              }
            },
            onUnavailable: () {
              _showActionMessage('Member detail is not available.');
            },
          ),

          const SizedBox(height: 28),
          _softDivider(),
          const SizedBox(height: 22),

          const DashboardSectionHeader(
            title: 'Recommended actions',
            subtitle: 'Fast next steps for the owner or admin.',
          ),
          const SizedBox(height: 14),
          DashboardRecommendedActionsSection(
            actions: data.recommendedActions,
            iconForActionType: _iconForActionType,
            onActionTap: (action) async {
              switch (action.type) {
                case 'tomorrow_risk':
                  _showTomorrowRiskSheet(data.tomorrow);
                  break;
                case 'inactive_members':
                  _showInactiveMembersSheet(data.memberActivity);
                  break;
                case 'next_class_workout':
                  final classId = data.nextClass?.id.trim();
                  if (classId != null &&
                      classId.isNotEmpty &&
                      widget.onOpenAdminClassDetail != null) {
                    widget.onOpenAdminClassDetail!.call(classId, true);
                  } else if (widget.onOpenAdminClasses != null) {
                    widget.onOpenAdminClasses!.call();
                  } else {
                    _showActionMessage('Classes navigation is not available.');
                  }
                  break;
                case 'today_workout_missing':
                case 'today_bookings':
                  await _scrollToToday();
                  if (widget.onOpenAdminClasses != null) {
                    widget.onOpenAdminClasses!.call();
                  } else {
                    _showActionMessage('Classes navigation is not available.');
                  }
                  break;
                case 'birthday':
                  _showActionMessage(
                    'Review today highlights and congratulate them.',
                  );
                  await _scrollToToday();
                  break;
                case 'open_admin':
                default:
                  if (widget.onOpenAdmin != null) {
                    widget.onOpenAdmin!.call();
                  } else {
                    _showActionMessage(
                      'Admin navigation is not available right now.',
                    );
                  }
                  break;
              }
            },
          ),

          const SizedBox(height: 28),
          _softDivider(),
          const SizedBox(height: 22),

          const DashboardSectionHeader(
            title: 'Alerts',
            subtitle: 'Useful things to review soon.',
          ),
          const SizedBox(height: 14),
          DashboardAlertsSection(
            alerts: data.alerts,
            iconForType: _iconForType,
            emptyPanel: _emptyPanel,
          ),
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
