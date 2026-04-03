import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/app_text.dart';

import '../../../core/constants/app_colors.dart';
import 'athlete_history_models.dart';
import 'athlete_history_repository.dart';
import 'widgets/athlete_history_empty_state.dart';
import 'widgets/athlete_history_filter_chips.dart';
import 'widgets/athlete_history_list_item.dart';

class AthleteHistoryScreen extends StatefulWidget {
  const AthleteHistoryScreen({super.key});

  @override
  State<AthleteHistoryScreen> createState() => _AthleteHistoryScreenState();
}

class _AthleteHistoryScreenState extends State<AthleteHistoryScreen> {
  final _repo = AthleteHistoryRepository();

  bool _loading = true;
  String? _error;
  AthleteHistoryFilter _filter = AthleteHistoryFilter.all;
  List<AthleteHistoryEntry> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _repo.listMyPastHistory();
      if (!mounted) return;
      setState(() {
        _items = items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appText;
    final counts = AthleteHistoryCounts(
      total: _items.length,
      attended: _items
          .where((e) => e.status == AthleteHistoryStatus.attended)
          .length,
      missed: _items
          .where(
            (e) =>
                e.status == AthleteHistoryStatus.noShow ||
                e.status == AthleteHistoryStatus.booked,
          )
          .length,
      cancelled: _items
          .where((e) => e.status == AthleteHistoryStatus.cancelled)
          .length,
    );

    final filtered = _items.where((e) => e.matchesFilter(_filter)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          t.attendanceHistory,
          style: _font(
            22,
            weight: FontWeight.w800,
            color: const Color(0xFF0E0E11),
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: const Color(0xFF111318),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Text(
              t.pastBookingsAndAttendance,
              style: _font(
                14,
                weight: FontWeight.w500,
                color: const Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 16),
            AthleteHistoryFilterChips(
              selected: _filter,
              counts: counts,
              onChanged: (value) {
                setState(() {
                  _filter = value;
                });
              },
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFB59B6A)),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 36),
                child: Center(
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: _font(
                      15,
                      weight: FontWeight.w600,
                      color: const Color(0xFFB42318),
                    ),
                  ),
                ),
              )
            else if (filtered.isEmpty)
              AthleteHistoryEmptyState(filter: _filter)
            else
              ...filtered.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AthleteHistoryListItem(item: item),
                  )),
          ],
        ),
      ),
    );
  }
}
