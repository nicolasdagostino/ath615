import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/supabase/achievement_repository.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/input_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/search_field.dart';
import '../../shared/widgets/secondary_button.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _repo = AchievementRepository();

  bool milestones = false;
  bool _loading = true;
  String? _error;
  String _query = '';

  List<Map<String, dynamic>> personalRecords = [];
  List<Map<String, dynamic>> milestoneItems = [];

  static const List<String> _categories = ['Strength', 'Benchmark', 'Open'];

  static const List<String> _strengthMovements = [
    'Back Squat',
    'Front Squat',
    'Overhead Squat',
    'Deadlift',
    'Bench Press',
    'Strict Press',
    'Push Press',
    'Push Jerk',
    'Split Jerk',
    'Clean',
    'Power Clean',
    'Hang Clean',
    'Snatch',
    'Power Snatch',
    'Hang Snatch',
    'Clean and Jerk',
  ];

  static const List<String> _benchmarks = [
    'Fran',
    'Murph',
    'Annie',
    'Cindy',
    'Karen',
    'Helen',
    'Grace',
    'Diane',
    'Elizabeth',
    'Isabel',
    'Nancy',
    'Jackie',
    'Fight Gone Bad',
    'Filthy Fifty',
  ];

  static const List<String> _opens = [
    'Open 26.1',
    'Open 26.2',
    'Open 26.3',
    'Open 25.1',
    'Open 25.2',
    'Open 25.3',
    'Open 24.1',
    'Open 24.2',
    'Open 24.3',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  TextStyle _font(
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prs = await _repo.myPrs();
      final achievements = await _repo.myAchievements();

      if (!mounted) return;
      setState(() {
        personalRecords = prs;
        milestoneItems = achievements;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Color _categoryColor(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('strength')) return const Color(0xFFB59B6A);
    if (lower.contains('benchmark')) return const Color(0xFF111318);
    if (lower.contains('open')) return const Color(0xFF667085);
    return const Color(0xFF111318);
  }

  String _formatDate(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return '-';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    return DateFormat('MMMM d, yyyy').format(parsed);
  }

  void _toast(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? const Color(0xFFB42318)
            : const Color(0xFF111318),
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: _font(14, weight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  String _recordValue(Map<String, dynamic> item) {
    final category = (item['category'] ?? '').toString().toLowerCase();

    if (category == 'strength') {
      final value = item['value'];
      if (value == null) return '-';
      final text = value.toString();
      if (text.endsWith('.0')) {
        return '${text.substring(0, text.length - 2)} KG';
      }
      return '$text KG';
    }

    final score = (item['score_text'] ?? '').toString().trim();
    if (score.isNotEmpty) return score;

    final value = item['value'];
    final unit = (item['unit'] ?? '').toString().trim();
    if (value == null) return '-';
    return unit.isEmpty ? value.toString() : '${value.toString()} $unit';
  }

  List<String> _movementOptionsFor(String category) {
    switch (category) {
      case 'Strength':
        return _strengthMovements;
      case 'Benchmark':
        return _benchmarks;
      case 'Open':
        return _opens;
      default:
        return _strengthMovements;
    }
  }

  int get _strengthCount => personalRecords
      .where(
        (e) => (e['category'] ?? '').toString().toLowerCase() == 'strength',
      )
      .length;

  List<Map<String, dynamic>> get _filteredRecords {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return personalRecords;
    return personalRecords.where((item) {
      final movement = (item['movement'] ?? '').toString().toLowerCase();
      final category = (item['category'] ?? '').toString().toLowerCase();
      final notes = (item['notes'] ?? '').toString().toLowerCase();
      return movement.contains(q) || category.contains(q) || notes.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredMilestones {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return milestoneItems;
    return milestoneItems.where((item) {
      final title = (item['title'] ?? '').toString().toLowerCase();
      final subtitle = (item['subtitle'] ?? '').toString().toLowerCase();
      return title.contains(q) || subtitle.contains(q);
    }).toList();
  }

  Future<void> _deletePr(String id) async {
    try {
      await _repo.deletePr(id);
      await _load();
      if (!mounted) return;
      _toast('Record deleted');
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    DateTime selectedDate =
        DateTime.tryParse(controller.text.trim()) ?? DateTime.now();

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
                                    'Date',
                                    style: _font(
                                      24,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFF111318),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Choose the record date.',
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
                          'Select Date',
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
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  child: CupertinoDatePicker(
                                    mode: CupertinoDatePickerMode.date,
                                    initialDateTime: selectedDate,
                                    minimumDate: DateTime(2020),
                                    maximumDate: DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                    ),
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
                                DateFormat('d MMMM yyyy').format(selectedDate),
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
                              'Save Changes',
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

    if (picked == null) return;

    controller.text =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  void _showCreatePrModal() {
    _showRecordModal(title: 'Add Record', primaryText: 'Create');
  }

  void _showEditPrModal(Map<String, dynamic> item) {
    _showRecordModal(title: 'Edit Record', primaryText: 'Update', item: item);
  }

  void _showPrActions(Map<String, dynamic> item) {
    final tag = (item['category'] ?? 'Record').toString();
    final title = (item['movement'] ?? 'Record').toString();
    final value = _recordValue(item);

    Widget actionTile({
      required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback? onTap,
      Color iconBg = const Color(0xFFF3F4F6),
      Color iconColor = const Color(0xFF111318),
      Color titleColor = const Color(0xFF111318),
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECF1)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        letterSpacing: -0.15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.barlowCondensed(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8F96A3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF98A2B3),
                size: 22,
              ),
            ],
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7F9),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7DBE1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFEAECEF)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _categoryColor(tag).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            tag.toUpperCase(),
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: _categoryColor(tag),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.toUpperCase(),
                                style: GoogleFonts.barlowCondensed(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111318),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                value,
                                style: GoogleFonts.barlowCondensed(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF8F96A3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Record actions',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8F96A3),
                    ),
                  ),
                  const SizedBox(height: 10),
                  actionTile(
                    icon: Icons.edit_rounded,
                    title: 'Edit record',
                    subtitle: 'Update movement, score and date',
                    iconBg: const Color(0xFFF7F3EA),
                    iconColor: const Color(0xFFB59B6A),
                    onTap: () {
                      Navigator.pop(context);
                      _showEditPrModal(item);
                    },
                  ),
                  const SizedBox(height: 10),
                  actionTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Delete record',
                    subtitle: 'Remove this record from your profile',
                    iconBg: const Color(0xFFFEE4E2),
                    iconColor: const Color(0xFFE11D48),
                    titleColor: const Color(0xFFE11D48),
                    onTap: () async {
                      Navigator.pop(context);
                      await _deletePr(item['id'].toString());
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRecordModal({
    required String title,
    required String primaryText,
    Map<String, dynamic>? item,
  }) {
    final isEdit = item != null;

    String selectedCategory = (item?['category'] ?? 'Strength').toString();
    if (!_categories.contains(selectedCategory)) {
      selectedCategory = 'Strength';
    }

    final movementCtrl = TextEditingController(
      text: (item?['movement'] ?? '').toString(),
    );
    final weightCtrl = TextEditingController(
      text: selectedCategory == 'Strength' && item?['value'] != null
          ? item!['value'].toString().replaceAll('.0', '')
          : '',
    );
    final scoreCtrl = TextEditingController(
      text: (item?['score_text'] ?? '').toString(),
    );
    final dateCtrl = TextEditingController(
      text: (item?['achieved_on'] ?? '').toString(),
    );
    final notesCtrl = TextEditingController(
      text: (item?['notes'] ?? '').toString(),
    );

    if (dateCtrl.text.trim().isEmpty) {
      final now = DateTime.now();
      dateCtrl.text =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }

    if (movementCtrl.text.trim().isEmpty) {
      movementCtrl.text = _movementOptionsFor(selectedCategory).first;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(sheetContext).unfocus(),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset, top: 32),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF6F7F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: StatefulBuilder(
                    builder: (context, setLocalState) {
                      final options = _movementOptionsFor(selectedCategory);
                      if (!options.contains(movementCtrl.text.trim())) {
                        movementCtrl.text = options.first;
                      }

                      final isStrength = selectedCategory == 'Strength';

                      InputDecoration dropDeco(String label) {
                        return InputDecoration(
                          labelText: label,
                          labelStyle: GoogleFonts.barlowCondensed(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8F96A3),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFB59B6A),
                              width: 1.2,
                            ),
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.only(bottom: bottomInset + 24),
                        child: Column(
                          children: [
                            Container(
                              width: 42,
                              height: 5,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD7DBE1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        'RECORDS',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.barlowCondensed(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF111318),
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        title.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.barlowCondensed(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF8F96A3),
                                          letterSpacing: 0.5,
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
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                18,
                                18,
                                18,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: const Color(0xFFEAECEF),
                                ),
                              ),
                              child: Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    initialValue: selectedCategory,
                                    decoration: dropDeco('Category'),
                                    items: _categories
                                        .map(
                                          (c) => DropdownMenuItem<String>(
                                            value: c,
                                            child: Text(
                                              c,
                                              style:
                                                  GoogleFonts.barlowCondensed(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(
                                                      0xFF111318,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    style: GoogleFonts.barlowCondensed(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF111318),
                                    ),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setLocalState(() {
                                        selectedCategory = value;
                                        movementCtrl.text = _movementOptionsFor(
                                          selectedCategory,
                                        ).first;
                                        weightCtrl.clear();
                                        scoreCtrl.clear();
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    initialValue: movementCtrl.text.trim(),
                                    decoration: dropDeco(
                                      selectedCategory == 'Strength'
                                          ? 'Movement'
                                          : (selectedCategory == 'Benchmark'
                                                ? 'Benchmark'
                                                : 'Open Workout'),
                                    ),
                                    items: options
                                        .map(
                                          (m) => DropdownMenuItem<String>(
                                            value: m,
                                            child: Text(
                                              m,
                                              style:
                                                  GoogleFonts.barlowCondensed(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(
                                                      0xFF111318,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    style: GoogleFonts.barlowCondensed(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF111318),
                                    ),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setLocalState(() {
                                        movementCtrl.text = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  if (isStrength)
                                    InputField(
                                      label: 'Weight (kg)',
                                      controller: weightCtrl,
                                      hint: '100',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d{0,2}'),
                                        ),
                                      ],
                                      fillColor: Colors.white,
                                      borderColor: const Color(0xFFE2E8F0),
                                      focusedBorderColor: const Color(
                                        0xFFB59B6A,
                                      ),
                                      radius: 16,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      labelStyle: GoogleFonts.barlowCondensed(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF111318),
                                      ),
                                      hintStyle: GoogleFonts.barlowCondensed(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF98A2B3),
                                      ),
                                      textStyle: GoogleFonts.barlowCondensed(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF111318),
                                      ),
                                    )
                                  else
                                    InputField(
                                      label: 'Score',
                                      controller: scoreCtrl,
                                      hint: '7:32',
                                      fillColor: Colors.white,
                                      borderColor: const Color(0xFFE2E8F0),
                                      focusedBorderColor: const Color(
                                        0xFFB59B6A,
                                      ),
                                      radius: 16,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      labelStyle: GoogleFonts.barlowCondensed(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF111318),
                                      ),
                                      hintStyle: GoogleFonts.barlowCondensed(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF98A2B3),
                                      ),
                                      textStyle: GoogleFonts.barlowCondensed(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF111318),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () async {
                                      await _pickDate(dateCtrl);
                                      setLocalState(() {});
                                    },
                                    child: AbsorbPointer(
                                      child: InputField(
                                        label: 'Date',
                                        textStyle: _font(
                                          16,
                                          weight: FontWeight.w600,
                                          color: const Color(0xFF111318),
                                        ),
                                        readOnly: true,
                                        suffixIcon: const Icon(
                                          Icons.calendar_today_rounded,
                                          color: Color(0xFF98A2B3),
                                        ),
                                        controller: dateCtrl,
                                        hint: '2026-03-18',
                                        fillColor: Colors.white,
                                        borderColor: const Color(0xFFE2E8F0),
                                        focusedBorderColor: const Color(
                                          0xFFB59B6A,
                                        ),
                                        radius: 16,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  InputField(
                                    label: 'Notes',
                                    controller: notesCtrl,
                                    hint: 'Optional notes',
                                    maxLines: 4,
                                    fillColor: Colors.white,
                                    borderColor: const Color(0xFFE2E8F0),
                                    focusedBorderColor: const Color(0xFFB59B6A),
                                    radius: 16,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    labelStyle: GoogleFonts.barlowCondensed(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF111318),
                                    ),
                                    hintStyle: GoogleFonts.barlowCondensed(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF98A2B3),
                                    ),
                                    textStyle: GoogleFonts.barlowCondensed(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF111318),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: SecondaryButton(
                                    text: 'Cancel',
                                    radius: 18,
                                    height: 58,
                                    backgroundColor: const Color(0xFFE5E7EB),
                                    pressedColor: const Color(0xFFD9DDE3),
                                    textStyle: GoogleFonts.barlowCondensed(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF475467),
                                      letterSpacing: -0.1,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: PrimaryButton(
                                    text: primaryText == 'Create'
                                        ? 'Create Record'
                                        : 'Update Record',
                                    radius: 18,
                                    height: 58,
                                    backgroundColor: const Color(0xFFB59B6A),
                                    pressedColor: const Color(0xFFA88C59),
                                    disabledColor: const Color(0xFFC9C9C9),
                                    boxShadow: const [],
                                    textStyle: GoogleFonts.barlowCondensed(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.1,
                                    ),
                                    onPressed: () async {
                                      final movement = movementCtrl.text.trim();
                                      final achievedOn = dateCtrl.text.trim();
                                      final notes = notesCtrl.text.trim();

                                      if (movement.isEmpty) {
                                        _toast(
                                          'Movement is required',
                                          isError: true,
                                        );
                                        return;
                                      }

                                      if (achievedOn.isEmpty) {
                                        _toast(
                                          'Date is required',
                                          isError: true,
                                        );
                                        return;
                                      }

                                      try {
                                        if (isStrength) {
                                          final weight = num.tryParse(
                                            weightCtrl.text.trim(),
                                          );
                                          if (weight == null) {
                                            throw Exception(
                                              'Enter a valid weight in kg',
                                            );
                                          }

                                          if (isEdit) {
                                            await _repo.updatePr(
                                              id: item['id'].toString(),
                                              category: selectedCategory,
                                              movement: movement,
                                              value: weight,
                                              unit: 'kg',
                                              scoreText: null,
                                              achievedOn: achievedOn,
                                              notes: notes.isEmpty
                                                  ? null
                                                  : notes,
                                            );
                                          } else {
                                            await _repo.createPr(
                                              category: selectedCategory,
                                              movement: movement,
                                              value: weight,
                                              unit: 'kg',
                                              scoreText: null,
                                              achievedOn: achievedOn,
                                              notes: notes.isEmpty
                                                  ? null
                                                  : notes,
                                            );
                                          }
                                        } else {
                                          final score = scoreCtrl.text.trim();
                                          if (score.isEmpty) {
                                            throw Exception(
                                              'Score is required',
                                            );
                                          }

                                          if (isEdit) {
                                            await _repo.updatePr(
                                              id: item['id'].toString(),
                                              category: selectedCategory,
                                              movement: movement,
                                              value: 0,
                                              unit: 'score',
                                              scoreText: score,
                                              achievedOn: achievedOn,
                                              notes: notes.isEmpty
                                                  ? null
                                                  : notes,
                                            );
                                          } else {
                                            await _repo.createPr(
                                              category: selectedCategory,
                                              movement: movement,
                                              value: 0,
                                              unit: 'score',
                                              scoreText: score,
                                              achievedOn: achievedOn,
                                              notes: notes.isEmpty
                                                  ? null
                                                  : notes,
                                            );
                                          }
                                        }

                                        if (!mounted) return;
                                        Navigator.pop(sheetContext);
                                        await _load();
                                        if (!mounted) return;
                                        _toast(
                                          isEdit
                                              ? 'Record updated'
                                              : 'Record created',
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        _toast(
                                          e.toString().replaceFirst(
                                            'Exception: ',
                                            '',
                                          ),
                                          isError: true,
                                        );
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
            ),
          ),
        );
      },
    );
  }

  Widget _prCard(Map<String, dynamic> item) {
    final tag = (item['category'] ?? 'Record').toString();
    final title = (item['movement'] ?? 'Record').toString();
    final value = _recordValue(item);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MiniTag(text: tag, color: _categoryColor(tag)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _PressableIconButton(
                  icon: Icons.more_horiz_rounded,
                  color: const Color(0xFF667085),
                  onTap: () => _showPrActions(item),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 21,
                    height: 0.98,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111318),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                value,
                style: GoogleFonts.barlowCondensed(
                  fontSize: 22,
                  height: 0.95,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111318),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _milestoneCard(Map<String, dynamic> item) {
    final emoji = (item['emoji'] ?? '🏅').toString();
    final title = (item['title'] ?? 'Achievement').toString();
    final subtitle = (item['subtitle'] ?? '').toString();
    final date = _formatDate(item['awarded_on']);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3EA),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111318),
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 15,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475467),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF98A2B3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsCount = personalRecords.length.toString();
    final milestonesCount = milestoneItems.length.toString();
    final strengthCount = _strengthCount.toString();

    final records = _filteredRecords;
    final milestonesList = _filteredMilestones;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                child: SizedBox(
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'RECORDS',
                              style: _font(
                                17,
                                weight: FontWeight.w800,
                                color: const Color(0xFF0E0E11),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              milestones ? 'BENCHMARKS' : 'PERSONAL RECORDS',
                              style: _font(
                                11,
                                weight: FontWeight.w500,
                                color: const Color(0xFF8F96A3),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              size: 28,
                              color: Color(0xFFB59B6A),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _showCreatePrModal,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F3EA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                size: 20,
                                color: Color(0xFFB59B6A),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEAECEF)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                milestones = false;
                              });
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: !milestones
                                    ? const Color(0xFFB59B6A)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'PERSONAL RECORDS',
                                style: GoogleFonts.barlowCondensed(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: !milestones
                                      ? Colors.white
                                      : const Color(0xFF111318),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                milestones = true;
                              });
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: milestones
                                    ? const Color(0xFFB59B6A)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'BENCHMARKS',
                                style: GoogleFonts.barlowCondensed(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: milestones
                                      ? Colors.white
                                      : const Color(0xFF111318),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SearchField(
                    hint: milestones
                        ? 'Search benchmark workouts...'
                        : 'Search personal records...',
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFB42318)),
                    )
                  else ...[
                    if (!milestones) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            _CountPill(label: '$recordsCount Records'),
                            const SizedBox(width: 8),
                            _CountPill(label: '$strengthCount Strength'),
                          ],
                        ),
                      ),
                      if (records.isEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text(
                              'No records yet.',
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF667085),
                              ),
                            ),
                          ),
                        )
                      else
                        ...List.generate(records.length, (i) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: i == records.length - 1 ? 0 : 14,
                            ),
                            child: _prCard(records[i]),
                          );
                        }),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            _CountPill(label: '$milestonesCount Achievements'),
                          ],
                        ),
                      ),
                      if (milestonesList.isEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text(
                              'No benchmark workouts yet.',
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF667085),
                              ),
                            ),
                          ),
                        )
                      else
                        ...List.generate(milestonesList.length, (i) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: i == milestonesList.length - 1 ? 0 : 14,
                            ),
                            child: _milestoneCard(milestonesList[i]),
                          );
                        }),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final String label;

  _CountPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.barlowCondensed(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: const Color(0xFF667085),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;

  _MiniTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.barlowCondensed(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}

class _PressableIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PressableIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 19),
      ),
    );
  }
}
