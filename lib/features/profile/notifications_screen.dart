import 'package:flutter/material.dart';
import '../../shared/widgets/app_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF05070B),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2030),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF245BEB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '2 new',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: const [
                _NotificationCard(
                  icon: Icons.calendar_today_outlined,
                  iconBg: Color(0xFFDCE8F8),
                  iconColor: Color(0xFF245BEB),
                  title: 'Class Reminder',
                  subtitle: 'Your CrossFit class starts in 30 minutes',
                  time: '30 min ago',
                  unread: true,
                ),
                SizedBox(height: 12),
                _NotificationCard(
                  icon: Icons.emoji_events_outlined,
                  iconBg: Color(0xFFF7E9B8),
                  iconColor: Color(0xFFD18B00),
                  title: 'New Personal Record!',
                  subtitle: 'You set a new PR for Back Squat: 315 lbs',
                  time: '2 hours ago',
                  unread: true,
                ),
                SizedBox(height: 12),
                _NotificationCard(
                  icon: Icons.mode_comment_outlined,
                  iconBg: Color(0xFFDDF5E5),
                  iconColor: Color(0xFF16A34A),
                  title: 'New Comment',
                  subtitle: 'Sarah commented on your workout: "Great job! 🔥"',
                  time: '4 hours ago',
                ),
                SizedBox(height: 12),
                _NotificationCard(
                  icon: Icons.group_outlined,
                  iconBg: Color(0xFFEDE4FF),
                  iconColor: Color(0xFF9333EA),
                  title: 'Mike Johnson',
                  subtitle: 'Started following you',
                  time: '1 day ago',
                ),
                SizedBox(height: 12),
                _NotificationCard(
                  icon: Icons.calendar_today_outlined,
                  iconBg: Color(0xFFDCE8F8),
                  iconColor: Color(0xFF245BEB),
                  title: 'Class Cancelled',
                  subtitle:
                      "Tomorrow's 6:00 AM CrossFit class has been cancelled",
                  time: '1 day ago',
                ),
                SizedBox(height: 12),
                _NotificationCard(
                  icon: Icons.emoji_events_outlined,
                  iconBg: Color(0xFFF7E9B8),
                  iconColor: Color(0xFFD18B00),
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

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D0D12),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.28,
                    color: Color(0xFF475467),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.28,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
          if (unread)
            const Padding(
              padding: EdgeInsets.only(left: 10, top: 8),
              child: Icon(Icons.circle, size: 10, color: Color(0xFF245BEB)),
            ),
        ],
      ),
    );
  }
}
