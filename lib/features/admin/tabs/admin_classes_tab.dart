import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminClassesTab extends StatelessWidget {
  final bool loading;
  final List classes;
  final bool adminActionBusy;
  final VoidCallback onAdd;
  final VoidCallback? onRecurring;
  final Function(Map<String, dynamic>) onEdit;
  final Function(Map<String, dynamic>) onActions;
  final TextStyle Function(
    double size, {
    FontWeight weight,
    Color color,
    double letterSpacing,
    double height,
  })
  font;

  const AdminClassesTab({
    super.key,
    required this.loading,
    required this.classes,
    required this.adminActionBusy,
    required this.onAdd,
    this.onRecurring,
    required this.onEdit,
    required this.onActions,
    required this.font,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Classes',
                style: font(
                  18,
                  weight: FontWeight.w800,
                  color: const Color(0xFF111318),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (onRecurring != null) ...[
              GestureDetector(
                onTap: adminActionBusy ? null : onRecurring,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD0D5DD)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Recurring',
                    style: font(
                      14,
                      weight: FontWeight.w700,
                      color: const Color(0xFF344054),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            GestureDetector(
              onTap: adminActionBusy ? null : onAdd,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFB59B6A),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+ Add',
                  style: font(15, weight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (loading)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFFB59B6A)),
          )
        else if (classes.isEmpty)
          _emptyState()
        else
          ...classes.map((e) => _card(Map<String, dynamic>.from(e as Map))),
      ],
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
          const SizedBox(height: 8),
          Text(
            'No classes yet',
            style: font(
              18,
              weight: FontWeight.w800,
              color: const Color(0xFF111318),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create your first class to start managing bookings and attendance.',
            textAlign: TextAlign.center,
            style: font(
              14,
              weight: FontWeight.w500,
              color: const Color(0xFF8F96A3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> item) {
    final dt = DateTime.tryParse(item['starts_at'].toString())?.toLocal();
    final dateLabel = dt != null
        ? DateFormat('EEE, MMM d · HH:mm').format(dt)
        : '-';

    final title = (item['title'] ?? 'Class').toString();
    final coach = (item['coach_name'] ?? 'TBD').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: adminActionBusy ? null : () => onEdit(item),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEFF1F4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: font(
                        16,
                        weight: FontWeight.w700,
                        color: const Color(0xFF111318),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: font(
                        13,
                        weight: FontWeight.w500,
                        color: const Color(0xFF8F96A3),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Coach: $coach',
                      style: font(
                        13,
                        weight: FontWeight.w500,
                        color: const Color(0xFF8F96A3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
