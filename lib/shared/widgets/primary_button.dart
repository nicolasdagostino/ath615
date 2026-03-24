import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double radius;
  final bool compact;
  final Color? backgroundColor;
  final Color? pressedColor;
  final Color? disabledColor;
  final Color? textColor;
  final TextStyle? textStyle;
  final List<BoxShadow>? boxShadow;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.height = 52,
    this.radius = 12,
    this.compact = false,
    this.backgroundColor,
    this.pressedColor,
    this.disabledColor,
    this.textColor,
    this.textStyle,
    this.boxShadow,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = widget.compact ? 48.0 : widget.height;
    final effectiveRadius = widget.compact ? 10.0 : widget.radius;
    final enabled = widget.onPressed != null;

    final bg = widget.backgroundColor ?? const Color(0xFF064BB3);
    final pressedBg = widget.pressedColor ?? const Color(0xFF053F97);
    final disabledBg = widget.disabledColor ?? const Color(0xFFBFC8D4);
    final effectiveTextColor = widget.textColor ?? Colors.white;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: enabled && _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          height: effectiveHeight,
          decoration: BoxDecoration(
            color: !enabled ? disabledBg : (_pressed ? pressedBg : bg),
            borderRadius: BorderRadius.circular(effectiveRadius),
            boxShadow:
                widget.boxShadow ??
                const [
                  BoxShadow(
                    color: Color(0x0F0D0D12),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20, color: effectiveTextColor),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                textAlign: TextAlign.center,
                style:
                    widget.textStyle ??
                    TextStyle(
                      color: effectiveTextColor,
                      fontSize: 16,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.32,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
