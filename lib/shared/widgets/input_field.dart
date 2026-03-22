import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';

class InputField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String hint;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double radius;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;

  const InputField({
    super.key,
    required this.label,
    this.controller,
    this.hint = '',
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
    this.textInputAction,
    this.suffixIcon,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.radius = 14,
    this.contentPadding,
    this.labelStyle,
    this.hintStyle,
    this.textStyle,
  });

  InputDecoration _decoration() {
    final effectiveBorder = borderColor ?? const Color(0xFFD0D5DD);
    final effectiveFocused = focusedBorderColor ?? const Color(0xFF245BEB);

    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fillColor ?? const Color(0xFFF8FAFC),
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: effectiveBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: effectiveBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: effectiveFocused, width: 1.4),
      ),
      hintStyle: hintStyle ??
          const TextStyle(fontSize: 14, color: Color(0xFF98A2B3)),
    );
  }

  Widget _buildField() {
    if (controller != null) {
      return TextField(
        controller: controller,
        obscureText: obscureText,
        maxLines: maxLines,
        
keyboardType: maxLines > 1
          ? TextInputType.multiline
          : keyboardType,

        readOnly: readOnly,
        onTap: onTap,
        inputFormatters: inputFormatters,
        
textInputAction: maxLines > 1
          ? TextInputAction.newline
          : textInputAction,

        style: textStyle,
        decoration: _decoration(),
      );
    }

    return TextFormField(
      initialValue: '',
      obscureText: obscureText,
      maxLines: maxLines,
      
keyboardType: maxLines > 1
          ? TextInputType.multiline
          : keyboardType,

      readOnly: readOnly,
      onTap: onTap,
      inputFormatters: inputFormatters,
      
textInputAction: maxLines > 1
          ? TextInputAction.newline
          : textInputAction,

      style: textStyle,
      decoration: _decoration(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: labelStyle ??
              const TextStyle(
                fontSize: 14,
                height: 1.55,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.28,
                color: Color(0xFF0D0D12),
              ),
        ),
        const SizedBox(height: 8),
        _buildField(),
      ],
    );
  }
}
