import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_bootstrap.dart';
import '../../core/supabase/workout_comment_repository.dart';
import '../../core/supabase/workout_like_repository.dart';
import '../../core/supabase/workout_repository.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/role_guard.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final _repo = WorkoutRepository();
  final _commentRepo = WorkoutCommentRepository();
  final _likeRepo = WorkoutLikeRepository();

  RealtimeChannel? _channel;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _workouts = [];
  final Map<String, List<Map<String, dynamic>>> _commentsByWorkout = {};
  final Map<String, bool> _likedByWorkout = {};
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _postingWorkoutIds = {};

  @override
  void initState() {
    super.initState();
    _subscribeRealtime();
    _loadToday();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    if (_channel != null) {
      sb.removeChannel(_channel!);
    }
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

  void _subscribeRealtime() {
    _channel = sb.channel('workouts-today-feed')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'workout_comments',
        callback: (_) {
          _loadToday();
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'workout_likes',
        callback: (_) {
          _loadToday();
        },
      )
      ..subscribe();
  }

  String _todayIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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

  Future<void> _loadToday() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _repo.listWorkoutsByDate(_todayIso());

      final commentsMap = <String, List<Map<String, dynamic>>>{};
      final likedMap = <String, bool>{};

      for (final item in items) {
        final workoutId = item['id']?.toString();
        if (workoutId == null) continue;
        final comments = await _commentRepo.listCommentsForWorkout(workoutId);
        final liked = await _likeRepo.hasLiked(workoutId);
        commentsMap[workoutId] = comments;
        likedMap[workoutId] = liked;
        _controllers.putIfAbsent(workoutId, () => TextEditingController());
      }

      if (!mounted) return;
      if (mounted) {}

      setState(() {
        _workouts = items;
        _commentsByWorkout
          ..clear()
          ..addAll(commentsMap);
        _likedByWorkout
          ..clear()
          ..addAll(likedMap);
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

  Future<void> _postComment(String workoutId) async {
    final controller = _controllers.putIfAbsent(
      workoutId,
      () => TextEditingController(),
    );
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _postingWorkoutIds.add(workoutId);
    });

    try {
      await _commentRepo.createComment(workoutId: workoutId, comment: text);

      controller.clear();
      final comments = await _commentRepo.listCommentsForWorkout(workoutId);

      if (!mounted) return;
      setState(() {
        _commentsByWorkout[workoutId] = comments;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _postingWorkoutIds.remove(workoutId);
        });
      }
    }
  }

  Future<void> _toggleLike(String workoutId) async {
    try {
      await _likeRepo.toggleLike(workoutId);

      final liked = await _likeRepo.hasLiked(workoutId);
      final refreshed = await _repo.listWorkoutsByDate(_todayIso());

      if (!mounted) return;
      setState(() {
        _likedByWorkout[workoutId] = liked;
        _workouts = refreshed;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _imageSection(Map<String, dynamic> item) {
    final imageUrl = (item['image_url'] ?? '').toString();
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
          ),
        ),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 220,
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
          size: 42,
        ),
      ),
    );
  }

  Widget _socialAction({
    required IconData icon,
    required String label,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: iconColor),
              const SizedBox(width: 7),
              Text(
                label.toUpperCase(),
                style: _font(
                  12,
                  weight: FontWeight.w700,
                  color: iconColor,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _commentBubble({
    required String name,
    required String text,
    required String timeAgo,
    required Color avatarColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: avatarColor,
            child: const Icon(Icons.person, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: _font(
                      14,
                      weight: FontWeight.w700,
                      color: const Color(0xFF111318),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    text,
                    style: _font(
                      14,
                      weight: FontWeight.w500,
                      color: const Color(0xFF475467),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    timeAgo,
                    style: _font(
                      11,
                      weight: FontWeight.w500,
                      color: const Color(0xFF98A2B3),
                      letterSpacing: 0.4,
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

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  Widget _commentComposer(String workoutId) {
    final controller = _controllers.putIfAbsent(
      workoutId,
      () => TextEditingController(),
    );
    final posting = _postingWorkoutIds.contains(workoutId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFDDE1E7), width: 1.2),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.centerLeft,
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    isDense: true,
                    filled: false,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 1,
                  autofocus: false,
                  enableSuggestions: true,
                  autocorrect: true,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!posting) _postComment(workoutId);
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Write a comment...',
                    hintStyle: _font(
                      13,
                      weight: FontWeight.w500,
                      color: const Color(0xFF98A2B3),
                    ),
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                  style: _font(
                    13,
                    weight: FontWeight.w500,
                    color: const Color(0xFF111318),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 108,
          child: _MiniPostButton(
            text: posting ? '...' : 'Post',
            onTap: posting ? () {} : () => _postComment(workoutId),
          ),
        ),
      ],
    );
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
    final todayText = DateFormat('EEEE, MMMM d').format(DateTime.now());

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
                          "TODAY'S WORKOUTS",
                          style: _font(
                            18,
                            weight: FontWeight.w800,
                            color: const Color(0xFF0E0E11),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          todayText,
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
                            Icons.fitness_center_rounded,
                            size: 18,
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

  bool _looksLikeSectionHeader(String raw) {
    final line = raw.trim().toLowerCase();
    if (line.isEmpty) return false;

    const exactHeaders = {
      'warm-up',
      'warm up',
      'strength',
      'skill',
      'accessory',
      'metcon',
      'conditioning',
      'cooldown',
      'mobility',
      'cash out',
      'cash-out',
      'finisher',
      'wod',
      'notes',
      'note',
    };

    if (exactHeaders.contains(line)) return true;
    if (line.endsWith(':') && line.length <= 24) return true;
    if (RegExp(r'^min\s*\d+$', caseSensitive: false).hasMatch(line)) {
      return true;
    }
    if (RegExp(r'^round\s*\d+$', caseSensitive: false).hasMatch(line)) {
      return true;
    }

    return false;
  }

  bool _looksLikeSeparator(String raw) {
    final line = raw.trim();
    if (line.isEmpty) return false;
    return RegExp(r'^[-_—–=]{3,}$').hasMatch(line);
  }

  bool _looksLikeLabelLine(String raw) {
    final line = raw.trim().toLowerCase();
    if (line.isEmpty) return false;

    if (RegExp(
      r'^(then|buy in|buy-in|cash out|cash-out|notes?):?$',
      caseSensitive: false,
    ).hasMatch(line)) {
      return true;
    }

    if (RegExp(
      r'^(men|women|rx|scaled):',
      caseSensitive: false,
    ).hasMatch(line)) {
      return true;
    }

    if (RegExp(
      r'^(for time|amrap|emom|every\s+\d+)',
      caseSensitive: false,
    ).hasMatch(line)) {
      return true;
    }

    return false;
  }

  Widget _wodLine(String line) {
    final trimmed = line.trim();

    if (_looksLikeSeparator(trimmed)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          width: 52,
          height: 2,
          decoration: BoxDecoration(
            color: const Color(0xFFD8DCE3),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
    }

    if (_looksLikeSectionHeader(trimmed)) {
      final clean = trimmed.endsWith(':')
          ? trimmed.substring(0, trimmed.length - 1)
          : trimmed;

      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 8),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: const Color(0xFFB59B6A),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                clean,
                style: _font(
                  16,
                  weight: FontWeight.w500,
                  color: const Color(0xFF344054),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_looksLikeLabelLine(trimmed)) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: Text(
          trimmed.endsWith(':') ? trimmed : '$trimmed:',
          style: _font(
            16,
            weight: FontWeight.w500,
            color: const Color(0xFF344054),
          ),
        ),
      );
    }

    final isBullet =
        trimmed.startsWith('- ') ||
        trimmed.startsWith('• ') ||
        trimmed.startsWith('* ');

    final display = isBullet ? trimmed.substring(2).trim() : trimmed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBullet) ...[
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF98A2B3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              display,
              style: _font(
                16,
                weight: FontWeight.w500,
                color: const Color(0xFF344054),
                height: 1.18,
                letterSpacing: -0.05,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _parsedDescription(String description) {
    final lines = description.replaceAll('\r\n', '\n').split('\n');

    if (lines.every((e) => e.trim().isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((raw) {
          if (raw.trim().isEmpty) {
            return const SizedBox(height: 8);
          }
          return _wodLine(raw);
        }).toList(),
      ),
    );
  }

  Widget _workoutCard(Map<String, dynamic> item) {
    final workoutId = item['id'].toString();
    final comments = _commentsByWorkout[workoutId] ?? [];

    final program = (item['program_name'] ?? 'Workout').toString();
    final author = (item['created_by_name'] ?? 'Athlete 615').toString();
    final dateIso = (item['workout_date'] ?? '').toString();

    String formattedDate = dateIso;
    try {
      final d = DateTime.parse(dateIso);
      formattedDate = DateFormat('MMMM d, yyyy').format(d);
    } catch (_) {}

    final description = (item['description'] ?? '').toString().trim();
    final type = (item['workout_type'] ?? '').toString().trim();

    final likes = (item['likes_count'] ?? 0).toString();
    final commentsCount = comments.length.toString();
    final isLiked = _likedByWorkout[workoutId] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE9EEF5),
                  child: const Icon(
                    Icons.person,
                    size: 20,
                    color: Color(0xFF8A90A0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: _font(
                          15,
                          weight: FontWeight.w700,
                          color: const Color(0xFF111318),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        formattedDate,
                        style: _font(
                          12,
                          weight: FontWeight.w500,
                          color: const Color(0xFF8F96A3),
                        ),
                      ),
                    ],
                  ),
                ),
                const RoleGuard(
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: Color(0xFF98A2B3),
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
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
            const SizedBox(height: 14),
            if (type.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                type.toUpperCase(),
                style: _font(
                  11,
                  weight: FontWeight.w700,
                  color: const Color(0xFF98A2B3),
                  letterSpacing: 1.1,
                ),
              ),
            ],
            if (description.isNotEmpty) ...[
              const SizedBox(height: 16),
              _parsedDescription(description),
            ],

            const SizedBox(height: 18),
            _imageSection(item),
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
                const Spacer(),
                Text(
                  '$commentsCount comments',
                  style: _font(
                    12,
                    weight: FontWeight.w500,
                    color: const Color(0xFF8F96A3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(height: 0.6, color: const Color(0xFFF1F3F6)),
            const SizedBox(height: 4),
            Row(
              children: [
                _socialAction(
                  icon: isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: 'Like',
                  iconColor: isLiked
                      ? const Color(0xFFE11D48)
                      : const Color(0xFF667085),
                  onTap: () => _toggleLike(workoutId),
                ),
                _socialAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Comment',
                  iconColor: const Color(0xFF667085),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(height: 0.6, color: const Color(0xFFF1F3F6)),
            const SizedBox(height: 14),
            if (comments.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No comments yet',
                    style: _font(
                      12,
                      weight: FontWeight.w500,
                      color: const Color(0xFF98A2B3),
                    ),
                  ),
                ),
              )
            else
              ...comments.map((comment) {
                final name = (comment['author_name'] ?? 'Athlete').toString();
                final text = (comment['comment'] ?? '').toString();

                DateTime createdAt = DateTime.now();
                try {
                  createdAt = DateTime.parse(
                    comment['created_at'].toString(),
                  ).toLocal();
                } catch (_) {}

                return _commentBubble(
                  name: name,
                  text: text,
                  timeAgo: _timeAgo(createdAt),
                  avatarColor: const Color(0xFF0F766E),
                );
              }),
            _commentComposer(workoutId),
          ],
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
        borderRadius: BorderRadius.circular(24),
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
            height: 220,
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
              onRefresh: _loadToday,
              color: const Color(0xFFB59B6A),
              backgroundColor: Colors.white,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                children: [
                  if (_loading) ...[
                    const SizedBox(height: 4),
                    ..._skeletonList(),
                  ] else if (_error != null)
                    Center(
                      child: Text(
                        _error!,
                        style: _font(
                          14,
                          weight: FontWeight.w500,
                          color: const Color(0xFFB42318),
                        ),
                      ),
                    )
                  else if (_workouts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                        child: Column(
                          children: [
                            Text(
                              'REST DAY',
                              textAlign: TextAlign.center,
                              style: _font(
                                28,
                                weight: FontWeight.w800,
                                color: const Color(0xFF111318),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "Resting is as important as work. Let your mind and body rest, do some mobility and stretching. Don't be tempted to train if you feel good.",
                              textAlign: TextAlign.center,
                              style: _font(
                                13,
                                weight: FontWeight.w500,
                                color: const Color(0xFF667085),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._workouts.map(_workoutCard),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPostButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _MiniPostButton({required this.text, required this.onTap});

  @override
  State<_MiniPostButton> createState() => _MiniPostButtonState();
}

class _MiniPostButtonState extends State<_MiniPostButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: double.infinity,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFB59B6A),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            widget.text.toUpperCase(),
            style: GoogleFonts.barlowCondensed(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
