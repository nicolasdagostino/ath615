import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/supabase/notification_repository.dart';
import '../../l10n/app_text.dart';
import '../../shared/widgets/app_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = NotificationRepository();

  bool _loading = true;
  bool _busy = false;
  String? _error;
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
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final rows = await _repo.myNotifications();
      if (!mounted) return;
      setState(() {
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

  Future<void> _markRead(Map<String, dynamic> item) async {
    final id = (item['id'] ?? '').toString().trim();
    final isRead = item['is_read'] == true;
    if (id.isEmpty || isRead || _busy) return;

    setState(() {
      _busy = true;
    });

    try {
      await _repo.markAsRead(id);
      if (!mounted) return;
      setState(() {
        _items = _items.map((row) {
          final sameId = (row['id'] ?? '').toString() == id;
          if (!sameId) return row;
          final updated = Map<String, dynamic>.from(row);
          updated['is_read'] = true;
          updated['read_at'] = DateTime.now().toIso8601String();
          return updated;
        }).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  int get _unreadCount =>
      _items.where((item) => item['is_read'] != true).length;

  String _timeLabel(BuildContext context, String? raw) {
    final t = context.appText;
    final parsed = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return t.justNow;

    final diff = DateTime.now().difference(parsed);
    if (diff.inMinutes < 1) return t.justNow;
    if (diff.inMinutes < 60) return t.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return t.hoursAgo(diff.inHours);
    if (diff.inDays == 1) return t.oneDayAgo;
    if (diff.inDays < 7) return t.daysAgo(diff.inDays);
    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'birthday':
        return Icons.cake_outlined;
      case 'milestone':
      case 'milestone_reached':
        return Icons.emoji_events_outlined;
      case 'class_reminder':
        return Icons.calendar_today_outlined;
      case 'workout_published':
      case 'workout':
        return Icons.fitness_center_outlined;
      case 'comment':
        return Icons.mode_comment_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconBgForType(String type, bool unread) {
    if (unread) return const Color(0xFFF7F3EA);
    return const Color(0xFFF8FAFC);
  }

  Color _iconColorForType(String type, bool unread) {
    if (unread) return const Color(0xFFB59B6A);
    return const Color(0xFF667085);
  }

  String _title(BuildContext context, Map<String, dynamic> item) {
    final notification = Map<String, dynamic>.from(
      (item['notifications'] as Map?) ?? const {},
    );
    final value = (notification['title'] ?? '').toString().trim();
    return value.isEmpty ? context.appText.notification : value;
  }

  String _message(BuildContext context, Map<String, dynamic> item) {
    final notification = Map<String, dynamic>.from(
      (item['notifications'] as Map?) ?? const {},
    );
    final value = (notification['message'] ?? '').toString().trim();
    return value.isEmpty ? context.appText.noDetailsAvailable : value;
  }

  String _type(Map<String, dynamic> item) {
    final notification = Map<String, dynamic>.from(
      (item['notifications'] as Map?) ?? const {},
    );
    return (notification['type'] ?? '').toString().trim().toLowerCase();
  }

  Widget _summaryCard(BuildContext context) {
    final t = context.appText;
    final unread = _unreadCount;
    final hasUnread = unread > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasUnread ? const Color(0xFFF7F3EA) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasUnread ? const Color(0xFFEADFCB) : const Color(0xFFE7ECF2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasUnread
                ? Icons.notifications_active_outlined
                : Icons.notifications_none_outlined,
            size: 18,
            color: hasUnread
                ? const Color(0xFFB59B6A)
                : const Color(0xFF667085),
          ),
          const SizedBox(width: 8),
          Text(
            hasUnread ? t.unreadNotifications(unread) : t.allCaughtUp,
            style: _font(
              13,
              weight: FontWeight.w700,
              color: hasUnread
                  ? const Color(0xFF8A6C3F)
                  : const Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final t = context.appText;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.noNotificationsYet,
            style: _font(
              20,
              weight: FontWeight.w800,
              color: const Color(0xFF111318),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.notificationsEmptySubtitle,
            style: _font(
              14,
              weight: FontWeight.w500,
              color: const Color(0xFF667085),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context) {
    final t = context.appText;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.couldNotLoadNotifications,
            style: _font(
              20,
              weight: FontWeight.w800,
              color: const Color(0xFF111318),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _error ?? t.unknownError,
            style: _font(
              14,
              weight: FontWeight.w500,
              color: const Color(0xFF667085),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _load, child: Text(t.retry)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          _summaryCard(context),
          const SizedBox(height: 14),
          if (_error != null)
            _errorState(context)
          else if (_items.isEmpty)
            _emptyState(context)
          else
            ...List.generate(_items.length, (index) {
              final item = _items[index];
              final unread = item['is_read'] != true;
              final type = _type(item);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == _items.length - 1 ? 0 : 12,
                ),
                child: GestureDetector(
                  onTap: () => _markRead(item),
                  child: _NotificationCard(
                    icon: _iconForType(type),
                    iconBg: _iconBgForType(type, unread),
                    iconColor: _iconColorForType(type, unread),
                    title: _title(context, item),
                    subtitle: _message(context, item),
                    time: _timeLabel(
                      context,
                      (item['created_at'] ?? item['read_at'])?.toString(),
                    ),
                    unread: unread,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                child: SizedBox(
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: SizedBox(
                          width: 132,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                size: 28,
                                color: Color(0xFFB59B6A),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.appText.notificationsUpper,
                              style: _font(
                                17,
                                weight: FontWeight.w800,
                                color: const Color(0xFF0E0E11),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.appText.profileUpper,
                              style: _font(
                                11,
                                weight: FontWeight.w500,
                                color: const Color(0xFF8F96A3),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final bool unread;

  const _NotificationCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    this.unread = false,
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
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: _font(
                          18,
                          weight: FontWeight.w800,
                          color: const Color(0xFF111318),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFB59B6A),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: _font(
                    14,
                    weight: FontWeight.w500,
                    color: const Color(0xFF667085),
                    letterSpacing: -0.1,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: _font(
                    12,
                    weight: FontWeight.w600,
                    color: const Color(0xFF98A2B3),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
