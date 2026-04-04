import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_text.dart';

class DashboardNextClassCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String occupancyLabel;
  final bool hasWorkout;
  final String? secondaryAttentionLabel;
  final VoidCallback? onTap;
  final bool compact;
  final bool embedded;

  const DashboardNextClassCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.occupancyLabel,
    required this.hasWorkout,
    this.secondaryAttentionLabel,
    this.onTap,
    this.compact = false,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(embedded ? 18 : 22);
    final bgColor = embedded ? const Color(0xFFF8FAFD) : Colors.white;
    final borderColor = embedded
        ? const Color(0xFFE3EAF5)
        : const Color(0xFFEAECEF);

    return Material(
      color: bgColor,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 18,
            compact ? 16 : 18,
            compact ? 16 : 18,
            compact ? 14 : 16,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: radius,
            border: Border.all(color: borderColor),
            boxShadow: embedded
                ? null
                : const [
                    BoxShadow(
                      blurRadius: 10,
                      offset: Offset(0, 4),
                      color: Color(0x080D0D12),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3EA),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  context.appText.nextClassUpper,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB59B6A),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              SizedBox(height: compact ? 12 : 16),
              Text(
                title,
                style: GoogleFonts.barlowCondensed(
                  fontSize: compact ? 28 : 30,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111318),
                  height: 0.98,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF667085),
                  height: 1.45,
                ),
              ),
              SizedBox(height: compact ? 14 : 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(
                    occupancyLabel,
                    bg: const Color(0xFFEFF4FB),
                    fg: const Color(0xFF064BB3),
                  ),
                  if (secondaryAttentionLabel != null &&
                      secondaryAttentionLabel!.trim().isNotEmpty)
                    _pill(
                      secondaryAttentionLabel!,
                      bg: const Color(0xFFFFF4E5),
                      fg: const Color(0xFFB54708),
                    ),
                  _pill(
                    hasWorkout
                        ? context.appText.workoutAssigned
                        : context.appText.workoutMissing,
                    bg: hasWorkout
                        ? const Color(0xFFDDF5E5)
                        : const Color(0xFFFEE4E2),
                    fg: hasWorkout
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFE11D48),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
          height: 1.2,
        ),
      ),
    );
  }
}
