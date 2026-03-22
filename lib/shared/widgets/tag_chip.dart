import 'package:flutter/material.dart';

class TagChip extends StatefulWidget {
  final String label;
  final Color? background;
  final Color? textColor;
  final bool selected;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const TagChip({
    super.key,
    required this.label,
    this.background,
    this.textColor,
    this.selected = false,
    this.padding,
    this.onTap,
  });

  @override
  State<TagChip> createState() => _TagChipState();
}

class _TagChipState extends State<TagChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? const Color(0xFFE6EDF7)
        : (widget.background ?? Colors.white);

    final fg = widget.selected
        ? const Color(0xFF064BB3)
        : (widget.textColor ?? const Color(0xFF818898));

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          height: 30,
          padding:
              widget.padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _pressed ? bg.withOpacity(0.88) : bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.28,
            ),
          ),
        ),
      ),
    );
  }
}
