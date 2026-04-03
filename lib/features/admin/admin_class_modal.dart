part of 'admin_screen.dart';

extension _AdminScreenClassModal on _AdminScreenState {
  void _showClassModal({Map<String, dynamic>? item}) {
    final t = context.appText;
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

    final recurrenceEndDateCtrl = TextEditingController(
      text: DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.now().add(const Duration(days: 30))),
    );

    bool recurrenceEnabled = false;
    final selectedWeekdays = <int>{};
    final recurrenceTimes = <String>[];

    if (!isEdit) {
      final parsedDate = DateTime.tryParse(dateCtrl.text.trim());
      selectedWeekdays.add((parsedDate ?? DateTime.now()).weekday);
      final initialTime = timeCtrl.text.trim().isEmpty
          ? '18:00'
          : timeCtrl.text.trim();
      recurrenceTimes.add(initialTime);
    }

    Future<void> pickDate(
      BuildContext context,
      TextEditingController controller, {
      String title = 'Date',
      String subtitle = 'Choose a date.',
      DateTime? minimumDate,
      DateTime? maximumDate,
    }) async {
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
                                      title,
                                      style: _font(
                                        24,
                                        weight: FontWeight.w800,
                                        color: const Color(0xFF111318),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
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
                                      minimumDate:
                                          minimumDate ?? DateTime(2024),
                                      maximumDate:
                                          maximumDate ?? DateTime(2035, 12, 31),
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

    Future<void> pickTime(
      BuildContext context,
      void Function(String value) onSelected, {
      String? initialValue,
      String title = 'Time',
      String subtitle = 'Choose the class start time.',
    }) async {
      int selectedHour = 18;
      int selectedMinute = 0;

      final raw = (initialValue ?? '').trim();
      final parts = raw.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && h >= 0 && h <= 23) {
          selectedHour = h;
        }
        if (m != null && m >= 0 && m <= 59) {
          selectedMinute = m;
        }
      }

      final picked = await showModalBottomSheet<String>(
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
                                  Icons.schedule_rounded,
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
                                      title,
                                      style: _font(
                                        24,
                                        weight: FontWeight.w800,
                                        color: const Color(0xFF111318),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
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
                            'Select Time',
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
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: CupertinoPicker(
                                          scrollController:
                                              FixedExtentScrollController(
                                                initialItem: selectedHour,
                                              ),
                                          itemExtent: 40,
                                          useMagnifier: true,
                                          magnification: 1.05,
                                          onSelectedItemChanged: (value) {
                                            setModalState(() {
                                              selectedHour = value;
                                            });
                                          },
                                          children: List.generate(
                                            24,
                                            (index) => Center(
                                              child: Text(
                                                index.toString().padLeft(
                                                  2,
                                                  '0',
                                                ),
                                                style: _font(
                                                  20,
                                                  weight: FontWeight.w700,
                                                  color: const Color(
                                                    0xFF111318,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        ':',
                                        style: _font(
                                          22,
                                          weight: FontWeight.w800,
                                          color: const Color(0xFF111318),
                                        ),
                                      ),
                                      Expanded(
                                        child: CupertinoPicker(
                                          scrollController:
                                              FixedExtentScrollController(
                                                initialItem:
                                                    (selectedMinute ~/ 15)
                                                        .clamp(0, 3),
                                              ),
                                          itemExtent: 40,
                                          useMagnifier: true,
                                          magnification: 1.05,
                                          onSelectedItemChanged: (value) {
                                            setModalState(() {
                                              selectedMinute = value * 15;
                                            });
                                          },
                                          children: [
                                            Center(
                                              child: Text(
                                                '00',
                                                style: _font(
                                                  20,
                                                  weight: FontWeight.w700,
                                                  color: const Color(
                                                    0xFF111318,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Center(
                                              child: Text(
                                                '15',
                                                style: _font(
                                                  20,
                                                  weight: FontWeight.w700,
                                                  color: const Color(
                                                    0xFF111318,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Center(
                                              child: Text(
                                                '30',
                                                style: _font(
                                                  20,
                                                  weight: FontWeight.w700,
                                                  color: const Color(
                                                    0xFF111318,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Center(
                                              child: Text(
                                                '45',
                                                style: _font(
                                                  20,
                                                  weight: FontWeight.w700,
                                                  color: const Color(
                                                    0xFF111318,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
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
                              onPressed: () => Navigator.pop(
                                sheetContext,
                                '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}',
                              ),
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

      if (picked != null && picked.trim().isNotEmpty) {
        onSelected(picked.trim());
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

    Widget weekdayChip({
      required String label,
      required int weekday,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFB59B6A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFFB59B6A)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: _font(
              12,
              weight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF344054),
              letterSpacing: -0.1,
            ),
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(top: 36, bottom: bottomInset),
          child: FractionallySizedBox(
            heightFactor: 0.86,
            alignment: Alignment.bottomCenter,
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
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isEdit
                                            ? context
                                                  .appText
                                                  .editClassModalTitle
                                            : context
                                                  .appText
                                                  .scheduleClassModalTitle,
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
                                                  .editClassModalSubtitle
                                            : context
                                                  .appText
                                                  .scheduleClassModalSubtitle,
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
                            sectionTitle(context.appText.classSetupSection),
                            const SizedBox(height: 10),
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
                                    items: _programs
                                        .map(
                                          (p) => DropdownMenuItem<String>(
                                            value: p['id'].toString(),
                                            child: Text(
                                              (p['name'] ?? t.program)
                                                  .toString(),
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
                                                (p['name'] ?? t.program)
                                                    .toString(),
                                                style: _font(
                                                  13,
                                                  weight: FontWeight.w500,
                                                  color: const Color(
                                                    0xFF111318,
                                                  ),
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
                                    decoration: dropdownDecoration(
                                      context.appText.coach,
                                    ),
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
                                          context.appText.noCoach,
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
                                            (c['full_name'] ?? 'Coach')
                                                .toString(),
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
                                        context.appText.noCoach,
                                        ..._coaches.map(
                                          (c) => (c['full_name'] ?? 'Coach')
                                              .toString(),
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
                                                  color: const Color(
                                                    0xFF111318,
                                                  ),
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
                                          label: recurrenceEnabled && !isEdit
                                              ? context.appText.startDateLabel
                                              : context.appText.date,
                                          controller: dateCtrl,
                                          hint: '2026-03-12',
                                          readOnly: true,
                                          onTap: () async {
                                            await pickDate(context, dateCtrl);
                                            if (!isEdit &&
                                                recurrenceEnabled &&
                                                selectedWeekdays.isEmpty) {
                                              final parsed = DateTime.tryParse(
                                                dateCtrl.text.trim(),
                                              );
                                              if (parsed != null) {
                                                selectedWeekdays.add(
                                                  parsed.weekday,
                                                );
                                              }
                                            }
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
                                          label: recurrenceEnabled && !isEdit
                                              ? context.appText.primaryTimeLabel
                                              : context.appText.time,
                                          controller: timeCtrl,
                                          hint: '18:00',
                                          readOnly: true,
                                          onTap: () async {
                                            await pickTime(context, (value) {
                                              setLocalState(() {
                                                timeCtrl.text = value;
                                                if (!isEdit &&
                                                    recurrenceEnabled) {
                                                  if (recurrenceTimes.isEmpty) {
                                                    recurrenceTimes.add(value);
                                                  } else {
                                                    recurrenceTimes[0] = value;
                                                  }
                                                }
                                              });
                                            }, initialValue: timeCtrl.text);
                                          },
                                          textInputAction: TextInputAction.next,
                                          suffixIcon: const Icon(
                                            Icons.schedule_rounded,
                                            size: 18,
                                            color: Color(0xFF98A2B3),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: styledField(
                                          label: context.appText.duration,
                                          controller: durationCtrl,
                                          hint: '60',
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: styledField(
                                          label: context.appText.spots,
                                          controller: maxSpotsCtrl,
                                          hint: '15',
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.done,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            if (!isEdit) ...[
                              const SizedBox(height: 14),
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
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            t.recurringScheduleTitle,
                                            style: _font(
                                              15,
                                              weight: FontWeight.w800,
                                              color: const Color(0xFF111318),
                                              letterSpacing: -0.1,
                                            ),
                                          ),
                                        ),
                                        Switch.adaptive(
                                          value: recurrenceEnabled,
                                          activeThumbColor: const Color(
                                            0xFFB59B6A,
                                          ),
                                          onChanged: (value) {
                                            setLocalState(() {
                                              recurrenceEnabled = value;
                                              if (recurrenceEnabled) {
                                                if (recurrenceTimes.isEmpty) {
                                                  recurrenceTimes.add(
                                                    timeCtrl.text.trim().isEmpty
                                                        ? '18:00'
                                                        : timeCtrl.text.trim(),
                                                  );
                                                }
                                                if (selectedWeekdays.isEmpty) {
                                                  final parsed =
                                                      DateTime.tryParse(
                                                        dateCtrl.text.trim(),
                                                      );
                                                  selectedWeekdays.add(
                                                    (parsed ?? DateTime.now())
                                                        .weekday,
                                                  );
                                                }
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      context.appText.recurringScheduleSubtitle,
                                      style: _font(
                                        13,
                                        weight: FontWeight.w500,
                                        color: const Color(0xFF8F96A3),
                                      ),
                                    ),
                                    if (recurrenceEnabled) ...[
                                      const SizedBox(height: 16),
                                      styledField(
                                        label: context.appText.repeatUntilLabel,
                                        controller: recurrenceEndDateCtrl,
                                        hint: '2026-04-30',
                                        readOnly: true,
                                        onTap: () async {
                                          await pickDate(
                                            context,
                                            recurrenceEndDateCtrl,
                                          );
                                          setLocalState(() {});
                                        },
                                        suffixIcon: const Icon(
                                          Icons.event_repeat_rounded,
                                          size: 18,
                                          color: Color(0xFF98A2B3),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        context.appText.daysLabel,
                                        style: _font(
                                          12,
                                          weight: FontWeight.w700,
                                          color: const Color(0xFF667085),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          weekdayChip(
                                            label: 'Mon',
                                            weekday: DateTime.monday,
                                            selected: selectedWeekdays.contains(
                                              DateTime.monday,
                                            ),
                                            onTap: () {
                                              setLocalState(() {
                                                if (selectedWeekdays.contains(
                                                  DateTime.monday,
                                                )) {
                                                  selectedWeekdays.remove(
                                                    DateTime.monday,
                                                  );
                                                } else {
                                                  selectedWeekdays.add(
                                                    DateTime.monday,
                                                  );
                                                }
                                              });
                                            },
                                          ),
                                          weekdayChip(
                                            label: 'Tue',
                                            weekday: DateTime.tuesday,
                                            selected: selectedWeekdays.contains(
                                              DateTime.tuesday,
                                            ),
                                            onTap: () {
                                              setLocalState(() {
                                                if (selectedWeekdays.contains(
                                                  DateTime.tuesday,
                                                )) {
                                                  selectedWeekdays.remove(
                                                    DateTime.tuesday,
                                                  );
                                                } else {
                                                  selectedWeekdays.add(
                                                    DateTime.tuesday,
                                                  );
                                                }
                                              });
                                            },
                                          ),
                                          weekdayChip(
                                            label: 'Wed',
                                            weekday: DateTime.wednesday,
                                            selected: selectedWeekdays.contains(
                                              DateTime.wednesday,
                                            ),
                                            onTap: () {
                                              setLocalState(() {
                                                if (selectedWeekdays.contains(
                                                  DateTime.wednesday,
                                                )) {
                                                  selectedWeekdays.remove(
                                                    DateTime.wednesday,
                                                  );
                                                } else {
                                                  selectedWeekdays.add(
                                                    DateTime.wednesday,
                                                  );
                                                }
                                              });
                                            },
                                          ),
                                          weekdayChip(
                                            label: 'Thu',
                                            weekday: DateTime.thursday,
                                            selected: selectedWeekdays.contains(
                                              DateTime.thursday,
                                            ),
                                            onTap: () {
                                              setLocalState(() {
                                                if (selectedWeekdays.contains(
                                                  DateTime.thursday,
                                                )) {
                                                  selectedWeekdays.remove(
                                                    DateTime.thursday,
                                                  );
                                                } else {
                                                  selectedWeekdays.add(
                                                    DateTime.thursday,
                                                  );
                                                }
                                              });
                                            },
                                          ),
                                          weekdayChip(
                                            label: 'Fri',
                                            weekday: DateTime.friday,
                                            selected: selectedWeekdays.contains(
                                              DateTime.friday,
                                            ),
                                            onTap: () {
                                              setLocalState(() {
                                                if (selectedWeekdays.contains(
                                                  DateTime.friday,
                                                )) {
                                                  selectedWeekdays.remove(
                                                    DateTime.friday,
                                                  );
                                                } else {
                                                  selectedWeekdays.add(
                                                    DateTime.friday,
                                                  );
                                                }
                                              });
                                            },
                                          ),
                                          weekdayChip(
                                            label: 'Sat',
                                            weekday: DateTime.saturday,
                                            selected: selectedWeekdays.contains(
                                              DateTime.saturday,
                                            ),
                                            onTap: () {
                                              setLocalState(() {
                                                if (selectedWeekdays.contains(
                                                  DateTime.saturday,
                                                )) {
                                                  selectedWeekdays.remove(
                                                    DateTime.saturday,
                                                  );
                                                } else {
                                                  selectedWeekdays.add(
                                                    DateTime.saturday,
                                                  );
                                                }
                                              });
                                            },
                                          ),
                                          weekdayChip(
                                            label: 'Sun',
                                            weekday: DateTime.sunday,
                                            selected: selectedWeekdays.contains(
                                              DateTime.sunday,
                                            ),
                                            onTap: () {
                                              setLocalState(() {
                                                if (selectedWeekdays.contains(
                                                  DateTime.sunday,
                                                )) {
                                                  selectedWeekdays.remove(
                                                    DateTime.sunday,
                                                  );
                                                } else {
                                                  selectedWeekdays.add(
                                                    DateTime.sunday,
                                                  );
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              context.appText.timesLabel,
                                              style: _font(
                                                12,
                                                weight: FontWeight.w700,
                                                color: const Color(0xFF667085),
                                              ),
                                            ),
                                          ),
                                          TextButton.icon(
                                            onPressed: () async {
                                              await pickTime(
                                                context,
                                                (value) {
                                                  setLocalState(() {
                                                    if (!recurrenceTimes
                                                        .contains(value)) {
                                                      recurrenceTimes.add(
                                                        value,
                                                      );
                                                      recurrenceTimes.sort();
                                                    }
                                                    if (recurrenceTimes
                                                        .isNotEmpty) {
                                                      timeCtrl.text =
                                                          recurrenceTimes.first;
                                                    }
                                                  });
                                                },
                                                initialValue: timeCtrl.text,
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.add_rounded,
                                              size: 18,
                                              color: Color(0xFFB59B6A),
                                            ),
                                            label: Text(
                                              context.appText.addTimeLabel,
                                              style: _font(
                                                12,
                                                weight: FontWeight.w700,
                                                color: const Color(0xFFB59B6A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: recurrenceTimes.map((time) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: const Color(0xFFE2E8F0),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  time,
                                                  style: _font(
                                                    12,
                                                    weight: FontWeight.w700,
                                                    color: const Color(
                                                      0xFF344054,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                InkWell(
                                                  onTap:
                                                      recurrenceTimes.length ==
                                                          1
                                                      ? null
                                                      : () {
                                                          setLocalState(() {
                                                            recurrenceTimes
                                                                .remove(time);
                                                            if (recurrenceTimes
                                                                .isNotEmpty) {
                                                              recurrenceTimes
                                                                  .sort();
                                                              timeCtrl.text =
                                                                  recurrenceTimes
                                                                      .first;
                                                            }
                                                          });
                                                        },
                                                  child: Icon(
                                                    Icons.close_rounded,
                                                    size: 16,
                                                    color:
                                                        recurrenceTimes
                                                                .length ==
                                                            1
                                                        ? const Color(
                                                            0xFFCBD5E1,
                                                          )
                                                        : const Color(
                                                            0xFF667085,
                                                          ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
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
                                    text: isEdit
                                        ? t.saveChanges
                                        : recurrenceEnabled
                                        ? context.appText.createScheduleCta
                                        : context
                                              .appText
                                              .scheduleClassModalTitle,
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
                                            title: '',
                                            description: '',
                                            date: dateCtrl.text,
                                            time: timeCtrl.text,
                                            duration: durationCtrl.text,
                                            maxSpots: maxSpotsCtrl.text,
                                            location: locationCtrl.text,
                                            status: selectedStatus,
                                          ),
                                          successMessage:
                                              context.appText.classUpdated,
                                        );
                                      } else if (recurrenceEnabled) {
                                        await _runAdminAction(
                                          () => _createRecurringClasses(
                                            programId: selectedProgramId,
                                            coachId: selectedCoachId,
                                            title: '',
                                            description: '',
                                            startDate: dateCtrl.text,
                                            endDate: recurrenceEndDateCtrl.text,
                                            weekdays: selectedWeekdays.toList(),
                                            times: recurrenceTimes,
                                            duration: durationCtrl.text,
                                            maxSpots: maxSpotsCtrl.text,
                                            location: locationCtrl.text,
                                          ),
                                          successMessage:
                                              t.recurringScheduleCreated,
                                        );
                                      } else {
                                        await _runAdminAction(
                                          () => _createClass(
                                            programId: selectedProgramId,
                                            coachId: selectedCoachId,
                                            title: '',
                                            description: '',
                                            date: dateCtrl.text,
                                            time: timeCtrl.text,
                                            duration: durationCtrl.text,
                                            maxSpots: maxSpotsCtrl.text,
                                            location: locationCtrl.text,
                                          ),
                                          successMessage:
                                              context.appText.classCreated,
                                        );
                                      }

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
          ),
        );
      },
    );
  }
}
