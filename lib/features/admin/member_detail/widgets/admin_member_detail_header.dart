import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_card.dart';

class AdminMemberDetailHeader extends StatelessWidget {
  final Map<String, dynamic> profile;

  const AdminMemberDetailHeader({super.key, required this.profile});

  bool _isSpanish(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('es');

  String _text(BuildContext context, String es, String en) =>
      _isSpanish(context) ? es : en;

  String _value(dynamic value, String fallback) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3EA),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 28,
                  color: Color(0xFFB59B6A),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111318),
                        height: 0.96,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFE7F6EC)
                                : const Color(0xFFFEE4E2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isActive
                                ? _text(context, 'ACTIVO', 'ACTIVE')
                                : _text(context, 'INACTIVO', 'INACTIVE'),
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isActive
                                  ? const Color(0xFF1F8A4C)
                                  : const Color(0xFFB42318),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFF0F2F5)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _infoChip(Icons.mail_outline_rounded, email),
              if (phone != '—') _infoChip(Icons.call_outlined, phone),
              _infoChip(
                Icons.calendar_today_outlined,
                '${_text(context, 'Miembro desde', 'Member since')} ${_memberSinceLabel()}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7EBF0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF667085)),
          const SizedBox(width: 7),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF475467),
            ),
          ),
        ],
      ),
    );
  }
}
