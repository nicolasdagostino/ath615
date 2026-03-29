import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/supabase/gym_repository.dart';
import '../../core/supabase/notification_repository.dart';
import '../../shared/widgets/app_card.dart';

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

  void _toast(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? const Color(0xFFB42318) : null,
      ),
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
      DateTime selectedDate =
          DateTime.tryParse(scheduledCtrl.text.trim()) ?? now;

      final picked = await showModalBottomSheet<DateTime>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (dateSheetContext) {
          return SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF6F7F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: StatefulBuilder(
                  builder: (context, setDateModalState) {
                    return SingleChildScrollView(
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
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F3EA),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.event_rounded,
                                  color: Color(0xFFB59B6A),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Scheduled Date',
                                      style: _font(
                                        24,
                                        weight: FontWeight.w800,
                                        color: const Color(0xFF111318),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Choose when this announcement should be sent.',
                                      style: _font(
                                        13,
                                        weight: FontWeight.w500,
                                        color: const Color(0xFF8F96A3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => Navigator.pop(dateSheetContext),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFE8EBF0),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 22,
                                    color: Color(0xFF111318),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Select Date',
                            style: _font(
                              15,
                              weight: FontWeight.w800,
                              color: const Color(0xFF111318),
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFEAECEF),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 220,
                                  child: CupertinoTheme(
                                    data: const CupertinoThemeData(
                                      primaryColor: Color(0xFFB59B6A),
                                      textTheme: CupertinoTextThemeData(
                                        dateTimePickerTextStyle: TextStyle(
                                          color: Color(0xFF111318),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                    child: CupertinoDatePicker(
                                      mode: CupertinoDatePickerMode.date,
                                      initialDateTime: selectedDate,
                                      minimumDate: DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                      ),
                                      maximumDate: DateTime(2035, 12, 31),
                                      onDateTimeChanged: (value) {
                                        setDateModalState(() {
                                          selectedDate = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat(
                                    'd MMMM yyyy',
                                  ).format(selectedDate),
                                  style: _font(
                                    13,
                                    weight: FontWeight.w600,
                                    color: const Color(0xFF667085),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(dateSheetContext, selectedDate),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: const Color(0xFFB59B6A),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Save Changes',
                                style: _font(
                                  16,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );

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
            Future<void> save() async {
              final title = titleCtrl.text.trim();
              final message = messageCtrl.text.trim();
              if (title.isEmpty || message.isEmpty) {
                _toast('Title and message are required.', isError: true);
                return;
              }
              if (_gymId == null || _gymId!.trim().isEmpty) {
                _toast('Gym not found for this admin.', isError: true);
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
                    id: notifId,
                    type: type,
                    status: status == 'published' ? 'draft' : status,
                    title: title,
                    message: message,
                    recipientsScope: recipientsScope,
                    scheduledForIso: scheduled,
                  );
                } else {
                  notifId = await _repo.createNotification(
                    gymId: _gymId!,
                    type: type,
                    status: status == 'published' ? 'draft' : status,
                    title: title,
                    message: message,
                    recipientsScope: recipientsScope,
                    scheduledForIso: scheduled,
                  );
                }

                if (status == 'published') {
                  await _repo.publishNotification(notifId);
                }

                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                await _load();
                if (!mounted) return;
                _toast(
                  status == 'published'
                      ? (isEdit
                            ? 'Notification published.'
                            : 'Notification created & published.')
                      : (isEdit
                            ? 'Notification updated.'
                            : 'Notification created.'),
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

            return SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F7F9),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    14,
                    18,
                    18 + MediaQuery.of(sheetContext).viewInsets.bottom,
                  ),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
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
                          isEdit ? 'Edit notification' : 'New notification',
                          style: _font(
                            24,
                            weight: FontWeight.w800,
                            color: const Color(0xFF111318),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create manual announcements for your gym members.',
                          style: _font(
                            13,
                            weight: FontWeight.w500,
                            color: const Color(0xFF8F96A3),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _FieldLabel(text: 'Title'),
                        const SizedBox(height: 8),
                        _SoftTextField(
                          controller: titleCtrl,
                          hint: 'Friday dinner after the last class',
                          minLines: 1,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel(text: 'Message'),
                        const SizedBox(height: 8),
                        _SoftTextField(
                          controller: messageCtrl,
                          hint:
                              'We will have dinner after the final training session on Friday.',
                          minLines: 4,
                          maxLines: 6,
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel(text: 'Recipients'),
                        const SizedBox(height: 8),
                        _DropdownCard<String>(
                          value: recipientsScope,
                          items: const [
                            DropdownMenuItem(
                              value: 'all_users',
                              child: Text('All users'),
                            ),
                            DropdownMenuItem(
                              value: 'athletes',
                              child: Text('Athletes'),
                            ),
                            DropdownMenuItem(
                              value: 'members',
                              child: Text('Members'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setModalState(() => recipientsScope = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel(text: 'Status'),
                        const SizedBox(height: 8),
                        _DropdownCard<String>(
                          value: status,
                          items: const [
                            DropdownMenuItem(
                              value: 'draft',
                              child: Text('Draft'),
                            ),
                            DropdownMenuItem(
                              value: 'scheduled',
                              child: Text('Scheduled'),
                            ),
                            DropdownMenuItem(
                              value: 'published',
                              child: Text('Publish now'),
                            ),
                            DropdownMenuItem(
                              value: 'sent',
                              child: Text('Sent'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setModalState(() => status = value);
                          },
                        ),
                        const SizedBox(height: 14),
                        _FieldLabel(text: 'Scheduled date'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            FocusManager.instance.primaryFocus?.unfocus();
                            await pickScheduledDate();
                            setModalState(() {});
                          },
                          child: AbsorbPointer(
                            child: _SoftTextField(
                              controller: scheduledCtrl,
                              hint: 'yyyy-mm-dd',
                              minLines: 1,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _busy ? null : save,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xFFB59B6A),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              isEdit ? 'Save Changes' : 'Create Notification',
                              style: _font(
                                16,
                                weight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE11D48),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Delete'),
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
      await _repo.deleteNotification(id);
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
                    'Manage drafts and scheduled messages for your gym.',
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
                  width: 92,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB59B6A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+ Add',
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
        else
          ..._items.map((item) {
            final title = (item['title'] ?? 'Notification').toString();
            final message = (item['message'] ?? '').toString().trim();
            final status = (item['status'] ?? 'draft').toString();
            final recipients = (item['recipients_scope'] ?? 'all_users')
                .toString();

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
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title.toUpperCase(),
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
                          const SizedBox(height: 12),
                          Text(
                            'Recipients: $recipients · ${_relativeDate(item['scheduled_for']?.toString())}',
                            style: _font(
                              12,
                              weight: FontWeight.w600,
                              color: const Color(0xFF667085),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _busy
                              ? null
                              : () => _openNotificationModal(item: item),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDEBE6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _busy ? null : () => _deleteNotification(item),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDECEE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                        ),
                      ],
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

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.barlowCondensed(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF111318),
        letterSpacing: -0.1,
      ),
    );
  }
}

class _SoftTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int maxLines;

  const _SoftTextField({
    required this.controller,
    required this.hint,
    required this.minLines,
    required this.maxLines,
  });

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

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      cursorColor: const Color(0xFFB59B6A),
      style: _font(13, weight: FontWeight.w500, color: const Color(0xFF111318)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _font(
          13,
          weight: FontWeight.w500,
          color: const Color(0xFF98A2B3),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFB59B6A), width: 1.2),
        ),
      ),
    );
  }
}

class _DropdownCard<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownCard({
    required this.value,
    required this.items,
    required this.onChanged,
  });

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: _font(
            13,
            weight: FontWeight.w500,
            color: const Color(0xFF111318),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
