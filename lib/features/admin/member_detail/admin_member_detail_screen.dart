import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'admin_member_detail_models.dart';
import 'admin_member_detail_repository.dart';
import 'widgets/admin_member_activity_card.dart';
import 'widgets/admin_member_detail_header.dart';
import 'widgets/admin_member_membership_card.dart';
import 'widgets/admin_member_recent_history_section.dart';

class AdminMemberDetailScreen extends StatefulWidget {
  final String memberId;

  const AdminMemberDetailScreen({super.key, required this.memberId});

  @override
  State<AdminMemberDetailScreen> createState() => _AdminMemberDetailScreenState();
}

class _AdminMemberDetailScreenState extends State<AdminMemberDetailScreen> {
  final _repo = AdminMemberDetailRepository();

  bool _loading = true;
  String? _error;
  AdminMemberDetailData? _data;

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
      final data = await _repo.loadMemberDetail(widget.memberId);
      if (!mounted) return;
      setState(() {
        _data = data;
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
    final data = _data;

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
                      child: Text(
                        'MEMBER DETAIL',
                        style: _font(
                          18,
                          weight: FontWeight.w800,
                          color: const Color(0xFF0E0E11),
                          letterSpacing: -0.3,
                        ),
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
                  else if (data != null) ...[
                    AdminMemberDetailHeader(profile: data.profile),
                    const SizedBox(height: 14),
                    AdminMemberMembershipCard(membership: data.activeMembership),
                    const SizedBox(height: 14),
                    AdminMemberActivityCard(activity: data.activity),
                    const SizedBox(height: 14),
                    AdminMemberRecentHistorySection(items: data.recentHistory),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
