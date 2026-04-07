part of 'admin_screen.dart';

extension _AdminScreenAssignWorkoutModal on _AdminScreenState {
  void _showAssignWorkoutModal(Map<String, dynamic> classItem) {
    final t = context.appText;
    if (_workouts.isEmpty) {
      _toast(t.createWorkoutFirst);
      return;
    }

    String selectedWorkoutId =
        classItem['workout_id']?.toString().isNotEmpty == true
        ? classItem['workout_id'].toString()
        : _workouts.first['id'].toString();

    final className = (classItem['title'] ?? context.appText.classLabel).toString().trim();
    final programName =
        (classItem['program_name'] ?? context.appText.programLabel)
            .toString()
            .trim();

    String classDateLabel = '';
    try {
      final dt = DateTime.parse(classItem['starts_at'].toString()).toLocal();
      classDateLabel = DateFormat(
        'EEE, MMM d · HH:mm',
        Localizations.localeOf(context).toLanguageTag(),
      ).format(dt);
    } catch (_) {}

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            top: 36,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF6F7F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: StatefulBuilder(
                  builder: (context, setLocalState) {
                    // SMART FILTER: same date + same program first
                    final classDateRaw = classItem['starts_at']?.toString() ?? '';
                    final classProgramId = classItem['program_id']?.toString() ?? '';

                    String classDate = '';
                    try {
                      final dt = DateTime.parse(classDateRaw).toLocal();
                      classDate = dt.toIso8601String().split('T').first;
                    } catch (_) {}

                    final prioritizedWorkouts = [
                      ..._workouts.where((w) =>
                        (w['program_id']?.toString() ?? '') == classProgramId &&
                        (w['workout_date']?.toString() ?? '') == classDate
                      ),
                      ..._workouts.where((w) =>
                        !(
                          (w['program_id']?.toString() ?? '') == classProgramId &&
                          (w['workout_date']?.toString() ?? '') == classDate
                        )
                      ),
                    ];

                    final selectedWorkout = prioritizedWorkouts.firstWhere(
                      (w) => w['id'].toString() == selectedWorkoutId,
                      orElse: () => prioritizedWorkouts.first,
                    );

                    final selectedWorkoutTitle =
                        (selectedWorkout['title'] ??
                                context.appText.workoutLabel)
                            .toString()
                            .trim();
                    final selectedWorkoutDate =
                        (selectedWorkout['workout_date'] ?? '')
                            .toString()
                            .trim();
                    final selectedWorkoutProgram =
                        (selectedWorkout['program_name'] ??
                                context.appText.programLabel)
                            .toString()
                            .trim();
                    final selectedWorkoutType =
                        (selectedWorkout['workout_type'] ?? '')
                            .toString()
                            .trim();
                    final selectedWorkoutDescription =
                        (selectedWorkout['description'] ?? '')
                            .toString()
                            .trim();
                    final selectedWorkoutImageUrl =
                        (selectedWorkout['image_url'] ?? '')
                            .toString()
                            .trim();

                    String previewDescription = selectedWorkoutDescription;
                    if (previewDescription.length > 140) {
                      previewDescription =
                          '${previewDescription.substring(0, 140).trimRight()}...';
                    }

                    return SingleChildScrollView(
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
                                  Icons.assignment_turned_in_rounded,
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
                                      t.assignWorkoutModalTitle,
                                      style: _font(
                                        24,
                                        weight: FontWeight.w800,
                                        color: const Color(0xFF111318),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      context
                                          .appText
                                          .assignWorkoutModalSubtitle,
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
                                onTap: () => Navigator.pop(context),
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFEAECEF),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.appText.programLabel,
                                        style: _font(
                                          12,
                                          weight: FontWeight.w600,
                                          color: const Color(0xFF667085),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        programName.isEmpty
                                            ? context.appText.programLabel
                                            : programName,
                                        style: _font(
                                          18,
                                          weight: FontWeight.w800,
                                          color: const Color(0xFF111318),
                                          letterSpacing: -0.15,
                                        ),
                                      ),
                                      if (classDateLabel.isNotEmpty ||
                                          className.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          [
                                            if (className.isNotEmpty &&
                                                className.toLowerCase() !=
                                                    programName.toLowerCase())
                                              className,
                                            if (classDateLabel.isNotEmpty)
                                              classDateLabel,
                                          ].join(' · '),
                                          style: _font(
                                            13,
                                            weight: FontWeight.w500,
                                            color: const Color(0xFF667085),
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedWorkoutId,
                                  decoration: dropdownDecoration(
                                    context.appText.workoutLabel,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  dropdownColor: Colors.white,
                                  iconEnabledColor: const Color(0xFF667085),
                                  style: _font(
                                    13,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF111318),
                                  ),
                                  items: prioritizedWorkouts.map((w) {
                                    final title =
                                        (w['title'] ??
                                                context.appText.workoutLabel)
                                            .toString();
                                    final date = (w['workout_date'] ?? '')
                                        .toString()
                                        .trim();
                                    return DropdownMenuItem<String>(
                                      value: w['id'].toString(),
                                      child: Text(
                                        date.isEmpty ? title : '$title · $date',
                                        style: _font(
                                          13,
                                          weight: FontWeight.w500,
                                          color: const Color(0xFF111318),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  selectedItemBuilder: (context) {
                                    return prioritizedWorkouts.map((w) {
                                      final title =
                                          (w['title'] ??
                                                  context.appText.workoutLabel)
                                              .toString();
                                      final date = (w['workout_date'] ?? '')
                                          .toString()
                                          .trim();
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          date.isEmpty
                                              ? title
                                              : '$title · $date',
                                          style: _font(
                                            13,
                                            weight: FontWeight.w500,
                                            color: const Color(0xFF111318),
                                          ),
                                        ),
                                      );
                                    }).toList();
                                  },
                                  onChanged: (value) {
                                    if (value != null) {
                                      setLocalState(() {
                                        selectedWorkoutId = value;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFFE8ECF1),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (selectedWorkoutImageUrl.isNotEmpty)
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(18),
                                              ),
                                          child: SizedBox(
                                            width: double.infinity,
                                            height: 150,
                                            child: Image.network(
                                              selectedWorkoutImageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    color: const Color(
                                                      0xFFF3F4F6,
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: const Icon(
                                                      Icons.image_outlined,
                                                      size: 34,
                                                      color: Color(0xFF98A2B3),
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 38,
                                                  height: 38,
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFF3F4F6,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons
                                                        .fitness_center_rounded,
                                                    size: 18,
                                                    color: Color(0xFF98A2B3),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        selectedWorkoutTitle,
                                                        style: _font(
                                                          15,
                                                          weight:
                                                              FontWeight.w800,
                                                          color: const Color(
                                                            0xFF111318,
                                                          ),
                                                          letterSpacing: -0.1,
                                                        ),
                                                      ),
                                                      if (selectedWorkoutDate
                                                              .isNotEmpty ||
                                                          selectedWorkoutProgram
                                                              .isNotEmpty) ...[
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          [
                                                            if (selectedWorkoutDate
                                                                .isNotEmpty)
                                                              selectedWorkoutDate,
                                                            if (selectedWorkoutProgram
                                                                    .isNotEmpty &&
                                                                selectedWorkoutProgram
                                                                        .toLowerCase() !=
                                                                    selectedWorkoutTitle
                                                                        .toLowerCase())
                                                              selectedWorkoutProgram,
                                                          ].join(' · '),
                                                          style: _font(
                                                            12,
                                                            weight:
                                                                FontWeight.w500,
                                                            color: const Color(
                                                              0xFF667085,
                                                            ),
                                                            height: 1.35,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  context.appText.selectedLabel,
                                                  style: _font(
                                                    12,
                                                    weight: FontWeight.w600,
                                                    color: const Color(
                                                      0xFF98A2B3,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (selectedWorkoutType
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 7,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(999),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFE2E8F0,
                                                    ),
                                                  ),
                                                ),
                                                child: Text(
                                                  selectedWorkoutType,
                                                  style: _font(
                                                    11,
                                                    weight: FontWeight.w700,
                                                    color: const Color(
                                                      0xFF475467,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (previewDescription.isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              Text(
                                                previewDescription,
                                                style: _font(
                                                  13,
                                                  weight: FontWeight.w500,
                                                  color: const Color(
                                                    0xFF475467,
                                                  ),
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                                  text: context.appText.assignCta,
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
                                  onPressed: () async {
                                    await _runAdminAction(
                                      () => _assignWorkoutToClass(
                                        classId: classItem['id'].toString(),
                                        workoutId: selectedWorkoutId,
                                      ),
                                      successMessage: t.workoutAssignedToClass,
                                    );
                                    if (!context.mounted) return;
                                    Navigator.pop(context);
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
          ),
        );
      },
    );
  }
}
