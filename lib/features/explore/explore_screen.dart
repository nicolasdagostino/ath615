import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/supabase/workout_repository.dart';
import '../../shared/widgets/app_card.dart';
import '../workouts/workout_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _repo = WorkoutRepository();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  String _mode = 'recent';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
      final items = await _repo.searchExploreWorkouts(
        mode: _mode,
        query: _searchCtrl.text,
      );
      if (!mounted) return;
      if (mounted) {}

      setState(() {
        _items = items;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load workouts';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Color _programColor(String name) {
    switch (name.toLowerCase()) {
      case 'crossfit':
        return const Color(0xFFB59B6A);
      case 'strength':
        return const Color(0xFF8E95A3);
      case 'payhim 30':
        return const Color(0xFFB08D57);
      case 'olympic lifting':
        return const Color(0xFF6F8F7A);
      case 'hyrox':
        return const Color(0xFF8A90A0);
      default:
        return const Color(0xFFB59B6A);
    }
  }

  Color _programChipBg(String name) {
    switch (name.toLowerCase()) {
      case 'crossfit':
      case 'payhim 30':
        return const Color(0xFFF7F3EA);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Widget _brandLogo() {
    return SizedBox(
      width: 132,
      child: Text(
        'ATHLETE LAB',
        style: _font(
          18,
          weight: FontWeight.w800,
          color: const Color(0xFF0E0E11),
          letterSpacing: -0.3,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _topHeader() {
    final title = _mode == 'popular' ? 'POPULAR WORKOUTS' : 'EXPLORE WORKOUTS';
    final subtitle = _mode == 'popular'
        ? 'Browse the most liked workouts'
        : 'Search recent and benchmark workouts';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
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
                          title,
                          style: _font(
                            18,
                            weight: FontWeight.w800,
                            color: const Color(0xFF0E0E11),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: _font(
                            12,
                            weight: FontWeight.w500,
                            color: const Color(0xFF8F96A3),
                            letterSpacing: 0.3,
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
                      child: _brandLogo(),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: 132,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F3EA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.search_rounded,
                            size: 19,
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
        ],
      ),
    );
  }

  Widget _segment() {
    final isRecent = _mode == 'recent';

    return Container(
      width: double.infinity,
      height: 52,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_mode == 'recent') return;
                setState(() => _mode = 'recent');
                _load();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: isRecent
                      ? const Color(0xFF111318)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  'RECENT',
                  style: _font(
                    13,
                    weight: isRecent ? FontWeight.w700 : FontWeight.w500,
                    color: isRecent ? Colors.white : const Color(0xFF8F96A3),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_mode == 'popular') return;
                setState(() => _mode = 'popular');
                _load();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: !isRecent
                      ? const Color(0xFFB59B6A)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  'POPULAR',
                  style: _font(
                    13,
                    weight: !isRecent ? FontWeight.w700 : FontWeight.w500,
                    color: !isRecent ? Colors.white : const Color(0xFF8F96A3),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _search() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE3E7ED), width: 1.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF8F96A3), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search workouts',
                hintStyle: _font(
                  13,
                  weight: FontWeight.w500,
                  color: const Color(0xFF98A2B3),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: _font(
                13,
                weight: FontWeight.w500,
                color: const Color(0xFF111318),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterHeader() {
    final title = _mode == 'popular' ? 'Popular workouts' : 'Recent workouts';
    return Text(
      title.toUpperCase(),
      style: _font(
        15,
        weight: FontWeight.w700,
        color: const Color(0xFF111318),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _resultCount() {
    final benchmarkCount = _items
        .where((e) => e['is_benchmark'] == true)
        .length;
    final text = _mode == 'popular'
        ? '${_items.length} results · $benchmarkCount benchmarks'
        : '${_items.length} results';

    return Text(
      text,
      style: _font(12, weight: FontWeight.w500, color: const Color(0xFF8F96A3)),
    );
  }

  Widget _imageSection(Map<String, dynamic> item) {
    final imageUrl = (item['image_url'] ?? '').toString();
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 190,
          width: double.infinity,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          ),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF1F2937)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.fitness_center_rounded,
          color: Colors.white70,
          size: 40,
        ),
      ),
    );
  }

  String _resolvedTitle(Map<String, dynamic> item) {
    final program = (item['program_name'] ?? 'Workout').toString().trim();
    final rawTitle = (item['title'] ?? 'Workout').toString().trim();
    final rawDate = (item['workout_date'] ?? '').toString();

    if (rawTitle.isEmpty) return program;

    final digitsOnly = rawTitle.replaceAll(RegExp(r'\D'), '');
    final dateDigits = rawDate.replaceAll('-', '');

    if (digitsOnly == dateDigits) return program;

    return rawTitle;
  }

  Widget _card(Map<String, dynamic> item) {
    final program = (item['program_name'] ?? 'Workout').toString();
    final title = _resolvedTitle(item);
    final description = (item['description'] ?? '').toString().trim();
    final likes = (item['likes_count'] ?? 0).toString();
    final comments = (item['comments_count'] ?? 0).toString();
    final isBenchmark = item['is_benchmark'] == true;

    String date = '';
    try {
      date = DateFormat(
        'MMMM d, yyyy',
      ).format(DateTime.parse(item['workout_date'].toString()));
    } catch (_) {
      date = (item['workout_date'] ?? '').toString();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkoutDetailScreen(
                initialWorkout: item,
                workoutId: item['id']?.toString(),
              ),
            ),
          );
        },
        child: AppCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _imageSection(item),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _programChipBg(program),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      program.toUpperCase(),
                      style: _font(
                        11,
                        weight: FontWeight.w700,
                        color: _programColor(program),
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                  if (isBenchmark)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F3EA),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'BENCHMARK',
                        style: _font(
                          11,
                          weight: FontWeight.w700,
                          color: const Color(0xFFB59B6A),
                          letterSpacing: 0.9,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                date,
                style: _font(
                  12,
                  weight: FontWeight.w500,
                  color: const Color(0xFF8F96A3),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: _font(
                  24,
                  weight: FontWeight.w800,
                  color: const Color(0xFF111318),
                  letterSpacing: -0.7,
                  height: 1.0,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: _font(
                    14,
                    weight: FontWeight.w500,
                    color: const Color(0xFF667085),
                    height: 1.18,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '$likes likes',
                    style: _font(
                      12,
                      weight: FontWeight.w500,
                      color: const Color(0xFF8F96A3),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '$comments comments',
                    style: _font(
                      12,
                      weight: FontWeight.w500,
                      color: const Color(0xFF8F96A3),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: Color(0xFF98A2B3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeletonLine({
    double? width,
    double height = 12,
    double radius = 999,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEAECEF),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _skeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skeletonLine(width: 110, height: 12),
          const SizedBox(height: 12),
          _skeletonLine(width: double.infinity, height: 22, radius: 8),
          const SizedBox(height: 10),
          _skeletonLine(width: 180, height: 14, radius: 8),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5F7),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: 16),
          _skeletonLine(width: double.infinity, height: 12, radius: 8),
          const SizedBox(height: 8),
          _skeletonLine(width: 220, height: 12, radius: 8),
        ],
      ),
    );
  }

  List<Widget> _skeletonList({int count = 3}) {
    return List.generate(count, (_) => _skeletonCard());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _topHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFFB59B6A),
              backgroundColor: Colors.white,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                children: [
                  _search(),
                  const SizedBox(height: 14),
                  _segment(),
                  const SizedBox(height: 18),
                  _filterHeader(),
                  const SizedBox(height: 4),
                  _resultCount(),
                  const SizedBox(height: 18),
                  if (_loading) ...[
                    const SizedBox(height: 4),
                    ..._skeletonList(),
                  ] else if (_error != null)
                    Text(
                      _error!,
                      style: _font(
                        14,
                        weight: FontWeight.w500,
                        color: const Color(0xFFB42318),
                      ),
                    )
                  else if (_items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          'No workouts found',
                          style: _font(
                            16,
                            weight: FontWeight.w500,
                            color: const Color(0xFF667085),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._items.map(_card),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
