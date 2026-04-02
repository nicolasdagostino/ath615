import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/supabase/membership_repository.dart';
import '../../../core/supabase/notification_repository.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../class_attendance_screen.dart';
import 'admin_member_detail_models.dart';
import 'admin_member_detail_repository.dart';
import 'widgets/admin_member_activity_card.dart';
import 'widgets/admin_member_detail_header.dart';
import 'widgets/admin_member_detail_sheet_ui.dart';
import 'widgets/admin_member_membership_card.dart';
import 'widgets/admin_member_recent_history_section.dart';

class AdminMemberDetailScreen extends StatefulWidget {
  final String gymId;
  final String memberId;

  const AdminMemberDetailScreen({
    super.key,
    required this.gymId,
    required this.memberId,
  });

  @override
  State<AdminMemberDetailScreen> createState() =>
      _AdminMemberDetailScreenState();
}

class _AdminMemberDetailScreenState extends State<AdminMemberDetailScreen> {
  final _repo = AdminMemberDetailRepository();
  final _membershipRepo = MembershipRepository();
  final _notificationRepo = NotificationRepository();

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

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _repo.loadMemberDetail(
        gymId: widget.gymId,
        memberId: widget.memberId,
      );
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

  Future<void> _showAssignPlanSheet() async {
    final data = _data;
    if (data == null) return;

    final memberId = (data.profile['id'] ?? '').toString().trim();
    if (memberId.isEmpty) {
      _toast('Member not found');
      return;
    }

    final gymId = (data.profile['gym_id'] ?? '').toString().trim();
    if (gymId.isEmpty) {
      _toast('Gym not found');
      return;
    }

    List<Map<String, dynamic>> plans;
    try {
      plans = await _membershipRepo.listPlans(gymId);
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
      return;
    }

    if (plans.isEmpty) {
      _toast('No plans available yet');
      return;
    }

    var selectedPlanId = (data.activeMembership?['plan_id'] ?? '')
        .toString()
        .trim();
    if (selectedPlanId.isEmpty) {
      selectedPlanId = (plans.first['id'] ?? '').toString().trim();
    }

    final todayIso = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool saving = false;

        String prettyType(String raw) {
          final value = raw.trim();
          if (value.isEmpty) return 'Plan';
          final clean = value.replaceAll('_', ' ');
          return clean[0].toUpperCase() + clean.substring(1);
        }

        String prettyBilling(String raw) {
          final value = raw.trim();
          if (value.isEmpty) return '—';
          final clean = value.replaceAll('_', ' ');
          return clean[0].toUpperCase() + clean.substring(1);
        }

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AdminMemberDetailSheetScaffold(
              sheetContext: sheetContext,
              title: 'Assign plan',
              subtitle: 'Choose an active plan for this member.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...plans.map((plan) {
                    final planId = (plan['id'] ?? '').toString().trim();
                    final selected = planId == selectedPlanId;
                    final name = (plan['name'] ?? 'Plan').toString().trim();
                    final planType = prettyType(
                      (plan['plan_type'] ?? '').toString(),
                    );
                    final billing = prettyBilling(
                      (plan['billing_period'] ?? '').toString(),
                    );
                    final price = (plan['price'] ?? '').toString().trim();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: saving
                            ? null
                            : () {
                                setLocalState(() {
                                  selectedPlanId = planId;
                                });
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFB59B6A)
                                  : const Color(0xFFE2E8F0),
                              width: selected ? 1.4 : 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x080D1210),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: memberDetailSheetFont(
                                        17,
                                        weight: FontWeight.w800,
                                        color: const Color(0xFF111318),
                                        letterSpacing: -0.15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        planType,
                                        billing,
                                        if (price.isNotEmpty) '$price €',
                                      ].join(' · '),
                                      style: memberDetailSheetFont(
                                        13,
                                        weight: FontWeight.w500,
                                        color: const Color(0xFF667085),
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: selected
                                    ? const Color(0xFFB59B6A)
                                    : const Color(0xFF98A2B3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  AdminMemberDetailSheetActions(
                    busy: saving,
                    primaryText: 'Assign plan',
                    busyText: 'Saving...',
                    onCancel: () => Navigator.of(sheetContext).pop(),
                    onPrimary: () async {
                      if (selectedPlanId.trim().isEmpty) return;

                      FocusManager.instance.primaryFocus?.unfocus();

                      setLocalState(() {
                        saving = true;
                      });

                      try {
                        await _membershipRepo.assignPlanToMember(
                          memberId: memberId,
                          planId: selectedPlanId.trim(),
                          status: 'active',
                          startDate: todayIso,
                          autoRenew: true,
                        );
                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop();
                        await _load();
                        _toast('Plan assigned');
                      } catch (e) {
                        _toast(e.toString().replaceFirst('Exception: ', ''));
                      } finally {
                        if (sheetContext.mounted) {
                          setLocalState(() {
                            saving = false;
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  AdminMemberHistoryItem? _preferredAttendanceHistoryItem() {
    final data = _data;
    if (data == null || data.recentHistory.isEmpty) return null;

    final now = DateTime.now();

    for (final item in data.recentHistory) {
      final startsAt = item.startsAt;
      if (startsAt == null) continue;
      if (!startsAt.isBefore(now)) continue;
      if (item.status == 'booked') return item;
    }

    for (final item in data.recentHistory) {
      final startsAt = item.startsAt;
      if (startsAt == null) continue;
      if (!startsAt.isBefore(now)) continue;
      return item;
    }

    return null;
  }

  Future<Map<String, dynamic>?> _loadClassItemForAttendance(
    String classId,
  ) async {
    final trimmed = classId.trim();
    if (trimmed.isEmpty) return null;

    final fromView = await sb
        .from('v_classes_with_spots')
        .select('*')
        .eq('id', trimmed)
        .maybeSingle();

    if (fromView != null) {
      return Map<String, dynamic>.from(fromView);
    }

    final fromClasses = await sb
        .from('classes')
        .select(
          'id, title, starts_at, duration_minutes, location, status, program_id, coach_id',
        )
        .eq('id', trimmed)
        .maybeSingle();

    if (fromClasses == null) return null;
    return Map<String, dynamic>.from(fromClasses);
  }

  Future<void> _openAttendanceAction() async {
    final item = _preferredAttendanceHistoryItem();
    if (item == null) {
      _toast('No past classes available for attendance');
      return;
    }

    try {
      final classItem = await _loadClassItemForAttendance(item.classId);
      if (classItem == null) {
        _toast('Could not load class attendance');
        return;
      }

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ClassAttendanceScreen(
            classItem: classItem,
            gymId: widget.gymId,
          ),
        ),
      );
      await _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _showNotifySheet() async {
    final data = _data;
    if (data == null) return;

    final memberId = (data.profile['id'] ?? '').toString().trim();
    final gymId = (data.profile['gym_id'] ?? '').toString().trim();
    final memberName = (data.profile['full_name'] ?? 'Member')
        .toString()
        .trim();

    if (memberId.isEmpty || gymId.isEmpty) {
      _toast('Member notification is not available');
      return;
    }

    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool sending = false;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AdminMemberDetailSheetScaffold(
              sheetContext: sheetContext,
              title: 'Notify member',
              subtitle: memberName.isEmpty
                  ? 'Send a direct push notification only to this member.'
                  : 'Send a direct push notification only to $memberName.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminMemberDetailSheetTextField(
                    controller: titleCtrl,
                    label: 'Title',
                    hint: 'Class update',
                    textInputAction: TextInputAction.next,
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                  const SizedBox(height: 12),
                  AdminMemberDetailSheetTextField(
                    controller: messageCtrl,
                    label: 'Message',
                    hint: 'Write a short message',
                    minLines: 4,
                    maxLines: 5,
                    textInputAction: TextInputAction.done,
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                  const SizedBox(height: 18),
                  AdminMemberDetailSheetActions(
                    busy: sending,
                    primaryText: 'Send notification',
                    busyText: 'Sending...',
                    onCancel: () => Navigator.of(sheetContext).pop(),
                    onPrimary: () async {
                      final title = titleCtrl.text.trim();
                      final message = messageCtrl.text.trim();

                      if (title.isEmpty || message.isEmpty) {
                        _toast('Title and message are required');
                        return;
                      }

                      FocusManager.instance.primaryFocus?.unfocus();

                      setLocalState(() {
                        sending = true;
                      });

                      try {
                        final notificationId = await _notificationRepo
                            .createNotification(
                              gymId: gymId,
                              type: 'announcement',
                              title: title,
                              message: message,
                              recipientsScope: 'all_users',
                              status: 'draft',
                              metadata: {
                                'pushType': 'member_direct_message',
                                'targetMemberId': memberId,
                              },
                            );

                        await _notificationRepo.publishNotification(
                          notificationId,
                        );

                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                        _toast('Notification sent');
                      } catch (e) {
                        _toast(e.toString().replaceFirst('Exception: ', ''));
                      } finally {
                        if (sheetContext.mounted) {
                          setLocalState(() {
                            sending = false;
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditActiveMembershipSheet() async {
    final data = _data;
    final membership = data?.activeMembership;
    if (data == null || membership == null) {
      _toast('No active membership to edit');
      return;
    }

    final membershipId = (membership['id'] ?? '').toString().trim();

    final endDateCtrl = TextEditingController(
      text: (membership['end_date'] ?? '').toString(),
    );
    final creditsCtrl = TextEditingController(
      text: (membership['credits_remaining'] ?? '').toString(),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool saving = false;
        bool autoRenew = membership['auto_renew'] == true;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AdminMemberDetailSheetScaffold(
              sheetContext: sheetContext,
              title: 'Membership',
              subtitle: 'Adjust membership settings.',
              child: Column(
                children: [
                  AdminMemberDetailSheetTextField(
                    controller: endDateCtrl,
                    label: 'End date',
                  ),
                  const SizedBox(height: 12),
                  AdminMemberDetailSheetTextField(
                    controller: creditsCtrl,
                    label: 'Credits remaining',
                  ),
                  const SizedBox(height: 12),
                  AdminMemberDetailSheetSwitchCard(
                    title: 'Auto-renew',
                    subtitle: 'Renew automatically',
                    value: autoRenew,
                    onChanged: saving
                        ? null
                        : (v) => setLocalState(() => autoRenew = v),
                  ),
                  const SizedBox(height: 18),
                  AdminMemberDetailSheetActions(
                    busy: saving,
                    primaryText: 'Save',
                    busyText: 'Saving...',
                    onCancel: () => Navigator.pop(sheetContext),
                    onPrimary: () async {
                      setLocalState(() => saving = true);

                      try {
                        await _membershipRepo.updateMemberMembership(
                          membershipId: membershipId,
                          endDate: endDateCtrl.text,
                          autoRenew: autoRenew,
                        );
                        if (!sheetContext.mounted) return;
                        Navigator.pop(sheetContext);
                        await _load();
                      } finally {
                        if (sheetContext.mounted) {
                          setLocalState(() => saving = false);
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditMemberSheet() async {
    final data = _data;
    if (data == null) return;

    final memberId = (data.profile['id'] ?? '').toString().trim();
    if (memberId.isEmpty) {
      _toast('Member not found');
      return;
    }

    final fullNameCtrl = TextEditingController(
      text: (data.profile['full_name'] ?? '').toString(),
    );
    final emailCtrl = TextEditingController(
      text: (data.profile['email'] ?? '').toString(),
    );
    final phoneCtrl = TextEditingController(
      text: (data.profile['phone'] ?? '').toString(),
    );
    final notesCtrl = TextEditingController(
      text: (data.profile['notes'] ?? '').toString(),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool saving = false;
        bool isActive = data.profile['is_active'] == true;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AdminMemberDetailSheetScaffold(
              sheetContext: sheetContext,
              title: 'Edit member',
              subtitle: 'Update member profile details.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminMemberDetailSheetTextField(
                    controller: fullNameCtrl,
                    label: 'Full name',
                    hint: 'John Doe',
                  ),
                  const SizedBox(height: 12),
                  AdminMemberDetailSheetTextField(
                    controller: emailCtrl,
                    label: 'Email',
                    hint: 'john@email.com',
                  ),
                  const SizedBox(height: 12),
                  AdminMemberDetailSheetTextField(
                    controller: phoneCtrl,
                    label: 'Phone',
                    hint: '+34 600 000 000',
                  ),
                  const SizedBox(height: 12),
                  AdminMemberDetailSheetTextField(
                    controller: notesCtrl,
                    label: 'Notes',
                    hint: 'Optional notes',
                    minLines: 3,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  AdminMemberDetailSheetSwitchCard(
                    title: 'Active member',
                    subtitle: 'Allow access to the app after password setup',
                    value: isActive,
                    onChanged: saving
                        ? null
                        : (value) {
                            setLocalState(() {
                              isActive = value;
                            });
                          },
                  ),
                  const SizedBox(height: 18),
                  AdminMemberDetailSheetActions(
                    busy: saving,
                    primaryText: 'Save changes',
                    busyText: 'Saving...',
                    onCancel: () => Navigator.of(sheetContext).pop(),
                    onPrimary: () async {
                      if (fullNameCtrl.text.trim().isEmpty) {
                        _toast('Full name is required');
                        return;
                      }

                      setLocalState(() => saving = true);

                      try {
                        final memberGymId =
                            (data.profile['gym_id'] ?? '').toString().trim();
                        if (memberGymId.isEmpty) {
                          throw Exception('Gym not found');
                        }

                        await _repo.updateMemberProfile(
                          gymId: memberGymId,
                          memberId: memberId,
                          fullName: fullNameCtrl.text,
                          email: emailCtrl.text,
                          phone: phoneCtrl.text,
                          notes: notesCtrl.text,
                          isActive: isActive,
                        );
                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop();
                        await _load();
                        _toast('Member updated');
                      } finally {
                        if (sheetContext.mounted) {
                          setLocalState(() => saving = false);
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _quickActions() {
    Widget action({
      required String title,
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEFF1F4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080D1210),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFFB59B6A)),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: _font(
                  13,
                  weight: FontWeight.w800,
                  color: const Color(0xFF111318),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: _font(
            12,
            weight: FontWeight.w700,
            color: const Color(0xFF98A2B3),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: action(
                title: 'Assign plan',
                icon: Icons.credit_card_outlined,
                onTap: _showAssignPlanSheet,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: action(
                title: 'Attendance',
                icon: Icons.check_circle_outline,
                onTap: _openAttendanceAction,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: action(
                title: 'Notify',
                icon: Icons.notifications_outlined,
                onTap: _showNotifySheet,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: action(
                title: 'Edit',
                icon: Icons.edit_outlined,
                onTap: _showEditMemberSheet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: action(
                title: 'Membership',
                icon: Icons.workspace_premium_outlined,
                onTap: _showEditActiveMembershipSheet,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
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
                  else if (data != null) ...[
                    _quickActions(),
                    const SizedBox(height: 18),
                    AdminMemberDetailHeader(profile: data.profile),
                    const SizedBox(height: 14),
                    AdminMemberMembershipCard(
                      membership: data.activeMembership,
                    ),
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
