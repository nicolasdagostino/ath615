import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_models.dart';
import '../../core/supabase/gym_repository.dart';
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
import '../admin/member_detail/admin_member_detail_screen.dart';
import '../admin/class_attendance_screen.dart';
import 'pending_attendance/pending_attendance_screen.dart';
import 'pending_attendance/pending_attendance_repository.dart';
import '../../l10n/app_text.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_toast.dart';

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
  final _gymRepository = GymRepository();
  final _repo = DashboardRepository();
  final _pendingAttendanceRepository = PendingAttendanceRepository();
  final _scrollController = ScrollController();
  final _todaySectionKey = GlobalKey();

  String _dashboardFilter = 'today';
  late Future<DashboardData> _future;
  String _gymName = '';
  int _pendingAttendanceClasses = 0;

  bool _didLoadInitial = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadInitial) return;
    _didLoadInitial = true;
    _future = _repo.loadDashboard(t: context.appText);
    _gymRepository.myGymName().then((value) {
      if (!mounted) return;
      setState(() {
        _gymName = (value ?? '').trim();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final next = _repo.loadDashboard(t: context.appText);
    final gymName = (await _gymRepository.myGymName() ?? '').trim();
    setState(() {
      _future = next;
      _gymName = gymName;
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
    AppToast.show(context, text, icon: Icons.info_outline_rounded);
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
                Text(
                  context.appText.tomorrowRiskTitle,
                  style: _sheetTitleStyle(),
                ),
                const SizedBox(height: 8),
                Text(
                  context.appText.tomorrowRiskSheetSubtitle,
                  style: _subtitleStyle(),
                ),
                const SizedBox(height: 16),
                if (tomorrow.riskClasses.isEmpty)
                  _emptyPanel(context.appText.tomorrowLooksHealthy)
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
                        context.appText.classesNavigationUnavailable,
                      );
                    }
                  },
                  child: Text(context.appText.openClasses),
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
                Text(
                  context.appText.inactiveMembersTitle,
                  style: _sheetTitleStyle(),
                ),
                const SizedBox(height: 8),
                Text(
                  context.appText.inactiveMembersSubtitle,
                  style: _subtitleStyle(),
                ),
                const SizedBox(height: 16),
                if (atRisk.isEmpty)
                  _emptyPanel(context.appText.noInactiveMembers)
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
                      _showActionMessage(context.appText.openMembers);
                    }
                  },
                  child: Text(context.appText.openMembers),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _brandLogo() {
    final gymName = _gymName.trim().isEmpty ? 'ATHLETE LAB' : _gymName.trim();

    return SizedBox(
      width: 132,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gymName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.barlowCondensed(
              fontSize: 16,
              fontWeight: FontWeight.w800,
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
            style: GoogleFonts.barlowCondensed(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8F96A3),
              letterSpacing: 0.7,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topHeader() {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final rawToday = DateFormat(
      'EEEE, MMMM d',
      localeTag,
    ).format(DateTime.now());
    final words = rawToday.split(' ');
    final todayText = words
        .map(
          (part) =>
              part.isEmpty ? part : part[0].toUpperCase() + part.substring(1),
        )
        .join(' ');

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
                  child: _brandLogo(),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.appText.dashboardTitle.toUpperCase(),
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0E0E11),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      todayText,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F3EA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.space_dashboard_rounded,
                        size: 19,
                        color: Color(0xFFB59B6A),
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
      case 'pending_attendance':
        return Icons.fact_check_outlined;
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

  String _uiText(String es, String en) {
    final isSpanish = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('es');
    return isSpanish ? es : en;
  }

  Widget _buildFilterTabs({required bool isCoachView}) {
    Widget chip(String key, String label) {
      final selected = _dashboardFilter == key;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _dashboardFilter = key),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF111318) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF111318)
                    : const Color(0xFFEAECEF),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.barlowCondensed(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : const Color(0xFF111318),
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('today', context.appText.todayUpper),
        const SizedBox(width: 8),
        chip('tomorrow', context.appText.tomorrow.toUpperCase()),
        const SizedBox(width: 8),
        chip(
          isCoachView ? 'attendance' : 'members',
          isCoachView
              ? (_pendingAttendanceClasses > 0
                    ? _uiText(
                        'ATTENDANCE ($_pendingAttendanceClasses)',
                        'ATTENDANCE ($_pendingAttendanceClasses)',
                      )
                    : _uiText('ATTENDANCE', 'ATTENDANCE'))
              : context.appText.membersUpper,
        ),
      ],
    );
  }

  Widget _buildTodayContent(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyedSubtree(
          key: _todaySectionKey,
          child: DashboardMorningOverview(
            nextClass: data.nextClass,
            highlights: data.todayHighlights,
            milestones: data.milestones,
            isCoachView: data.isCoachView,
            pendingAttendanceCount: data.pendingAttendance.pendingClasses,
            onNextClassTap: () async {
              final classId = data.nextClass?.id.trim();
              if (classId == null || classId.isEmpty) return;

              if (data.isCoachView &&
                  data.pendingAttendance.pendingClasses > 0) {
                try {
                  final groups = await _pendingAttendanceRepository
                      .loadPendingAttendance(gymId: data.gymId);

                  final pendingClasses = <dynamic>[
                    for (final group in groups) ...group.classes,
                  ];

                  if (!mounted) return;

                  if (pendingClasses.length == 1) {
                    final classItem = pendingClasses.first.classItem;
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ClassAttendanceScreen(classItem: classItem),
                      ),
                    );
                  } else {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PendingAttendanceScreen(gymId: data.gymId),
                      ),
                    );
                  }

                  await _refresh();
                  return;
                } catch (_) {
                  if (!mounted) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PendingAttendanceScreen(gymId: data.gymId),
                    ),
                  );
                  await _refresh();
                  return;
                }
              }

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
        const SizedBox(height: 28),
        _softDivider(),
        const SizedBox(height: 22),
        DashboardSectionHeader(
          title: data.isCoachView
              ? _uiText('Attendance', 'Attendance')
              : context.appText.recommendedActionsTitle,
          subtitle: data.isCoachView
              ? _uiText(
                  'Review classes that still need attendance.',
                  'Review classes that still need attendance.',
                )
              : context.appText.recommendedActionsSubtitle,
        ),
        const SizedBox(height: 14),
        DashboardRecommendedActionsSection(
          actions: data.isCoachView
              ? data.recommendedActions
                    .where((a) => a.type == 'pending_attendance')
                    .toList()
              : data.recommendedActions,
          iconForActionType: _iconForActionType,
          onActionTap: (action) async {
            switch (action.type) {
              case 'tomorrow_risk':
                _showTomorrowRiskSheet(data.tomorrow);
                break;
              case 'inactive_members':
                _showInactiveMembersSheet(data.memberActivity);
                break;
              case 'pending_attendance':
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PendingAttendanceScreen(gymId: data.gymId),
                  ),
                );
                await _refresh();
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
                  _showActionMessage(
                    context.appText.classesNavigationUnavailable,
                  );
                }
                break;
              case 'today_workout_missing':
              case 'today_bookings':
                await _scrollToToday();
                if (!mounted) return;
                final classesNavigationUnavailable =
                    context.appText.classesNavigationUnavailable;
                if (widget.onOpenAdminClasses != null) {
                  widget.onOpenAdminClasses!.call();
                } else {
                  _showActionMessage(classesNavigationUnavailable);
                }
                break;
              case 'birthday':
                _showActionMessage(
                  context.appText.reviewHighlightsAndCongratulate,
                );
                await _scrollToToday();
                break;
              case 'open_admin':
              default:
                if (widget.onOpenAdmin != null) {
                  widget.onOpenAdmin!.call();
                } else {
                  _showActionMessage(
                    context.appText.adminNavigationUnavailable,
                  );
                }
                break;
            }
          },
        ),
        if (!data.isCoachView) ...[
          const SizedBox(height: 28),
          _softDivider(),
          const SizedBox(height: 22),
          DashboardSectionHeader(
            title: context.appText.alertsTitle,
            subtitle: context.appText.alertsSubtitle,
          ),
          const SizedBox(height: 14),
          DashboardAlertsSection(
            alerts: data.alerts,
            iconForType: _iconForType,
            emptyPanel: _emptyPanel,
          ),
          const SizedBox(height: 28),
          _softDivider(),
          const SizedBox(height: 22),
          DashboardSectionHeader(
            title: context.appText.tomorrowRiskTitle,
            subtitle: context.appText.tomorrowRiskSubtitle,
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
                _showActionMessage(
                  context.appText.classesNavigationUnavailable,
                );
              }
            },
            onUnavailable: () {
              _showActionMessage(context.appText.classDetailUnavailable);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTomorrowContent(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: data.isCoachView
              ? _uiText('Tomorrow', 'Tomorrow')
              : context.appText.tomorrowRiskTitle,
          subtitle: data.isCoachView
              ? _uiText(
                  'Your upcoming classes for tomorrow.',
                  'Your upcoming classes for tomorrow.',
                )
              : context.appText.tomorrowRiskSubtitle,
        ),
        const SizedBox(height: 14),
        DashboardTomorrowRiskSection(
          tomorrow: data.tomorrow,
          emptyPanel: _emptyPanel,
          twoCards: _twoCards,
          isCoachView: data.isCoachView,
          uiText: _uiText,
          onClassTap: (classId, needsWorkoutAssignment) {
            if (widget.onOpenAdminClassDetail != null) {
              widget.onOpenAdminClassDetail!.call(
                classId,
                needsWorkoutAssignment,
              );
            } else if (widget.onOpenAdminClasses != null) {
              widget.onOpenAdminClasses!.call();
            } else {
              _showActionMessage(context.appText.classesNavigationUnavailable);
            }
          },
          onUnavailable: () {
            _showActionMessage(context.appText.classDetailUnavailable);
          },
        ),
      ],
    );
  }

  Widget _buildAttendanceContent(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: _uiText('Attendance', 'Attendance'),
          subtitle: _uiText(
            'Open pending classes and review attendance.',
            'Open pending classes and review attendance.',
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.pendingAttendance.pendingClasses > 0
                    ? _uiText('Pending attendance', 'Pending attendance')
                    : _uiText('All caught up', 'All caught up'),
                style: _titleStyle().copyWith(fontSize: 24),
              ),
              const SizedBox(height: 6),
              Text(
                data.pendingAttendance.pendingClasses > 0
                    ? _uiText(
                        '${data.pendingAttendance.pendingClasses} classes still need review.',
                        '${data.pendingAttendance.pendingClasses} classes still need review.',
                      )
                    : _uiText(
                        'There are no past classes waiting for attendance review.',
                        'There are no past classes waiting for attendance review.',
                      ),
                style: _subtitleStyle(),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PendingAttendanceScreen(gymId: data.gymId),
                    ),
                  );
                  await _refresh();
                },
                child: Text(_uiText('Open attendance', 'Open attendance')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembersContent(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: context.appText.membersActivityTitle,
          subtitle: context.appText.membersActivitySubtitle,
        ),
        const SizedBox(height: 14),
        DashboardMemberActivitySection(
          items: data.memberActivity,
          emptyPanel: _emptyPanel,
          onMemberTap: (memberId) async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FutureBuilder<String?>(
                  future: _gymRepository.resolveGymId(),
                  builder: (context, snapshot) {
                    final gymId = (snapshot.data ?? '').trim();
                    if (gymId.isEmpty) {
                      return Scaffold(
                        body: Center(child: Text(context.appText.gymNotFound)),
                      );
                    }
                    return AdminMemberDetailScreen(
                      gymId: gymId,
                      memberId: memberId,
                    );
                  },
                ),
              ),
            );
            await _refresh();
          },
          onUnavailable: () {
            _showActionMessage(context.appText.memberDetailUnavailable);
          },
        ),
      ],
    );
  }

  Widget _content(DashboardData data) {
    _pendingAttendanceClasses = data.pendingAttendance.pendingClasses;
    Widget activeContent() {
      switch (_dashboardFilter) {
        case 'tomorrow':
          return _buildTomorrowContent(data);
        case 'attendance':
          return _buildAttendanceContent(data);
        case 'members':
          return data.isCoachView
              ? _buildAttendanceContent(data)
              : _buildMembersContent(data);
        case 'today':
        default:
          return _buildTodayContent(data);
      }
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(context.appText.dashboardTitle, style: _titleStyle()),
          const SizedBox(height: 8),
          Text(
            data.isCoachView
                ? _uiText(
                    'Your classes and attendance for today.',
                    'Your classes and attendance for today.',
                  )
                : context.appText.dashboardSubtitle,
            style: _subtitleStyle(),
          ),
          const SizedBox(height: 18),
          _buildFilterTabs(isCoachView: data.isCoachView),
          const SizedBox(height: 22),
          activeContent(),
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
          Text(context.appText.dashboardTitle, style: _titleStyle()),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEAECEF), width: 1),
            ),
            child: Text(
              context.appText.couldNotLoadDashboardData(error.toString()),
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
              return Column(
                children: [
                  _topHeader(),
                  Expanded(child: _errorState(snapshot.error!)),
                ],
              );
            }

            final data = snapshot.data;
            if (data == null) {
              return Column(
                children: [
                  _topHeader(),
                  Expanded(
                    child: _errorState(
                      context.appText.noDashboardDataAvailable,
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _topHeader(),
                Expanded(child: _content(data)),
              ],
            );
          },
        ),
      ),
    );
  }
}
