import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_text.dart';
import '../../../shared/widgets/input_field.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';

Future<Map<String, dynamic>?> showCreateWorkoutSheet(
  BuildContext context, {
  required List<Map<String, dynamic>> programs,
  required Future<Map<String, dynamic>?> Function(String name) onCreateProgram,
  Map<String, dynamic>? item,
}) {
  final t = context.appText;
  final isEdit = item != null;
  final localPrograms = List<Map<String, dynamic>>.from(programs);

  final descriptionCtrl = TextEditingController(
    text: item?['description']?.toString() ?? '',
  );
  final dateCtrl = TextEditingController(
    text:
        item?['workout_date']?.toString() ??
        DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );

  String selectedProgramId =
      item?['program_id']?.toString() ??
      (localPrograms.isNotEmpty ? localPrograms.first['id'].toString() : '');
  String existingImageUrl = item?['image_url']?.toString() ?? '';
  File? pickedImage;

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

  Future<void> pickDate(BuildContext context) async {
    DateTime selectedDate =
        DateTime.tryParse(dateCtrl.text.trim()) ?? DateTime.now();

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF6F7F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: StatefulBuilder(
              builder: (context, setLocalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 220,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: selectedDate,
                        minimumDate: DateTime(2024),
                        maximumDate: DateTime(2035, 12, 31),
                        onDateTimeChanged: (value) {
                          setLocalState(() => selectedDate = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(sheetContext, selectedDate),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFB59B6A),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(t.saveChanges),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (picked != null) {
      dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  InputField field({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return InputField(
      label: label,
      controller: controller,
      hint: hint,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      suffixIcon: suffixIcon,
      fillColor: const Color(0xFFF8FAFC),
      borderColor: const Color(0xFFE2E8F0),
      focusedBorderColor: const Color(0xFFB59B6A),
      radius: 16,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: font(12, color: const Color(0xFF667085)),
      hintStyle: font(13, color: const Color(0xFF98A2B3)),
      textStyle: font(13, color: const Color(0xFF111318)),
    );
  }

  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setLocalState) {
          final selectedProgram = localPrograms
              .cast<Map<String, dynamic>?>()
              .firstWhere(
                (p) => (p?['id'] ?? '').toString() == selectedProgramId,
                orElse: () => null,
              );
          final selectedProgramName = (selectedProgram?['name'] ?? '')
              .toString()
              .trim();

          return Padding(
            padding: EdgeInsets.only(
              top: 36,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF6F7F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(
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
                        isEdit
                            ? (t.isSpanish ? 'Editar workout' : 'Edit workout')
                            : (t.isSpanish
                                  ? 'Crear workout'
                                  : 'Create workout'),
                        style: font(24, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 18),
                      AppSheetDropdown(
                        value: selectedProgramId.isEmpty
                            ? null
                            : selectedProgramId,
                        label: t.program,
                        items: [
                          ...localPrograms.map(
                            (p) => DropdownMenuItem<String>(
                              value: p['id'].toString(),
                              child: Text((p['name'] ?? t.program).toString()),
                            ),
                          ),
                        ],
                        onChanged: (value) async {
                          setLocalState(() => selectedProgramId = value ?? '');
                        },
                      ),
                      const SizedBox(height: 14),
                      field(
                        label: t.isSpanish ? 'Descripción' : 'Description',
                        controller: descriptionCtrl,
                        hint: t.isSpanish
                            ? 'Escribe el WOD...'
                            : 'Write the WOD...',
                        maxLines: 8,
                      ),
                      const SizedBox(height: 14),
                      AppSheetTextField(
                        label: t.isSpanish ? 'Fecha' : 'Date',
                        controller: dateCtrl,
                        hint: 'yyyy-mm-dd',
                        readOnly: true,
                        onTap: () => pickDate(sheetContext),
                        suffixIcon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () async {
                          final xfile = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 90,
                          );
                          if (xfile == null) return;
                          setLocalState(() => pickedImage = File(xfile.path));
                        },
                        child: Container(
                          width: double.infinity,
                          height: 190,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: pickedImage != null
                                ? Image.file(pickedImage!, fit: BoxFit.cover)
                                : existingImageUrl.isNotEmpty
                                ? Image.network(
                                    existingImageUrl,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.image_outlined,
                                          size: 40,
                                          color: Color(0xFF98A2B3),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          t.tapToChooseImage,
                                          style: font(
                                            13,
                                            color: const Color(0xFF8F96A3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: selectedProgramId.trim().isEmpty
                              ? null
                              : () {
                                  Navigator.pop(sheetContext, {
                                    'programId': selectedProgramId,
                                    'programName': selectedProgramName,
                                    'title': '',
                                    'description': descriptionCtrl.text.trim(),
                                    'workoutDate': dateCtrl.text.trim(),
                                    'imageFile': pickedImage,
                                    'existingImageUrl': existingImageUrl,
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFFB59B6A),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFC9C9C9),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isEdit
                                ? t.saveChanges
                                : (t.isSpanish
                                      ? 'Crear workout'
                                      : 'Create workout'),
                            style: font(
                              16,
                              weight: FontWeight.w700,
                              color: Colors.white,
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
        },
      );
    },
  ).whenComplete(() {
    descriptionCtrl.dispose();
    dateCtrl.dispose();
  });
}
