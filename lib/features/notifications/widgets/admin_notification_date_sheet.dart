import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminNotificationDateSheet {
  static Future<DateTime?> pick(BuildContext context, DateTime initial) async {
    DateTime selectedDate = initial;

    return await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (dateSheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF6F7F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 220,
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.date,
                          initialDateTime: selectedDate,
                          minimumDate: DateTime.now(),
                          maximumDate: DateTime(2035, 12, 31),
                          onDateTimeChanged: (value) {
                            setState(() => selectedDate = value);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        DateFormat('d MMMM yyyy').format(selectedDate),
                        style: GoogleFonts.barlowCondensed(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(dateSheetContext, selectedDate),
                        child: const Text('Save'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
