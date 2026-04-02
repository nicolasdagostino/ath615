import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminNotificationEditorSheet extends StatelessWidget {
  final bool isEdit;
  final TextEditingController titleCtrl;
  final TextEditingController messageCtrl;
  final TextEditingController scheduledCtrl;
  final String status;
  final String recipientsScope;
  final bool busy;
  final VoidCallback onPickDate;
  final VoidCallback onSave;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onRecipientsChanged;

  const AdminNotificationEditorSheet({
    super.key,
    required this.isEdit,
    required this.titleCtrl,
    required this.messageCtrl,
    required this.scheduledCtrl,
    required this.status,
    required this.recipientsScope,
    required this.busy,
    required this.onPickDate,
    required this.onSave,
    required this.onStatusChanged,
    required this.onRecipientsChanged,
  });

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF6F7F9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            14,
            18,
            18 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(
                  isEdit ? 'Edit notification' : 'New notification',
                  style: _font(
                    24,
                    weight: FontWeight.w800,
                    color: const Color(0xFF111318),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create manual announcements for your gym members.',
                  style: _font(
                    13,
                    weight: FontWeight.w500,
                    color: const Color(0xFF8F96A3),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                const _FieldLabel(text: 'Title'),
                const SizedBox(height: 8),
                _SoftTextField(
                  controller: titleCtrl,
                  hint: 'Friday dinner after the last class',
                  minLines: 1,
                  maxLines: 1,
                ),
                const SizedBox(height: 14),
                const _FieldLabel(text: 'Message'),
                const SizedBox(height: 8),
                _SoftTextField(
                  controller: messageCtrl,
                  hint:
                      'We will have dinner after the final training session on Friday.',
                  minLines: 4,
                  maxLines: 6,
                ),
                const SizedBox(height: 14),
                const _FieldLabel(text: 'Recipients'),
                const SizedBox(height: 8),
                _DropdownCard<String>(
                  value: recipientsScope,
                  items: const [
                    DropdownMenuItem(
                      value: 'all_users',
                      child: Text('All users'),
                    ),
                    DropdownMenuItem(
                      value: 'athletes',
                      child: Text('Athletes'),
                    ),
                    DropdownMenuItem(value: 'members', child: Text('Members')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    onRecipientsChanged(value);
                  },
                ),
                const SizedBox(height: 14),
                const _FieldLabel(text: 'Status'),
                const SizedBox(height: 8),
                _DropdownCard<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(
                      value: 'scheduled',
                      child: Text('Scheduled'),
                    ),
                    DropdownMenuItem(
                      value: 'published',
                      child: Text('Publish now'),
                    ),
                    DropdownMenuItem(value: 'sent', child: Text('Sent')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    onStatusChanged(value);
                  },
                ),
                const SizedBox(height: 14),
                const _FieldLabel(text: 'Scheduled date'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    onPickDate();
                  },
                  child: AbsorbPointer(
                    child: _SoftTextField(
                      controller: scheduledCtrl,
                      hint: 'yyyy-mm-dd',
                      minLines: 1,
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: busy ? null : onSave,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFFB59B6A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isEdit ? 'Save Changes' : 'Create Notification',
                      style: _font(
                        16,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.barlowCondensed(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF111318),
        letterSpacing: -0.1,
      ),
    );
  }
}

class _SoftTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int minLines;
  final int maxLines;

  const _SoftTextField({
    required this.controller,
    required this.hint,
    required this.minLines,
    required this.maxLines,
  });

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

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      cursorColor: const Color(0xFFB59B6A),
      style: _font(13, weight: FontWeight.w500, color: const Color(0xFF111318)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _font(
          13,
          weight: FontWeight.w500,
          color: const Color(0xFF98A2B3),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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
      ),
    );
  }
}

class _DropdownCard<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownCard({
    required this.value,
    required this.items,
    required this.onChanged,
  });

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: _font(
            13,
            weight: FontWeight.w500,
            color: const Color(0xFF111318),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
