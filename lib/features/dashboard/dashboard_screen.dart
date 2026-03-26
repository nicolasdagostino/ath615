import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_models.dart';
import 'dashboard_repository.dart';
import 'widgets/dashboard_alert_tile.dart';
import 'widgets/dashboard_kpi_card.dart';
import 'widgets/dashboard_loading_state.dart';
import 'widgets/dashboard_section_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = DashboardRepository();
  late Future<DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.loadDashboard();
  }

  Future<void> _refresh() async {
    final next = _repo.loadDashboard();
    setState(() {
      _future = next;
    });
    await next;
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
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _alerts(List<DashboardAlertItem> alerts) {
    if (alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAECEF), width: 1),
        ),
        child: Text('No urgent alerts right now.', style: _subtitleStyle()),
      );
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

  IconData _iconForType(String type) {
    switch (type) {
      case 'birthday':
        return Icons.cake_outlined;
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text('Dashboard', style: _titleStyle()),
          const SizedBox(height: 8),
          Text(
            data.gymId == null || data.gymId!.isEmpty
                ? 'Business insights for your gym.'
                : 'Business insights for gym ${data.gymId}.',
            style: _subtitleStyle(),
          ),
          const SizedBox(height: 24),

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
