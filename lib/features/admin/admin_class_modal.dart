part of 'admin_screen.dart';

extension _AdminScreenClassModal on _AdminScreenState {
void _showClassModal({Map<String, dynamic>? item}) {
    final isEdit = item != null;

    String selectedProgramId = isEdit
        ? (item['program_id']?.toString() ??
              (_programs.isNotEmpty ? _programs.first['id'].toString() : ''))
        : (_programs.isNotEmpty ? _programs.first['id'].toString() : '');

    String selectedCoachId = isEdit ? (item['coach_id']?.toString() ?? '') : '';
    String selectedStatus = isEdit
        ? (item['status']?.toString() ?? 'scheduled')
        : 'scheduled';

    final dt = isEdit
        ? DateTime.tryParse(item['starts_at'].toString())?.toLocal()
        : null;

    final titleCtrl = TextEditingController(
      text: item?['title']?.toString() ?? '',
    );
    final descriptionCtrl = TextEditingController(
      text: item?['description']?.toString() ?? '',
    );
    final dateCtrl = TextEditingController(
      text: dt != null
          ? '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}'
          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final timeCtrl = TextEditingController(
      text: dt != null
          ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
          : '18:00',
    );
    final durationCtrl = TextEditingController(
      text: item?['duration_minutes']?.toString() ?? '60',
    );
    final maxSpotsCtrl = TextEditingController(
      text: item?['max_spots']?.toString() ?? '15',
    );
    final locationCtrl = TextEditingController(
      text: item?['location']?.toString() ?? 'Athlete 615',
    );

    Future<void> pickDate(
      BuildContext context,
      TextEditingController controller,
    ) async {
      DateTime initialDate = DateTime.now();
      final raw = controller.text.trim();
      if (raw.isNotEmpty) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) initialDate = parsed;
      }

      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2024),
        lastDate: DateTime(2035),
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
      TextInputAction? textInputAction,
      TextInputType? keyboardType,
      int maxLines = 1,
      bool readOnly = false,
      VoidCallback? onTap,
      Widget? suffixIcon,
    }) {
      return InputField(
        label: label,
        controller: controller,
        hint: hint,
        textInputAction: textInputAction,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        suffixIcon: suffixIcon,
        fillColor: const Color(0xFFF8FAFC),
        borderColor: const Color(0xFFE2E8F0),
        focusedBorderColor: const Color(0xFFB59B6A),
        radius: 16,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                                  Icons.calendar_today_rounded,
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
                                      isEdit ? 'Edit Class' : 'Create Class',
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
                                          ? 'Update scheduling, capacity and coach details.'
                                          : 'Create a new class for your training schedule.',
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
                                    border: Border.all(color: const Color(0xFFE8EBF0)),
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
                          sectionTitle('Class setup'),
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
                                  decoration: dropdownDecoration('Program'),
                                  borderRadius: BorderRadius.circular(16),
                                  dropdownColor: Colors.white,
                                  iconEnabledColor: const Color(0xFF667085),
                                  style: _font(
                                    13,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF111318),
                                  ),
                                  items: _programs
                                      .map(
                                        (p) => DropdownMenuItem<String>(
                                          value: p['id'].toString(),
                                          child: Text(
                                            (p['name'] ?? 'Program').toString(),
                                            style: _font(
                                              13,
                                              weight: FontWeight.w500,
                                              color: const Color(0xFF111318),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  selectedItemBuilder: (context) {
                                    return _programs
                                        .map(
                                          (p) => Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              (p['name'] ?? 'Program').toString(),
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
                                    if (value != null) {
                                      setLocalState(() {
                                        selectedProgramId = value;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedCoachId.isEmpty
                                      ? null
                                      : selectedCoachId,
                                  decoration: dropdownDecoration('Coach'),
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
                                        'No coach',
                                        style: _font(
                                          13,
                                          weight: FontWeight.w500,
                                          color: const Color(0xFF111318),
                                        ),
                                      ),
                                    ),
                                    ..._coaches.map(
                                      (c) => DropdownMenuItem<String>(
                                        value: c['id'].toString(),
                                        child: Text(
                                          (c['full_name'] ?? 'Coach').toString(),
                                          style: _font(
                                            13,
                                            weight: FontWeight.w500,
                                            color: const Color(0xFF111318),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  selectedItemBuilder: (context) {
                                    final labels = [
                                      'No coach',
                                      ..._coaches.map(
                                        (c) => (c['full_name'] ?? 'Coach').toString(),
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
                                      selectedCoachId = value ?? '';
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: styledField(
                                        label: 'Date',
                                        controller: dateCtrl,
                                        hint: '2026-03-12',
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
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: styledField(
                                        label: 'Time',
                                        controller: timeCtrl,
                                        hint: '18:00',
                                        textInputAction: TextInputAction.next,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: styledField(
                                        label: 'Duration',
                                        controller: durationCtrl,
                                        hint: '60',
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.next,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: styledField(
                                        label: 'Spots',
                                        controller: maxSpotsCtrl,
                                        hint: '15',
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.next,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                styledField(
                                  label: 'Location',
                                  controller: locationCtrl,
                                  hint: 'Athlete 615',
                                  textInputAction: TextInputAction.next,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            title: Text(
                              'Optional details',
                              style: _font(
                                15,
                                weight: FontWeight.w700,
                                color: const Color(0xFF667085),
                                letterSpacing: -0.1,
                              ),
                            ),
                            children: [
                              const SizedBox(height: 8),
                              if (isEdit) ...[
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedStatus,
                                  decoration: dropdownDecoration('Status'),
                                  borderRadius: BorderRadius.circular(16),
                                  dropdownColor: Colors.white,
                                  iconEnabledColor: const Color(0xFF667085),
                                  style: _font(
                                    13,
                                    weight: FontWeight.w500,
                                    color: const Color(0xFF111318),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'scheduled',
                                      child: Text('Scheduled'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'cancelled',
                                      child: Text('Cancelled'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'completed',
                                      child: Text('Completed'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setLocalState(() {
                                        selectedStatus = value;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: SecondaryButton(
                                  text: 'Cancel',
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
                                  text: isEdit ? 'Save Changes' : 'Create Class',
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
                                    FocusScope.of(context).unfocus();

                                    if (isEdit) {
                                      await _runAdminAction(
                                        () => _updateClass(
                                          id: item['id'].toString(),
                                          programId: selectedProgramId,
                                          coachId: selectedCoachId,
                                          title: titleCtrl.text,
                                          description: descriptionCtrl.text,
                                          date: dateCtrl.text,
                                          time: timeCtrl.text,
                                          duration: durationCtrl.text,
                                          maxSpots: maxSpotsCtrl.text,
                                          location: locationCtrl.text,
                                          status: selectedStatus,
                                        ),
                                        successMessage: 'Class updated',
                                      );
                                    } else {
                                      await _runAdminAction(
                                        () => _createClass(
                                          programId: selectedProgramId,
                                          coachId: selectedCoachId,
                                          title: titleCtrl.text,
                                          description: descriptionCtrl.text,
                                          date: dateCtrl.text,
                                          time: timeCtrl.text,
                                          duration: durationCtrl.text,
                                          maxSpots: maxSpotsCtrl.text,
                                          location: locationCtrl.text,
                                        ),
                                        successMessage: 'Class created',
                                      );
                                    }

                                    if (!mounted) return;
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
