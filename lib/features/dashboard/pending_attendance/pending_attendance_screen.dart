import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/widgets/app_card.dart';
import '../../admin/class_attendance_screen.dart';
import 'pending_attendance_models.dart';
import 'pending_attendance_repository.dart';
import 'widgets/pending_attendance_day_section.dart';
import '../../../l10n/app_text.dart';

class PendingAttendanceScreen extends StatefulWidget {
  final String? gymId;

  const PendingAttendanceScreen({super.key, this.gymId});

  @override
  State<PendingAttendanceScreen> createState() =>
      _PendingAttendanceScreenState();
}

class _PendingAttendanceScreenState extends State<PendingAttendanceScreen> {
  final _repo = PendingAttendanceRepository();

  bool _loading = true;
  String? _error;
  List<PendingAttendanceDayGroup> _groups = const [];

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
      final groups = await _repo.loadPendingAttendance(gymId: widget.gymId);
      if (!mounted) return;
      setState(() {
        _groups = groups;
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

  Future<void> _openAttendance(PendingAttendanceClassItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClassAttendanceScreen(classItem: item.classItem),
      ),
    );
    await _load();
  }

  Widget _emptyState() {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      child: Column(
        children: [
          const Icon(
            Icons.fact_check_outlined,
            size: 30,
            color: Color(0xFF98A2B3),
          ),
          const SizedBox(height: 12),
          Text(
            context.appText.noPendingAttendance,
            textAlign: TextAlign.center,
            style: _font(
              20,
              weight: FontWeight.w800,
              color: const Color(0xFF0E0E11),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.appText.allPastClassesReviewed,
            textAlign: TextAlign.center,
            style: _font(
              14,
              weight: FontWeight.w500,
              color: const Color(0xFF667085),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalClasses = _groups.fold<int>(
      0,
      (sum, group) => sum + group.classes.length,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.appText.pendingAttendanceUpper,
                            style: _font(
                              18,
                              weight: FontWeight.w800,
                              color: const Color(0xFF0E0E11),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.appText.pendingClassesToReview(
                              totalClasses,
                            ),
                            style: _font(
                              12,
                              weight: FontWeight.w500,
                              color: const Color(0xFF8F96A3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F3EA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
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
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFB59B6A),
                        ),
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
                  else if (_groups.isEmpty)
                    _emptyState()
                  else
                    ..._groups.map(
                      (group) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: PendingAttendanceDaySection(
                          group: group,
                          onTapClass: _openAttendance,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
