import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_models.dart';
import '../../core/supabase/gym_repository.dart';
import '../../core/supabase/admin_member_repository.dart';
import 'dashboard_repository.dart';
import 'widgets/dashboard_loading_state.dart';
import 'widgets/dashboard_kpi_card.dart';
import 'widgets/dashboard_section_header.dart';
import 'widgets/dashboard_tomorrow_risk_section.dart';
import '../admin/member_detail/admin_member_detail_screen.dart';
import 'pending_attendance/pending_attendance_screen.dart';
import '../../l10n/app_text.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_toast.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onOpenAdminMembers;
  final ValueChanged<String>? onOpenAdminMemberDetail;
  final void Function(String classId, bool openAssignWorkout)?
  onOpenAdminClassDetail;

  const DashboardScreen({
    super.key,
    this.onOpenAdminMembers,
    this.onOpenAdminMemberDetail,
    this.onOpenAdminClassDetail,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _gymRepository = GymRepository();
  final _adminMemberRepository = AdminMemberRepository();
  final _repo = DashboardRepository();
  final _scrollController = ScrollController();

  String _dashboardFilter = 'today';
  String _memberSearch = '';
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

  bool _isValidEmail(String value) {
    final email = value.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _showQuickAddMemberSheet() async {
    final fullNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String? localError;
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF7F8FA),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              final fullName = fullNameCtrl.text.trim();
              final email = emailCtrl.text.trim().toLowerCase();

              if (fullName.isEmpty) {
                setModalState(() {
                  localError = context.appText.fullNameRequiredError;
                });
                return;
              }

              if (!_isValidEmail(email)) {
                setModalState(() {
                  localError = context.appText.validEmailRequiredError;
                });
                return;
              }

              setModalState(() {
                localError = null;
                saving = true;
              });

              try {
                final parentContext = this.context;

                await _adminMemberRepository.createMember(
                  fullName: fullName,
                  email: email,
                  role: 'athlete',
                );

                if (!mounted) return;
                Navigator.of(sheetContext).pop();
                AppToast.show(
                  parentContext,
                  parentContext.appText.memberCreatedInvitationSent,
                );
                await _refresh();
              } catch (e) {
                setModalState(() {
                  localError = e
                      .toString()
                      .replaceFirst('Exception: ', '')
                      .trim();
                  saving = false;
                });
              }
            }

            final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _uiText('Añadir miembro', 'Add member'),
                        style: _titleStyle().copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _uiText(
                          'Alta rápida con nombre y email. La invitación se enviará automáticamente.',
                          'Quick signup with name and email. The invitation will be sent automatically.',
                        ),
                        style: _subtitleStyle(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: fullNameCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: _uiText('Nombre completo', 'Full name'),
                          hintText: _uiText('John Doe', 'John Doe'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: _uiText('Email', 'Email'),
                          hintText: 'john@email.com',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onSubmitted: (_) => submit(),
                      ),
                      if (localError != null &&
                          localError!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          localError!,
                          style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(),
                              child: Text(_uiText('Cancelar', 'Cancel')),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: saving ? null : submit,
                              child: Text(
                                saving
                                    ? _uiText('Creando...', 'Creating...')
                                    : _uiText('Crear miembro', 'Create member'),
                              ),
                            ),
                          ),
                        ],
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
              letterSpacing: 0.6,
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
                        fontSize: 10,
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
        const SizedBox(width: 10),
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
                fontSize: 12,
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
        DashboardSectionHeader(
          title: _uiText('Hoy', 'Today'),
          subtitle: _uiText(
            'Métricas principales del gimnasio hoy.',
            'Main gym metrics for today.',
          ),
        ),
        const SizedBox(height: 14),
        _twoCards(
          left: DashboardKpiCard(
            label: _uiText('CLASES HOY', 'CLASSES TODAY'),
            value: data.today.classesToday.toString(),
            helper: _uiText('Programadas hoy', 'Scheduled today'),
          ),
          right: DashboardKpiCard(
            label: _uiText('RESERVAS HOY', 'BOOKINGS TODAY'),
            value: data.today.bookingsToday.toString(),
            helper: _uiText('Reservas activas', 'Active bookings'),
          ),
        ),
        const SizedBox(height: 12),
        _twoCards(
          left: DashboardKpiCard(
            label: _uiText('ASISTENCIA', 'ATTENDANCE'),
            value: data.today.attendanceToday.toString(),
            helper: _uiText('Check-ins marcados', 'Marked check-ins'),
          ),
          right: DashboardKpiCard(
            label: _uiText('CLASES LLENAS', 'FULL CLASSES'),
            value: data.today.fullClassesToday.toString(),
            helper: _uiText('Sin cupos libres', 'No free spots'),
          ),
        ),
        const SizedBox(height: 28),
        DashboardSectionHeader(
          title: _uiText('Ingresos y membresías', 'Revenue and memberships'),
          subtitle: _uiText(
            'Resumen comercial del mes en curso.',
            'Commercial summary for the current month.',
          ),
        ),
        const SizedBox(height: 14),
        _twoCards(
          left: DashboardKpiCard(
            label: _uiText('INGRESOS MES', 'MONTH REVENUE'),
            value: data.revenue.revenueThisMonth.toStringAsFixed(0),
            helper: _uiText(
              'Pagos del mes: ${data.revenue.paymentsThisMonth}',
              'Payments this month: ${data.revenue.paymentsThisMonth}',
            ),
          ),
          right: DashboardKpiCard(
            label: _uiText('MEMBRESÍAS ACTIVAS', 'ACTIVE MEMBERSHIPS'),
            value: data.revenue.activeMemberships.toString(),
            helper: _uiText(
              'Vencidas: ${data.revenue.expiredMemberships}',
              'Expired: ${data.revenue.expiredMemberships}',
            ),
          ),
        ),
        const SizedBox(height: 28),
        DashboardSectionHeader(
          title: _uiText('Rendimiento semanal', 'Weekly performance'),
          subtitle: _uiText(
            'Comparación rápida contra la semana pasada.',
            'Quick comparison versus last week.',
          ),
        ),
        const SizedBox(height: 14),
        _twoCards(
          left: DashboardKpiCard(
            label: _uiText('RESERVAS SEMANA', 'WEEK BOOKINGS'),
            value: data.performance.bookingsThisWeek.toString(),
            helper: _uiText(
              'Semana pasada: ${data.performance.bookingsLastWeek}',
              'Last week: ${data.performance.bookingsLastWeek}',
            ),
          ),
          right: DashboardKpiCard(
            label: _uiText('OCUPACIÓN SEM.', 'WEEK OCCUPANCY'),
            value:
                '${data.performance.occupancyRateThisWeek.toStringAsFixed(0)}%',
            helper: _uiText(
              'Semana pasada: ${data.performance.occupancyRateLastWeek.toStringAsFixed(0)}%',
              'Last week: ${data.performance.occupancyRateLastWeek.toStringAsFixed(0)}%',
            ),
          ),
        ),
        const SizedBox(height: 28),
        DashboardSectionHeader(
          title: _uiText('Clases con más demanda', 'Top demand classes'),
          subtitle: _uiText(
            'Las sesiones que mejor están funcionando esta semana.',
            'The best performing sessions this week.',
          ),
        ),
        const SizedBox(height: 14),
        if (data.topClasses.isEmpty)
          _emptyPanel(
            _uiText('No hay clases para analizar.', 'No classes to analyze.'),
          )
        else
          ...data.topClasses.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111318),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(item.subtitle, style: _subtitleStyle()),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${item.occupancyRate.toStringAsFixed(0)}%',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111318),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 18),
        DashboardSectionHeader(
          title: _uiText('Clases más flojas', 'Lowest demand classes'),
          subtitle: _uiText(
            'Las sesiones que quizás debas revisar, mover o empujar.',
            'Sessions you may want to review, move, or promote.',
          ),
        ),
        const SizedBox(height: 14),
        if (data.lowClasses.isEmpty)
          _emptyPanel(
            _uiText('No hay clases para analizar.', 'No classes to analyze.'),
          )
        else
          ...data.lowClasses.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111318),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(item.subtitle, style: _subtitleStyle()),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${item.occupancyRate.toStringAsFixed(0)}%',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111318),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTomorrowContent(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: _uiText('Mañana', 'Tomorrow'),
          subtitle: data.isCoachView
              ? _uiText(
                  'Your upcoming classes for tomorrow.',
                  'Your upcoming classes for tomorrow.',
                )
              : _uiText(
                  'Demand and risk for tomorrow\'s schedule.',
                  'Demand and risk for tomorrow\'s schedule.',
                ),
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
            } else {
              AppToast.show(
                context,
                context.appText.classesNavigationUnavailable,
                icon: Icons.info_outline_rounded,
              );
            }
          },
          onUnavailable: () {
            AppToast.show(
              context,
              context.appText.classDetailUnavailable,
              icon: Icons.info_outline_rounded,
            );
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
          title: _uiText('Asistencia', 'Attendance'),
          subtitle: _uiText(
            'Open pending classes and review attendance.',
            'Open pending classes and review attendance.',
          ),
        ),
        const SizedBox(height: 14),
        _twoCards(
          left: DashboardKpiCard(
            label: _uiText('Clases pendientes', 'Pending classes'),
            value: data.pendingAttendance.pendingClasses.toString(),
            helper: _uiText(
              'Past classes waiting for review.',
              'Past classes waiting for review.',
            ),
          ),
          right: DashboardKpiCard(
            label: _uiText('Reservas pendientes', 'Pending bookings'),
            value: data.pendingAttendance.pendingBookings.toString(),
            helper: _uiText(
              'Booked spots not reviewed yet.',
              'Booked spots not reviewed yet.',
            ),
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
                    ? _uiText('Listo para revisar', 'Ready to review')
                    : _uiText('Todo al día', 'All caught up'),
                style: _titleStyle().copyWith(fontSize: 24),
              ),
              const SizedBox(height: 6),
              Text(
                data.pendingAttendance.pendingClasses > 0
                    ? _uiText(
                        '${data.pendingAttendance.pendingClasses} classes still need attendance.',
                        '${data.pendingAttendance.pendingClasses} classes still need attendance.',
                      )
                    : _uiText(
                        'There are no classes waiting for attendance review.',
                        'There are no classes waiting for attendance review.',
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
                child: Text(_uiText('Abrir asistencia', 'Open attendance')),
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
          title: _uiText('Miembros', 'Members'),
          subtitle: _uiText(
            'Busca clientes, abre su ficha o añade nuevos atletas.',
            'Search clients, open their profile, or add new athletes.',
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFE3E7ED),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: Color(0xFF8F96A3),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              onChanged: (value) {
                                setState(() => _memberSearch = value);
                              },
                              decoration: InputDecoration(
                                hintText: _uiText(
                                  'Buscar miembro...',
                                  'Search member...',
                                ),
                                hintStyle: _subtitleStyle().copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF98A2B3),
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              style: _subtitleStyle().copyWith(
                                fontSize: 13,
                                color: const Color(0xFF111318),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 40,
                    child: FilledButton(
                      onPressed: () async {
                        await _showQuickAddMemberSheet();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFB59B6A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Builder(
          builder: (context) {
            final query = _memberSearch.trim().toLowerCase();
            final members = data.memberRows.where((m) {
              final name = (m['full_name'] ?? '').toString().toLowerCase();
              final email = (m['email'] ?? '').toString().toLowerCase();
              return query.isEmpty ||
                  name.contains(query) ||
                  email.contains(query);
            }).toList();

            if (members.isEmpty) {
              return _emptyPanel(
                _uiText('No hay miembros para mostrar.', 'No members to show.'),
              );
            }

            return Column(
              children: members.map((m) {
                final name = (m['full_name'] ?? 'Member').toString().trim();
                final email = (m['email'] ?? '').toString().trim();
                final active = m['is_active'] == true;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () async {
                      final gymId = (data.gymId ?? '').trim();
                      if (gymId.isEmpty) return;

                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminMemberDetailScreen(
                            gymId: gymId,
                            memberId: m['id'].toString(),
                          ),
                        ),
                      );

                      await _refresh();
                    },
                    child: AppCard(
                      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFFEAF7EE)
                                  : const Color(0xFFF2F4F7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              color: active
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF98A2B3),
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.isEmpty ? 'Member' : name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _titleStyle().copyWith(
                                    fontSize: 17,
                                    height: 1.0,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                if (email.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _subtitleStyle().copyWith(
                                      fontSize: 12,
                                      height: 1.15,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFFEAF7EE)
                                  : const Color(0xFFF2F4F7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              active ? 'ACTIVE' : 'INACTIVE',
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: active
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF667085),
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF98A2B3),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        DashboardSectionHeader(
          title: _uiText('Estado de miembros', 'Member health'),
          subtitle: _uiText(
            'Resumen rápido de crecimiento y riesgo.',
            'Quick summary of growth and risk.',
          ),
        ),
        const SizedBox(height: 14),
        _twoCards(
          left: DashboardKpiCard(
            label: _uiText('Miembros activos', 'Active members'),
            value: data.members.activeMembers.toString(),
            helper: _uiText(
              'Actualmente activos en el gimnasio.',
              'Currently active in the gym.',
            ),
          ),
          right: DashboardKpiCard(
            label: _uiText('Nuevos este mes', 'New this month'),
            value: data.members.newMembersThisMonth.toString(),
            helper: _uiText(
              'Perfiles añadidos este mes.',
              'Profiles added this month.',
            ),
          ),
        ),
        const SizedBox(height: 12),
        _twoCards(
          left: DashboardKpiCard(
            label: _uiText('Inactivos 7d', 'Inactive 7d'),
            value: data.engagement.inactive7Days.toString(),
            helper: _uiText(
              'Sin actividad reciente.',
              'Without recent activity.',
            ),
          ),
          right: DashboardKpiCard(
            label: _uiText('Inactivos 14d', 'Inactive 14d'),
            value: data.engagement.inactive14Days.toString(),
            helper: _uiText('Casos con más riesgo.', 'Higher-risk cases.'),
          ),
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
