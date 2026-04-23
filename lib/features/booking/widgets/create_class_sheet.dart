import 'package:flutter/material.dart';

import '../../../l10n/app_text.dart';
import '../../../shared/widgets/input_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';

Future<Map<String, dynamic>?> showCreateClassSheet({
  required BuildContext context,
  required List<Map<String, dynamic>> programs,
  required List<Map<String, dynamic>> coaches,
  Map<String, dynamic>? initialData,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _CreateClassSheet(
        programs: programs,
        coaches: coaches,
        initialData: initialData,
      );
    },
  );
}

class _CreateClassSheet extends StatefulWidget {
  final List<Map<String, dynamic>> programs;
  final List<Map<String, dynamic>> coaches;
  final Map<String, dynamic>? initialData;

  const _CreateClassSheet({
    required this.programs,
    required this.coaches,
    this.initialData,
  });

  @override
  State<_CreateClassSheet> createState() => _CreateClassSheetState();
}

class _CreateClassSheetState extends State<_CreateClassSheet> {
  late String _selectedProgramId;
  String _selectedCoachId = '';

  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController(text: '18:00');
  final _durationCtrl = TextEditingController(text: '60');
  final _spotsCtrl = TextEditingController(text: '15');

  bool _saving = false;

  bool get _isSpanish => Localizations.localeOf(
    context,
  ).languageCode.toLowerCase().startsWith('es');

  String _text(String es, String en) => _isSpanish ? es : en;

  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      final item = widget.initialData!;
      _selectedProgramId =
          item['program_id']?.toString() ??
          (widget.programs.isNotEmpty
              ? widget.programs.first['id'].toString()
              : '');
      _selectedCoachId = item['coach_id']?.toString() ?? '';

      final dt = DateTime.tryParse(
        (item['starts_at'] ?? '').toString(),
      )?.toLocal();
      if (dt != null) {
        _dateCtrl.text =
            '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        _timeCtrl.text =
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }

      _durationCtrl.text = (item['duration_minutes'] ?? '60').toString();
      _spotsCtrl.text = (item['max_spots'] ?? '15').toString();
    } else {
      _selectedProgramId = widget.programs.isNotEmpty
          ? widget.programs.first['id'].toString()
          : '';
      final now = DateTime.now();
      _dateCtrl.text =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _durationCtrl.dispose();
    _spotsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_dateCtrl.text.trim()) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked == null) return;
    _dateCtrl.text =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() {});
  }

  Future<void> _pickTime() async {
    final raw = _timeCtrl.text.trim().split(':');
    final initial = TimeOfDay(
      hour: raw.length == 2 ? int.tryParse(raw[0]) ?? 18 : 18,
      minute: raw.length == 2 ? int.tryParse(raw[1]) ?? 0 : 0,
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
    _timeCtrl.text =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {});
  }

  String? _validate(dynamic t) {
    final duration = int.tryParse(_durationCtrl.text.trim());
    final spots = int.tryParse(_spotsCtrl.text.trim());
    final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

    if (_selectedProgramId.trim().isEmpty) return t.programRequiredError;
    if (_dateCtrl.text.trim().isEmpty) return t.dateRequiredError;
    if (_timeCtrl.text.trim().isEmpty) return t.timeRequiredError;
    if (!timeRegex.hasMatch(_timeCtrl.text.trim())) {
      return _text('Hora inválida', 'Invalid time');
    }
    if (duration == null || duration <= 0) return t.invalidDurationError;
    if (spots == null || spots <= 0) return t.invalidMaxSpotsError;

    final dateParts = _dateCtrl.text.trim().split('-');
    final timeParts = _timeCtrl.text.trim().split(':');
    if (dateParts.length != 3 || timeParts.length != 2) {
      return _text('Fecha u hora inválida', 'Invalid date or time');
    }

    final local = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    if (local.isBefore(DateTime.now())) {
      return t.classesCannotBeInPastError;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appText;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.initialData != null;

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
                  isEdit
                      ? _text('Editar clase', 'Edit class')
                      : _text('Crear clase', 'Create class'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111318),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _text(
                    'Sesión simple sin WOD asignado.',
                    'Simple session with no WOD assigned.',
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
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(
                        color: Color(0xFFB59B6A),
                        width: 1.2,
                      ),
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
                  onChanged: _saving
                      ? null
                      : (value) {
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
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(
                        color: Color(0xFFB59B6A),
                        width: 1.2,
                      ),
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
                  onChanged: _saving
                      ? null
                      : (value) {
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
                        label: t.date,
                        controller: _dateCtrl,
                        hint: '2026-04-22',
                        readOnly: true,
                        onTap: _saving ? null : _pickDate,
                        suffixIcon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                        ),
                        fillColor: const Color(0xFFF8FAFC),
                        borderColor: const Color(0xFFE2E8F0),
                        focusedBorderColor: const Color(0xFFB59B6A),
                        radius: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InputField(
                        label: t.time,
                        controller: _timeCtrl,
                        hint: '18:00',
                        readOnly: true,
                        onTap: _saving ? null : _pickTime,
                        suffixIcon: const Icon(
                          Icons.schedule_rounded,
                          size: 18,
                        ),
                        fillColor: const Color(0xFFF8FAFC),
                        borderColor: const Color(0xFFE2E8F0),
                        focusedBorderColor: const Color(0xFFB59B6A),
                        radius: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        text: _saving
                            ? _text('Guardando...', 'Saving...')
                            : (isEdit
                                  ? _text('Guardar cambios', 'Save changes')
                                  : t.saveChanges),
                        compact: true,
                        radius: 16,
                        backgroundColor: const Color(0xFFB59B6A),
                        pressedColor: const Color(0xFFA88C59),
                        disabledColor: const Color(0xFFC9C9C9),
                        onPressed: _saving
                            ? null
                            : () {
                                final error = _validate(t);
                                if (error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error)),
                                  );
                                  return;
                                }
                                final data = {
                                  'programId': _selectedProgramId,
                                  'coachId': _selectedCoachId,
                                  'date': _dateCtrl.text.trim(),
                                  'time': _timeCtrl.text.trim(),
                                  'duration': _durationCtrl.text.trim(),
                                  'maxSpots': _spotsCtrl.text.trim(),
                                };
                                if (isEdit) {
                                  Navigator.pop(context, {
                                    ...data,
                                    'mode': 'edit',
                                  });
                                } else {
                                  Navigator.pop(context, data);
                                }
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
