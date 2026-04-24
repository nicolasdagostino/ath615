import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'primary_button.dart';
import 'secondary_button.dart';

TextStyle appSheetFont(
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

InputDecoration appSheetInputDecoration(
  String label, {
  String? hint,
  Widget? suffixIcon,
  Color? suffixIconColor,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffixIcon,
    suffixIconColor: suffixIconColor,
    labelStyle: appSheetFont(
      14,
      weight: FontWeight.w600,
      color: const Color(0xFF475467),
      letterSpacing: -0.08,
    ),
    hintStyle: appSheetFont(
      13,
      weight: FontWeight.w500,
      color: const Color(0xFF98A2B3),
      letterSpacing: -0.05,
    ),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFB59B6A), width: 1.2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.2),
    ),
  );
}

class AppBottomSheetScaffold extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool scrollable;
  final bool showHandle;
  final double maxHeightFactor;

  const AppBottomSheetScaffold({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 14, 20, 20),
    this.scrollable = true,
    this.showHandle = true,
    this.maxHeightFactor = 0.88,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHandle) ...[
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD7DBE1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (title != null && title!.trim().isNotEmpty) ...[
          Text(
            title!,
            style: appSheetFont(
              24,
              weight: FontWeight.w800,
              color: const Color(0xFF111318),
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: appSheetFont(
                13,
                weight: FontWeight.w500,
                color: const Color(0xFF667085),
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
        child,
      ],
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * maxHeightFactor,
          ),
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7F9),
            borderRadius: BorderRadius.circular(28),
          ),
          child: scrollable
              ? SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: content,
                )
              : content,
        ),
      ),
    );
  }
}

class AppSheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int minLines;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final Color? suffixIconColor;
  final ValueChanged<PointerDownEvent>? onTapOutside;

  const AppSheetTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.minLines = 1,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.suffixIconColor,
    this.onTapOutside,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      onTapOutside: onTapOutside,
      style: appSheetFont(
        14,
        weight: FontWeight.w500,
        color: const Color(0xFF111318),
        letterSpacing: -0.08,
      ),
      decoration: appSheetInputDecoration(
        label,
        hint: hint,
        suffixIcon: suffixIcon,
        suffixIconColor: suffixIconColor,
      ),
    );
  }
}

class AppSheetDropdown extends StatelessWidget {
  final String? value;
  final String label;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;

  const AppSheetDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      borderRadius: BorderRadius.circular(16),
      dropdownColor: Colors.white,
      iconEnabledColor: const Color(0xFF667085),
      style: appSheetFont(
        14,
        weight: FontWeight.w500,
        color: const Color(0xFF111318),
        letterSpacing: -0.08,
      ),
      decoration: appSheetInputDecoration(label),
      items: items,
      onChanged: onChanged,
    );
  }
}

class AppSheetActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color iconBg;
  final Color iconColor;
  final Color titleColor;

  const AppSheetActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconBg = const Color(0xFFF3F4F6),
    this.iconColor = const Color(0xFF111318),
    this.titleColor = const Color(0xFF111318),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEAECEF)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: subtitle == null || subtitle!.trim().isEmpty
                  ? Text(
                      title,
                      style: appSheetFont(
                        16,
                        weight: FontWeight.w700,
                        color: titleColor,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: appSheetFont(
                            16,
                            weight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: appSheetFont(
                            13,
                            weight: FontWeight.w500,
                            color: const Color(0xFF667085),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppSheetActions extends StatelessWidget {
  final bool busy;
  final String primaryText;
  final String? busyText;
  final String cancelText;
  final VoidCallback? onCancel;
  final VoidCallback? onPrimary;
  final Color primaryColor;
  final Color pressedColor;

  const AppSheetActions({
    super.key,
    required this.busy,
    required this.primaryText,
    this.busyText,
    required this.cancelText,
    required this.onCancel,
    required this.onPrimary,
    this.primaryColor = const Color(0xFFB59B6A),
    this.pressedColor = const Color(0xFFA88C59),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SecondaryButton(
            text: cancelText,
            compact: true,
            radius: 16,
            textStyle: appSheetFont(
              16,
              weight: FontWeight.w700,
              color: const Color(0xFF344054),
              letterSpacing: -0.15,
            ),
            onPressed: busy ? null : onCancel,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryButton(
            text: busy ? (busyText ?? primaryText) : primaryText,
            compact: true,
            radius: 16,
            backgroundColor: primaryColor,
            pressedColor: pressedColor,
            disabledColor: const Color(0xFFC9C9C9),
            textColor: Colors.white,
            textStyle: appSheetFont(
              16,
              weight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.15,
            ),
            boxShadow: const [],
            onPressed: busy ? null : onPrimary,
          ),
        ),
      ],
    );
  }
}
