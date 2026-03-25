import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/widgets/app_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
                              'NOTIFICATIONS',
                              style: _font(
                                17,
                                weight: FontWeight.w800,
                                color: const Color(0xFF0E0E11),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'PROFILE',
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F3EA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEADFCB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                        color: Color(0xFFB59B6A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '2 unread notifications',
                        style: _font(
                          13,
                          weight: FontWeight.w700,
                          color: const Color(0xFF8A6C3F),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const _NotificationCard(
                  icon: Icons.calendar_today_outlined,
                  iconBg: Color(0xFFF7F3EA),
                  iconColor: Color(0xFFB59B6A),
                  title: 'Class Reminder',
                  subtitle: 'Your CrossFit class starts in 30 minutes',
                  time: '30 min ago',
                  unread: true,
                ),
                const SizedBox(height: 12),
                const _NotificationCard(
                  icon: Icons.emoji_events_outlined,
                  iconBg: Color(0xFFF7F3EA),
                  iconColor: Color(0xFFB59B6A),
                  title: 'New Personal Record!',
                  subtitle: 'You set a new PR for Back Squat: 315 lbs',
                  time: '2 hours ago',
                  unread: true,
                ),
                const SizedBox(height: 12),
                const _NotificationCard(
                  icon: Icons.mode_comment_outlined,
                  iconBg: Color(0xFFF8FAFC),
                  iconColor: Color(0xFF667085),
                  title: 'New Comment',
                  subtitle: 'Sarah commented on your workout: "Great job! 🔥"',
                  time: '4 hours ago',
                ),
                const SizedBox(height: 12),
                const _NotificationCard(
                  icon: Icons.group_outlined,
                  iconBg: Color(0xFFF8FAFC),
                  iconColor: Color(0xFF667085),
                  title: 'Mike Johnson',
                  subtitle: 'Started following you',
                  time: '1 day ago',
                ),
                const SizedBox(height: 12),
                const _NotificationCard(
                  icon: Icons.calendar_today_outlined,
                  iconBg: Color(0xFFF8FAFC),
                  iconColor: Color(0xFF667085),
                  title: 'Class Cancelled',
                  subtitle:
                      "Tomorrow's 6:00 AM CrossFit class has been cancelled",
                  time: '1 day ago',
                ),
                const SizedBox(height: 12),
                const _NotificationCard(
                  icon: Icons.emoji_events_outlined,
                  iconBg: Color(0xFFF8FAFC),
                  iconColor: Color(0xFF667085),
                  title: 'Milestone Unlocked',
                  subtitle: "You've completed 100 classes! Keep it up! 🎯",
                  time: '2 days ago',
                ),
              ],
            ),
          ),
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
