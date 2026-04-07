import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_text.dart';
import 'widgets/admin_notification_editor_sheet.dart';
import '../../core/supabase/gym_repository.dart';
import '../../core/supabase/notification_repository.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/secondary_button.dart';
import 'widgets/admin_notification_date_sheet.dart';
import '../../shared/widgets/app_toast.dart';

class AdminNotificationsTab extends StatefulWidget {
  const AdminNotificationsTab({super.key});

  @override
  State<AdminNotificationsTab> createState() => _AdminNotificationsTabState();
}

class _AdminNotificationsTabState extends State<AdminNotificationsTab> {
  final _repo = NotificationRepository();
  final _gymRepo = GymRepository();

  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _gymId;
  List<Map<String, dynamic>> _items = [];
  String _selectedFilter = 'all';

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
      final gymId = await _gymRepo.resolveGymId();
      final rows = await _repo.adminNotifications(gymId: gymId);
      if (!mounted) return;
      setState(() {
        _gymId = gymId;
        _items = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _toast(
    String text, {
    bool isError = false,
    IconData? icon,
  }) {
    if (!mounted) return;

    AppToast.show(
      context,
      text,
      isError: isError,
      icon: icon,
    );
  }

  Future<void> _openNotificationModal({Map<String, dynamic>? item}) async {
    final isEdit = item != null;
    final titleCtrl = TextEditingController(
      text: item?['title']?.toString() ?? '',
    );
    final messageCtrl = TextEditingController(
      text: item?['message']?.toString() ?? '',
    );
    final scheduledCtrl = TextEditingController(
      text: _dateFieldValue(item?['scheduled_for']?.toString()),
    );

    const String type = 'announcement';
    String status = (item?['status'] ?? 'draft').toString();
    String recipientsScope = (item?['recipients_scope'] ?? 'all_users')
        .toString();

    Future<void> pickScheduledDate() async {
      final now = DateTime.now();
      final initial = DateTime.tryParse(scheduledCtrl.text.trim()) ?? now;

      final picked = await AdminNotificationDateSheet.pick(context, initial);

      if (picked != null) {
        scheduledCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final t = context.appText;

            Future<void> saveWithStatus({
              required String targetStatus,
              required bool publishAfterSave,
            }) async {
              final title = titleCtrl.text.trim();
              final message = messageCtrl.text.trim();
              if (title.isEmpty || message.isEmpty) {
                _toast(t.titleAndMessageRequiredShort, isError: true);
                return;
              }
              if (_gymId == null || _gymId!.trim().isEmpty) {
                _toast(t.adminGymMissing, isError: true);
                return;
              }

              setState(() => _busy = true);
              try {
                final scheduled = scheduledCtrl.text.trim().isEmpty
                    ? null
                    : '${scheduledCtrl.text.trim()}T09:00:00';

                late final String notifId;

                if (isEdit) {
                  notifId = item['id'].toString();
                  await _repo.updateNotification(
                    gymId: _gymId!,
                    id: notifId,
                    type: type,
                    status: targetStatus,
                    title: title,
                    message: message,
                    recipientsScope: recipientsScope,
                    scheduledForIso: scheduled,
                  );
                } else {
                  notifId = await _repo.createNotification(
                    gymId: _gymId!,
                    type: type,
                    status: targetStatus,
                    title: title,
                    message: message,
                    recipientsScope: recipientsScope,
                    scheduledForIso: scheduled,
                  );
                }

                if (publishAfterSave) {
                  await _repo.publishNotification(notifId);
                }

                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                await _load();
                if (!mounted) return;
                _toast(
                  publishAfterSave
                      ? (isEdit
                            ? t.publishedNow
                            : t.createdAndPublished)
                      : (isEdit
                            ? t.savedDraft
                            : t.createdDraft),
                );
              } catch (e) {
                _toast(
                  e.toString().replaceFirst('Exception: ', ''),
                  isError: true,
                );
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            }

            final effectivePrimaryLabel = status == 'published'
                ? t.publishNow
                : t.saveChanges;

            return AdminNotificationEditorSheet(
              isEdit: isEdit,
              titleCtrl: titleCtrl,
              messageCtrl: messageCtrl,
              scheduledCtrl: scheduledCtrl,
              status: status,
              recipientsScope: recipientsScope,
              busy: _busy,
              onPickDate: () async {
                FocusManager.instance.primaryFocus?.unfocus();
                await pickScheduledDate();
                setModalState(() {});
              },
              onSaveDraft: () async {
                await saveWithStatus(
                  targetStatus: 'draft',
                  publishAfterSave: false,
                );
              },
              onPrimaryAction: () async {
                if (status == 'published') {
                  await saveWithStatus(
                    targetStatus: 'draft',
                    publishAfterSave: true,
                  );
                } else {
                  await saveWithStatus(
                    targetStatus: status == 'sent' ? 'draft' : status,
                    publishAfterSave: false,
                  );
                }
              },
              primaryLabel: effectivePrimaryLabel,
              onStatusChanged: (value) {
                setModalState(() => status = value);
              },
              onRecipientsChanged: (value) {
                setModalState(() => recipientsScope = value);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showNotificationActions(Map<String, dynamic> item) async {
    final status = (item['status'] ?? 'draft').toString();
    final canPublish = status == 'draft' || status == 'scheduled';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        Widget actionTile({
          required IconData icon,
          required Color iconColor,
          required String title,
          required String subtitle,
          required VoidCallback onTap,
        }) {
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECF1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: _font(
                            16,
                            weight: FontWeight.w800,
                            color: const Color(0xFF111318),
                            letterSpacing: -0.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: _font(
                            12,
                            weight: FontWeight.w500,
                            color: const Color(0xFF667085),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF6F7F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD7DBE1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Notification actions',
                      style: _font(
                        22,
                        weight: FontWeight.w800,
                        color: const Color(0xFF111318),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage this message without leaving the list.',
                      style: _font(
                        13,
                        weight: FontWeight.w500,
                        color: const Color(0xFF667085),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    actionTile(
                      icon: Icons.edit_outlined,
                      iconColor: const Color(0xFF6B7280),
                      title: 'Edit notification',
                      subtitle: 'Update title, message, audience or schedule.',
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await _openNotificationModal(item: item);
                      },
                    ),
                    if (canPublish) ...[
                      const SizedBox(height: 10),
                      actionTile(
                        icon: Icons.send_rounded,
                        iconColor: const Color(0xFFB59B6A),
                        title: 'Publish now',
                        subtitle: 'Send this notification immediately.',
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          await _publishNow(item);
                        },
                      ),
                    ],
                    const SizedBox(height: 10),
                    actionTile(
                      icon: Icons.delete_outline,
                      iconColor: const Color(0xFFE11D48),
                      title: 'Delete notification',
                      subtitle: 'Remove this notification from the admin list.',
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await _deleteNotification(item);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteNotification(Map<String, dynamic> item) async {
    final id = (item['id'] ?? '').toString().trim();
    if (id.isEmpty) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF6F7F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Delete notification?',
                    style: _font(
                      24,
                      weight: FontWeight.w800,
                      color: const Color(0xFF111318),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This draft will be removed from your gym notifications.',
                    textAlign: TextAlign.center,
                    style: _font(
                      13,
                      weight: FontWeight.w500,
                      color: const Color(0xFF8F96A3),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          text: context.appText.cancel,
                          compact: true,
                          radius: 16,
                          textStyle: _font(
                            16,
                            weight: FontWeight.w700,
                            color: const Color(0xFF344054),
                            letterSpacing: -0.15,
                          ),
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          text: context.appText.delete,
                          compact: true,
                          radius: 16,
                          backgroundColor: const Color(0xFFE11D48),
                          pressedColor: const Color(0xFFC81E44),
                          disabledColor: const Color(0xFFF1A9B8),
                          textColor: Colors.white,
                          textStyle: _font(
                            16,
                            weight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.15,
                          ),
                          boxShadow: const [],
                          onPressed: () => Navigator.of(sheetContext).pop(true),
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

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await _repo.deleteNotification(gymId: _gymId!, id: id);
      await _load();
      _toast('Notification deleted.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _dateFieldValue(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '';
    final dt = DateTime.tryParse(iso.trim());
    if (dt == null) return '';
    return DateFormat('yyyy-MM-dd').format(dt.toLocal());
  }

  String _relativeDate(String? iso) {
    if (iso == null || iso.trim().isEmpty) return 'No date';
    final dt = DateTime.tryParse(iso.trim())?.toLocal();
    if (dt == null) return 'No date';
    return DateFormat('d MMM yyyy · HH:mm').format(dt);
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'scheduled':
        return const Color(0xFFEFF4FB);
      case 'sent':
        return const Color(0xFFEAF7EE);
      default:
        return const Color(0xFFF7F3EA);
    }
  }

  Color _statusFg(String status) {
    switch (status) {
      case 'scheduled':
        return const Color(0xFF064BB3);
      case 'sent':
        return const Color(0xFF157347);
      default:
        return const Color(0xFFB59B6A);
    }
  }

  String _filterLabel(String value) {
    switch (value) {
      case 'draft':
        return 'Draft';
      case 'scheduled':
        return 'Scheduled';
      case 'sent':
        return 'Sent';
      default:
        return 'All';
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedFilter == 'all') return _items;
    return _items
        .where(
          (item) => (item['status'] ?? '').toString().trim() == _selectedFilter,
        )
        .toList();
  }

  Future<void> _publishNow(Map<String, dynamic> item) async {
    final id = (item['id'] ?? '').toString().trim();
    if (id.isEmpty) return;

    setState(() => _busy = true);
    try {
      await _repo.publishNotification(id);
      await _load();
      _toast('Notification published.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _filterChip(String value) {
    final selected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF7F3EA) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFB59B6A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          _filterLabel(value).toUpperCase(),
          style: _font(
            11,
            weight: FontWeight.w800,
            color: selected ? const Color(0xFFB59B6A) : const Color(0xFF667085),
            letterSpacing: 0.35,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEFF1F4)),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3EA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFFB59B6A),
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: _font(
              18,
              weight: FontWeight.w800,
              color: const Color(0xFF111318),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first message for milestones, birthdays, workouts or reminders.',
            textAlign: TextAlign.center,
            style: _font(
              13,
              weight: FontWeight.w500,
              color: const Color(0xFF8F96A3),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _filteredItems;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: _font(
                      24,
                      weight: FontWeight.w800,
                      color: const Color(0xFF111318),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage drafts, scheduled messages and instant announcements for your gym.',
                    style: _font(
                      13,
                      weight: FontWeight.w500,
                      color: const Color(0xFF8F96A3),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _busy ? null : () => _openNotificationModal(),
              child: Opacity(
                opacity: _busy ? 0.6 : 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB59B6A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'New notification',
                    style: _font(
                      15,
                      weight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.05,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('all'),
              const SizedBox(width: 8),
              _filterChip('draft'),
              const SizedBox(width: 8),
              _filterChip('scheduled'),
              const SizedBox(width: 8),
              _filterChip('sent'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEAECEF)),
            ),
            child: Text(
              _error!,
              style: _font(
                13,
                weight: FontWeight.w500,
                color: const Color(0xFFB42318),
                height: 1.45,
              ),
            ),
          )
        else if (_items.isEmpty)
          _emptyState()
        else if (visibleItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFEFF1F4)),
            ),
            child: Column(
              children: [
                Text(
                  'No ${_filterLabel(_selectedFilter).toLowerCase()} notifications',
                  style: _font(
                    18,
                    weight: FontWeight.w800,
                    color: const Color(0xFF111318),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Try another filter or create a new message.',
                  textAlign: TextAlign.center,
                  style: _font(
                    13,
                    weight: FontWeight.w500,
                    color: const Color(0xFF8F96A3),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          )
        else
          ...visibleItems.map((item) {
            final title = (item['title'] ?? 'Notification').toString().trim();
            final message = (item['message'] ?? '').toString().trim();
            final status = (item['status'] ?? 'draft').toString();
            final recipients = (item['recipients_scope'] ?? 'all_users')
                .toString();
            final canPublish = status == 'draft' || status == 'scheduled';

            String recipientsLabel;
            switch (recipients) {
              case 'athletes':
                recipientsLabel = 'Athletes';
                break;
              case 'members':
                recipientsLabel = 'Members';
                break;
              default:
                recipientsLabel = 'All users';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F3EA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.campaign_outlined,
                        color: Color(0xFFB59B6A),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusBg(status),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: _font(
                                    10,
                                    weight: FontWeight.w800,
                                    color: _statusFg(status),
                                    letterSpacing: 0.35,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F3EA),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  recipientsLabel.toUpperCase(),
                                  style: _font(
                                    10,
                                    weight: FontWeight.w800,
                                    color: const Color(0xFFB59B6A),
                                    letterSpacing: 0.35,
                                  ),
                                ),
                              ),
                              if ((item['scheduled_for'] ?? '')
                                  .toString()
                                  .trim()
                                  .isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _relativeDate(
                                      item['scheduled_for']?.toString(),
                                    ).toUpperCase(),
                                    style: _font(
                                      10,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFF667085),
                                      letterSpacing: 0.35,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            style: _font(
                              19,
                              weight: FontWeight.w800,
                              color: const Color(0xFF111318),
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (message.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              message,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: _font(
                                13,
                                weight: FontWeight.w500,
                                color: const Color(0xFF8F96A3),
                                height: 1.4,
                              ),
                            ),
                          ],
                          if (canPublish) ...[
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _busy ? null : () => _publishNow(item),
                              child: Opacity(
                                opacity: _busy ? 0.6 : 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F3EA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE8D9B5),
                                    ),
                                  ),
                                  child: Text(
                                    'Publish now',
                                    style: _font(
                                      13,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFFB59B6A),
                                      letterSpacing: -0.08,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _busy
                          ? null
                          : () => _showNotificationActions(item),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDEBE6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.more_horiz_rounded,
                          size: 20,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}



