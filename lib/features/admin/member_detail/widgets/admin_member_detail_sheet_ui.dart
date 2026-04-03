import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/secondary_button.dart';

TextStyle memberDetailSheetFont(
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

InputDecoration memberDetailSheetInputDecoration(
  String label, {
  String? hint,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    suffixIcon: suffixIcon,
    labelStyle: memberDetailSheetFont(
      14,
      weight: FontWeight.w600,
      color: const Color(0xFF475467),
      letterSpacing: -0.08,
    ),
    hintStyle: memberDetailSheetFont(
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

TextStyle memberDetailSheetFieldTextStyle() {
  return memberDetailSheetFont(
    14,
    weight: FontWeight.w500,
    color: const Color(0xFF111318),
    letterSpacing: -0.08,
  );
}

class AdminMemberDetailSheetScaffold extends StatelessWidget {
  final BuildContext sheetContext;
  final String title;
  final String subtitle;
  final Widget child;

  const AdminMemberDetailSheetScaffold({
    super.key,
    required this.sheetContext,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7F9),
            borderRadius: BorderRadius.circular(26),
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7DBE1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: memberDetailSheetFont(
                    22,
                    weight: FontWeight.w800,
                    color: const Color(0xFF111318),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: memberDetailSheetFont(
                    13,
                    weight: FontWeight.w500,
                    color: const Color(0xFF667085),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminMemberDetailSheetTextField extends StatelessWidget {
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
  final ValueChanged<PointerDownEvent>? onTapOutside;

  const AdminMemberDetailSheetTextField({
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
      style: memberDetailSheetFieldTextStyle(),
      decoration: memberDetailSheetInputDecoration(
        label,
        hint: hint,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class AdminMemberDetailSheetDropdown extends StatelessWidget {
  final String value;
  final String label;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;

  const AdminMemberDetailSheetDropdown({
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
      style: memberDetailSheetFieldTextStyle(),
      decoration: memberDetailSheetInputDecoration(label),
      items: items,
      onChanged: onChanged,
    );
  }
}

class AdminMemberDetailSheetSwitchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AdminMemberDetailSheetSwitchCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: memberDetailSheetFont(
                    14,
                    weight: FontWeight.w700,
                    color: const Color(0xFF111318),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: memberDetailSheetFont(
                    12,
                    weight: FontWeight.w500,
                    color: const Color(0xFF8F96A3),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFFB59B6A),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFD0D5DD),
          ),
        ],
      ),
    );
  }
}

class AdminMemberDetailSheetActions extends StatelessWidget {
  final bool busy;
  final String primaryText;
  final String busyText;
  final VoidCallback? onCancel;
  final VoidCallback? onPrimary;

  bool _isSpanish(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('es');

  String _cancelText(BuildContext context) =>
      _isSpanish(context) ? 'Cancelar' : 'Cancel';

  const AdminMemberDetailSheetActions({
    super.key,
    required this.busy,
    required this.primaryText,
    required this.busyText,
    required this.onCancel,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SecondaryButton(
            text: _cancelText(context),
            compact: true,
            radius: 16,
            textStyle: memberDetailSheetFont(
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
            text: busy ? busyText : primaryText,
            compact: true,
            radius: 16,
            backgroundColor: const Color(0xFFB59B6A),
            pressedColor: const Color(0xFFA88C59),
            disabledColor: const Color(0xFFC9C9C9),
            textColor: Colors.white,
            textStyle: memberDetailSheetFont(
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
