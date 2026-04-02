import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminNotificationDateSheet {
  static Future<DateTime?> pick(BuildContext context, DateTime initial) async {
    DateTime selectedDate = initial;

    TextStyle font(
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

    final now = DateTime.now();
    final minDate = DateTime(now.year, now.month, now.day);

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
                  return SingleChildScrollView(
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
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F3EA),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.event_rounded,
                                color: Color(0xFFB59B6A),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scheduled date',
                                    style: font(
                                      24,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFF111318),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Choose when this announcement should be sent.',
                                    style: font(
                                      13,
                                      weight: FontWeight.w500,
                                      color: const Color(0xFF8F96A3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.pop(dateSheetContext),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE8EBF0),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 22,
                                  color: Color(0xFF111318),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select date',
                          style: font(
                            15,
                            weight: FontWeight.w800,
                            color: const Color(0xFF111318),
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFEAECEF)),
                          ),
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 220,
                                child: CupertinoTheme(
                                  data: const CupertinoThemeData(
                                    primaryColor: Color(0xFFB59B6A),
                                    textTheme: CupertinoTextThemeData(
                                      dateTimePickerTextStyle: TextStyle(
                                        color: Color(0xFF111318),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  child: CupertinoDatePicker(
                                    mode: CupertinoDatePickerMode.date,
                                    initialDateTime:
                                        selectedDate.isBefore(minDate)
                                        ? minDate
                                        : selectedDate,
                                    minimumDate: minDate,
                                    maximumDate: DateTime(2035, 12, 31),
                                    onDateTimeChanged: (value) {
                                      setState(() => selectedDate = value);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('d MMMM yyyy').format(selectedDate),
                                style: font(
                                  13,
                                  weight: FontWeight.w600,
                                  color: const Color(0xFF667085),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(dateSheetContext, selectedDate),
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
                              'Save changes',
                              style: font(
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
