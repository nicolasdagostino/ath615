import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_text.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';

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

  final bool _saving = false;

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
    DateTime selected =
        DateTime.tryParse(_dateCtrl.text.trim()) ?? DateTime.now();

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AppBottomSheetScaffold(
          title: _text('Elegir fecha', 'Choose date'),
          scrollable: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _text('Selecciona una fecha', 'Select a date'),
                style: appSheetFont(
                  13,
                  weight: FontWeight.w500,
                  color: const Color(0xFF667085),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  height: 180,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: selected,
                    minimumDate: DateTime.now().subtract(
                      const Duration(days: 1),
                    ),
                    maximumDate: DateTime(2035, 12, 31),
                    onDateTimeChanged: (value) => selected = value,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AppSheetActions(
                busy: false,
                primaryText: _text('Guardar', 'Save'),
                cancelText: context.appText.cancel,
                onCancel: () => Navigator.pop(sheetContext),
                onPrimary: () => Navigator.pop(sheetContext, selected),
              ),
            ],
          ),
        );
      },
    );

    if (picked == null) return;
    _dateCtrl.text =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() {});
  }

  Future<void> _pickTime() async {
    final raw = _timeCtrl.text.trim().split(':');
    final now = DateTime.now();
    DateTime selected = DateTime(
      now.year,
      now.month,
      now.day,
      raw.length == 2 ? int.tryParse(raw[0]) ?? 18 : 18,
      raw.length == 2 ? int.tryParse(raw[1]) ?? 0 : 0,
    );

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AppBottomSheetScaffold(
          title: _text('Elegir hora', 'Choose time'),
          subtitle: _text('Selecciona una hora', 'Select a time'),
          scrollable: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _text('Selecciona una fecha', 'Select a date'),
                style: appSheetFont(
                  13,
                  weight: FontWeight.w500,
                  color: const Color(0xFF667085),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  height: 180,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: selected,
                    onDateTimeChanged: (value) => selected = value,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AppSheetActions(
                busy: false,
                primaryText: _text('Guardar', 'Save'),
                cancelText: context.appText.cancel,
                onCancel: () => Navigator.pop(sheetContext),
                onPrimary: () => Navigator.pop(sheetContext, selected),
              ),
            ],
          ),
        );
      },
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
    final isEdit = widget.initialData != null;

    return AppBottomSheetScaffold(
      title: isEdit
          ? _text('Editar clase', 'Edit class')
          : _text('Crear clase', 'Create class'),
      subtitle: _text(
        'Sesión simple sin WOD asignado.',
        'Simple session with no WOD assigned.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSheetDropdown(
            value: _selectedProgramId.isEmpty ? null : _selectedProgramId,
            label: t.program,
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
          AppSheetDropdown(
            value: _selectedCoachId.isEmpty ? '' : _selectedCoachId,
            label: t.coach,
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
                child: AppSheetTextField(
                  label: t.date,
                  controller: _dateCtrl,
                  hint: '2026-04-22',
                  readOnly: true,
                  onTap: _saving ? null : _pickDate,
                  suffixIcon: const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppSheetTextField(
                  label: t.time,
                  controller: _timeCtrl,
                  hint: '18:00',
                  readOnly: true,
                  onTap: _saving ? null : _pickTime,
                  suffixIcon: const Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: Color(0xFFB59B6A),
                  ),
                  suffixIconColor: Color(0xFFB59B6A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppSheetTextField(
                  label: t.duration,
                  controller: _durationCtrl,
                  hint: '60',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppSheetTextField(
                  label: t.spots,
                  controller: _spotsCtrl,
                  hint: '15',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AppSheetActions(
            busy: _saving,
            primaryText: isEdit
                ? _text('Guardar cambios', 'Save changes')
                : t.saveChanges,
            busyText: _text('Guardando...', 'Saving...'),
            cancelText: t.cancel,
            onCancel: _saving ? null : () => Navigator.pop(context),
            onPrimary: _saving
                ? null
                : () {
                    final error = _validate(t);
                    if (error != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
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
                      Navigator.pop(context, {...data, 'mode': 'edit'});
                    } else {
                      Navigator.pop(context, data);
                    }
                  },
          ),
        ],
      ),
    );
  }
}
