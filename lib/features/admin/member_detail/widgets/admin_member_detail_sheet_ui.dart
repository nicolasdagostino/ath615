import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_bottom_sheet.dart';

TextStyle memberDetailSheetFont(
  double size, {
  FontWeight weight = FontWeight.w500,
  Color color = const Color(0xFF111318),
  double? height,
  double? letterSpacing,
}) {
  return appSheetFont(
    size,
    weight: weight,
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
  return appSheetInputDecoration(label, hint: hint, suffixIcon: suffixIcon);
}

TextStyle memberDetailSheetFieldTextStyle() {
  return appSheetFont(
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
    return AppBottomSheetScaffold(
      title: title,
      subtitle: subtitle,
      child: child,
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
    return AppSheetTextField(
      controller: controller,
      label: label,
      hint: hint,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      suffixIcon: suffixIcon,
      onTapOutside: onTapOutside,
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
    return AppSheetDropdown(
      value: value,
      label: label,
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
                  style: appSheetFont(
                    14,
                    weight: FontWeight.w700,
                    color: const Color(0xFF111318),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: appSheetFont(
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

  bool _isSpanish(BuildContext context) => Localizations.localeOf(
    context,
  ).languageCode.toLowerCase().startsWith('es');

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
    return AppSheetActions(
      busy: busy,
      primaryText: primaryText,
      busyText: busyText,
      cancelText: _cancelText(context),
      onCancel: onCancel,
      onPrimary: onPrimary,
    );
  }
}
