import 'package:flutter/material.dart';

import '../../../l10n/app_text.dart';
import '../../../shared/widgets/input_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';

Future<Map<String, dynamic>?> showCreateRecurringClassesSheet({
  required BuildContext context,
  required List<Map<String, dynamic>> programs,
  required List<Map<String, dynamic>> coaches,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _CreateRecurringClassesSheet(programs: programs, coaches: coaches),
  );
}

class _CreateRecurringClassesSheet extends StatefulWidget {
  final List<Map<String, dynamic>> programs;
  final List<Map<String, dynamic>> coaches;

  const _CreateRecurringClassesSheet({
    required this.programs,
    required this.coaches,
  });

  @override
  State<_CreateRecurringClassesSheet> createState() =>
      _CreateRecurringClassesSheetState();
}

class _CreateRecurringClassesSheetState
    extends State<_CreateRecurringClassesSheet> {
  late String _selectedProgramId;
  String _selectedCoachId = '';

  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');
  final _spotsCtrl = TextEditingController(text: '15');

  final Set<int> _weekdays = {};
  final List<String> _times = ['18:00'];

  bool get _isSpanish => Localizations.localeOf(
    context,
  ).languageCode.toLowerCase().startsWith('es');

  String _text(String es, String en) => _isSpanish ? es : en;

  @override
  void initState() {
    super.initState();
    _selectedProgramId = widget.programs.isNotEmpty
        ? widget.programs.first['id'].toString()
        : '';
    final now = DateTime.now();
    _startDateCtrl.text =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final future = now.add(const Duration(days: 30));
    _endDateCtrl.text =
        '${future.year.toString().padLeft(4, '0')}-${future.month.toString().padLeft(2, '0')}-${future.day.toString().padLeft(2, '0')}';
    _weekdays.add(now.weekday);
  }

  @override
  void dispose() {
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _durationCtrl.dispose();
    _spotsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final initial = DateTime.tryParse(ctrl.text.trim()) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked == null) return;
    ctrl.text =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() {});
  }

  Future<void> _addTime() async {
    final raw = _times.isNotEmpty ? _times.first.split(':') : ['18', '00'];
    final initial = TimeOfDay(
      hour: int.tryParse(raw[0]) ?? 18,
      minute: int.tryParse(raw[1]) ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null) return;
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (_times.contains(value)) return;
    setState(() {
      _times.add(value);
      _times.sort();
    });
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return _text('Lun', 'Mon');
      case DateTime.tuesday:
        return _text('Mar', 'Tue');
      case DateTime.wednesday:
        return _text('Mié', 'Wed');
      case DateTime.thursday:
        return _text('Jue', 'Thu');
      case DateTime.friday:
        return _text('Vie', 'Fri');
      case DateTime.saturday:
        return _text('Sáb', 'Sat');
      default:
        return _text('Dom', 'Sun');
    }
  }

  String? _validate(dynamic t) {
    final duration = int.tryParse(_durationCtrl.text.trim());
    final spots = int.tryParse(_spotsCtrl.text.trim());

    if (_selectedProgramId.trim().isEmpty) return t.programRequiredError;
    if (_startDateCtrl.text.trim().isEmpty) return t.startDateRequiredError;
    if (_endDateCtrl.text.trim().isEmpty) return t.repeatUntilRequiredError;
    if (duration == null || duration <= 0) return t.invalidDurationError;
    if (spots == null || spots <= 0) return t.invalidMaxSpotsError;
    if (_weekdays.isEmpty) return t.selectAtLeastOneWeekdayError;
    if (_times.isEmpty) return t.addAtLeastOneTimeError;

    final start = DateTime.tryParse(_startDateCtrl.text.trim());
    final end = DateTime.tryParse(_endDateCtrl.text.trim());
    if (start == null) return t.invalidStartDateError;
    if (end == null) return t.invalidRepeatUntilDateError;
    if (end.isBefore(start)) return t.repeatUntilAfterStartError;

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appText;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6F7F9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: SingleChildScrollView(
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
                  _text('Crear clases recurrentes', 'Create recurring classes'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111318),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _text(
                    'Programa una agenda futura simple.',
                    'Create a simple future schedule.',
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _selectedProgramId.isEmpty
                      ? null
                      : _selectedProgramId,
                  decoration: const InputDecoration(
                    labelText: 'Program',
                    filled: true,
                    fillColor: Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  items: widget.programs
                      .map(
                        (p) => DropdownMenuItem<String>(
                          value: p['id'].toString(),
                          child: Text((p['name'] ?? t.program).toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProgramId = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCoachId.isEmpty
                      ? ''
                      : _selectedCoachId,
                  decoration: InputDecoration(
                    labelText: t.coach,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String>(value: '', child: Text(t.noCoach)),
                    ...widget.coaches.map(
                      (c) => DropdownMenuItem<String>(
                        value: c['id'].toString(),
                        child: Text((c['full_name'] ?? t.coach).toString()),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCoachId = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InputField(
                        label: _text('Fecha inicio', 'Start date'),
                        controller: _startDateCtrl,
                        hint: '2026-04-23',
                        readOnly: true,
                        onTap: () => _pickDate(_startDateCtrl),
                        fillColor: const Color(0xFFF8FAFC),
                        borderColor: const Color(0xFFE2E8F0),
                        focusedBorderColor: const Color(0xFFB59B6A),
                        radius: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InputField(
                        label: _text('Fecha fin', 'End date'),
                        controller: _endDateCtrl,
                        hint: '2026-05-23',
                        readOnly: true,
                        onTap: () => _pickDate(_endDateCtrl),
                        fillColor: const Color(0xFFF8FAFC),
                        borderColor: const Color(0xFFE2E8F0),
                        focusedBorderColor: const Color(0xFFB59B6A),
                        radius: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _text('Días', 'Weekdays'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111318),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(7, (index) {
                    final weekday = index + 1;
                    final selected = _weekdays.contains(weekday);
                    return InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _weekdays.remove(weekday);
                          } else {
                            _weekdays.add(weekday);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFB59B6A)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFB59B6A)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          _weekdayLabel(weekday),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF344054),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _text('Horarios', 'Times'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111318),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _addTime,
                      child: Text(_text('Añadir hora', 'Add time')),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _times.map((time) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(time),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: _times.length == 1
                                ? null
                                : () {
                                    setState(() {
                                      _times.remove(time);
                                    });
                                  },
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: _times.length == 1
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF667085),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: InputField(
                        label: t.duration,
                        controller: _durationCtrl,
                        hint: '60',
                        keyboardType: TextInputType.number,
                        fillColor: const Color(0xFFF8FAFC),
                        borderColor: const Color(0xFFE2E8F0),
                        focusedBorderColor: const Color(0xFFB59B6A),
                        radius: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InputField(
                        label: t.spots,
                        controller: _spotsCtrl,
                        hint: '15',
                        keyboardType: TextInputType.number,
                        fillColor: const Color(0xFFF8FAFC),
                        borderColor: const Color(0xFFE2E8F0),
                        focusedBorderColor: const Color(0xFFB59B6A),
                        radius: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        text: t.cancel,
                        compact: true,
                        radius: 16,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        text: _text('Crear agenda', 'Create schedule'),
                        compact: true,
                        radius: 16,
                        backgroundColor: const Color(0xFFB59B6A),
                        pressedColor: const Color(0xFFA88C59),
                        disabledColor: const Color(0xFFC9C9C9),
                        onPressed: () {
                          final error = _validate(t);
                          if (error != null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                            return;
                          }
                          Navigator.pop(context, {
                            'programId': _selectedProgramId,
                            'coachId': _selectedCoachId,
                            'startDate': _startDateCtrl.text.trim(),
                            'endDate': _endDateCtrl.text.trim(),
                            'weekdays': _weekdays.toList()..sort(),
                            'times': _times,
                            'duration': _durationCtrl.text.trim(),
                            'maxSpots': _spotsCtrl.text.trim(),
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
