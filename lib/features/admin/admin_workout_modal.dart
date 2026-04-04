part of 'admin_screen.dart';

extension _AdminScreenWorkoutModal on _AdminScreenState {
  void _showWorkoutModal({Map<String, dynamic>? item}) {
    final t = context.appText;
    final isEdit = item != null;

    String selectedProgramId = isEdit
        ? (item['program_id']?.toString() ?? '')
        : (_programs.isNotEmpty ? _programs.first['id'].toString() : '');

    final titleCtrl = TextEditingController(
      text: item?['title']?.toString() ?? '',
    );
    final descriptionCtrl = TextEditingController(
      text: item?['description']?.toString() ?? '',
    );
    final dateCtrl = TextEditingController(
      text:
          item?['workout_date']?.toString() ??
          DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    String imageUrl = item?['image_url']?.toString() ?? '';
    File? pickedImage;
    bool uploading = false;

    Future<void> pickDate(
      BuildContext context,
      TextEditingController controller, {
      String? title,
      String? subtitle,
    }) async {
      final resolvedTitle = title ?? (t.isSpanish ? 'Fecha del entrenamiento' : 'Workout Date');
      final resolvedSubtitle = subtitle ?? (t.isSpanish ? 'Elige la fecha del entrenamiento.' : 'Choose the workout date.');
      final now = DateTime.now();
      DateTime selectedDate = DateTime.tryParse(controller.text.trim()) ?? now;

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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: StatefulBuilder(
                  builder: (context, setModalState) {
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
                                      resolvedTitle,
                                      style: _font(
                                        24,
                                        weight: FontWeight.w800,
                                        color: const Color(0xFF111318),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      resolvedSubtitle,
                                      style: _font(
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
                                onTap: () => Navigator.pop(sheetContext),
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
                            t.selectDate,
                            style: _font(
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
                              border: Border.all(
                                color: const Color(0xFFEAECEF),
                              ),
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
                                      initialDateTime: selectedDate,
                                      minimumDate: DateTime(2024),
                                      maximumDate: DateTime(2035, 12, 31),
                                      onDateTimeChanged: (value) {
                                        setModalState(() {
                                          selectedDate = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat(
                                    'd MMMM yyyy',
                                  ).format(selectedDate),
                                  style: _font(
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
                              child: Text(
                                t.saveChanges,
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
                    );
                  },
                ),
              ),
            ),
          );
        },
      );

      if (picked != null) {
        controller.text = picked.toIso8601String().split('T').first;
      }
    }

    InputDecoration dropdownDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: _font(
          12,
          weight: FontWeight.w500,
          color: const Color(0xFF667085),
        ),
        floatingLabelStyle: _font(
          12,
          weight: FontWeight.w600,
          color: const Color(0xFF667085),
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
      );
    }

    Widget sectionTitle(String text) {
      return Text(
        text,
        style: _font(
          15,
          weight: FontWeight.w800,
          color: const Color(0xFF111318),
          letterSpacing: -0.1,
        ),
      );
    }

    InputField styledField({
      required String label,
      required TextEditingController controller,
      required String hint,
      int maxLines = 1,
      TextInputAction? textInputAction,
      TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      Widget? suffixIcon,
    }) {
      return InputField(
        label: label,
        controller: controller,
        hint: hint,
        maxLines: maxLines,
        textInputAction: textInputAction,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        suffixIcon: suffixIcon,
        fillColor: const Color(0xFFF8FAFC),
        borderColor: const Color(0xFFE2E8F0),
        focusedBorderColor: const Color(0xFFB59B6A),
        radius: 16,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: _font(
          12,
          weight: FontWeight.w500,
          color: const Color(0xFF667085),
        ),
        hintStyle: _font(
          13,
          weight: FontWeight.w500,
          color: const Color(0xFF98A2B3),
        ),
        textStyle: _font(
          13,
          weight: FontWeight.w500,
          color: const Color(0xFF111318),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
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
              child: StatefulBuilder(
                builder: (context, setLocalState) {
                  return SingleChildScrollView(
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
                                Icons.fitness_center_rounded,
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
                                    isEdit
                                        ? t.editWorkoutModalTitle
                                        : t.createWorkoutModalTitle,
                                    style: _font(
                                      24,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFF111318),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isEdit
                                        ? context
                                              .appText
                                              .editWorkoutModalSubtitle
                                        : context
                                              .appText
                                              .createWorkoutModalSubtitle,
                                    style: _font(
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
                              onTap: () => Navigator.pop(sheetContext),
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
                        sectionTitle(context.appText.workoutSetupSection),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFEAECEF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: selectedProgramId.isEmpty
                                    ? null
                                    : selectedProgramId,
                                decoration: dropdownDecoration(t.program),
                                borderRadius: BorderRadius.circular(16),
                                dropdownColor: Colors.white,
                                iconEnabledColor: const Color(0xFF667085),
                                style: _font(
                                  13,
                                  weight: FontWeight.w500,
                                  color: const Color(0xFF111318),
                                ),
                                items: [
                                  DropdownMenuItem<String>(
                                    value: '',
                                    child: Text(
                                      context.appText.noProgram,
                                      style: _font(
                                        13,
                                        weight: FontWeight.w500,
                                        color: const Color(0xFF111318),
                                      ),
                                    ),
                                  ),
                                  ..._programs.map((p) {
                                    return DropdownMenuItem<String>(
                                      value: p['id'].toString(),
                                      child: Text(
                                        (p['name'] ?? t.program).toString(),
                                        style: _font(
                                          13,
                                          weight: FontWeight.w500,
                                          color: const Color(0xFF111318),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                                selectedItemBuilder: (context) {
                                  final labels = [
                                    context.appText.noProgram,
                                    ..._programs.map(
                                      (p) =>
                                          (p['name'] ?? t.program).toString(),
                                    ),
                                  ];
                                  return labels
                                      .map(
                                        (label) => Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            label,
                                            style: _font(
                                              13,
                                              weight: FontWeight.w500,
                                              color: const Color(0xFF111318),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList();
                                },
                                onChanged: (value) {
                                  setLocalState(() {
                                    selectedProgramId = value ?? '';
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              styledField(
                                label: context.appText.workoutTitleLabel,
                                controller: titleCtrl,
                                hint: context.appText.workoutTitleHint,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 12),
                              styledField(
                                label: context.appText.workoutDateLabel,
                                controller: dateCtrl,
                                hint: '2026-03-15',
                                readOnly: true,
                                onTap: () async {
                                  await pickDate(context, dateCtrl);
                                  setLocalState(() {});
                                },
                                suffixIcon: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: Color(0xFF98A2B3),
                                ),
                              ),
                              const SizedBox(height: 12),
                              styledField(
                                label: context.appText.description,
                                controller: descriptionCtrl,
                                hint: context.appText.descriptionHintWorkout,
                                maxLines: 5,
                                textInputAction: TextInputAction.newline,
                                keyboardType: TextInputType.multiline,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        sectionTitle(t.workoutImageSection),
                        const SizedBox(height: 10),
                        InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () async {
                            final xfile = await _picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 90,
                            );
                            if (xfile == null) return;
                            setLocalState(() {
                              pickedImage = File(xfile.path);
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            height: 190,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: pickedImage != null
                                  ? Image.file(pickedImage!, fit: BoxFit.cover)
                                  : (imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Center(
                                                      child: Icon(
                                                        Icons.image_outlined,
                                                        size: 40,
                                                        color: Color(
                                                          0xFF6B7280,
                                                        ),
                                                      ),
                                                    ),
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
                                                  style: _font(
                                                    13,
                                                    weight: FontWeight.w500,
                                                    color: const Color(
                                                      0xFF8F96A3,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                text: context.appText.cancel,
                                compact: true,
                                radius: 16,
                                textStyle: _font(
                                  16,
                                  weight: FontWeight.w700,
                                  color: const Color(0xFF344054),
                                  letterSpacing: -0.15,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PrimaryButton(
                                text: uploading
                                    ? context.appText.uploadingImage
                                    : (isEdit
                                          ? t.saveChanges
                                          : t.createWorkoutModalTitle),
                                compact: true,
                                radius: 16,
                                backgroundColor: const Color(0xFFB59B6A),
                                pressedColor: const Color(0xFFA88C59),
                                disabledColor: const Color(0xFFC9C9C9),
                                textColor: Colors.white,
                                textStyle: _font(
                                  16,
                                  weight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.15,
                                ),
                                boxShadow: const [],
                                onPressed: uploading
                                    ? null
                                    : () async {
                                        FocusScope.of(sheetContext).unfocus();

                                        setLocalState(() {
                                          uploading = true;
                                        });

                                        String finalImageUrl = imageUrl;

                                        if (!context.mounted) return;
                                        final t = context.appText;

                                        try {
                                          if (pickedImage != null) {
                                            finalImageUrl = await _storageRepo
                                                .uploadWorkoutImage(
                                                  pickedImage!,
                                                );
                                          }

                                          if (isEdit) {
                                            await _runAdminAction(
                                              () => _updateWorkout(
                                                id: item['id'].toString(),
                                                programId: selectedProgramId,
                                                title: titleCtrl.text,
                                                description:
                                                    descriptionCtrl.text,
                                                workoutDate: dateCtrl.text,
                                                workoutType: '',
                                                imageUrl: finalImageUrl,
                                              ),
                                              successMessage: t.workoutUpdated,
                                            );
                                          } else {
                                            await _runAdminAction(
                                              () => _createWorkout(
                                                programId: selectedProgramId,
                                                title: titleCtrl.text,
                                                description:
                                                    descriptionCtrl.text,
                                                workoutDate: dateCtrl.text,
                                                workoutType: '',
                                                imageUrl: finalImageUrl,
                                              ),
                                              successMessage: t.workoutCreated,
                                            );
                                          }

                                          if (!context.mounted) return;
                                          Navigator.pop(context);
                                        } finally {
                                          if (mounted) {
                                            setLocalState(() {
                                              uploading = false;
                                            });
                                          }
                                        }
                                      },
                              ),
                            ),
                          ],
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
