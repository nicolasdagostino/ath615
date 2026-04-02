import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_card.dart';

class AdminMemberDetailHeader extends StatelessWidget {
  final Map<String, dynamic> profile;

  const AdminMemberDetailHeader({super.key, required this.profile});

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

  String _value(dynamic input, String fallback) {
    final value = (input ?? '').toString().trim();
    return value.isEmpty ? fallback : value;
  }

  String _memberSinceLabel() {
    final raw = (profile['member_since'] ?? '').toString().trim();
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) return '—';
    return DateFormat('MMM d, yyyy').format(parsed);
    }

  @override
  Widget build(BuildContext context) {
    final fullName = _value(profile['full_name'], 'Member');
    final email = _value(profile['email'], '—');
    final phone = _value(profile['phone'], '—');
    final isActive = profile['is_active'] == true;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fullName.toUpperCase(),
                  style: _font(
                    24,
                    weight: FontWeight.w800,
                    color: const Color(0xFF0E0E11),
                    letterSpacing: -0.3,
                    height: 0.98,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFDDF5E5)
                      : const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: _font(
                    13,
                    weight: FontWeight.w700,
                    color: isActive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF667085),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            email,
            style: _font(
              15,
              weight: FontWeight.w600,
              color: const Color(0xFF344054),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Phone: $phone',
            style: _font(
              14,
              weight: FontWeight.w500,
              color: const Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Member since: ${_memberSinceLabel()}',
            style: _font(
              14,
              weight: FontWeight.w500,
              color: const Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}
