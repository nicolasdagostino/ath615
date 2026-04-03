import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_bootstrap.dart';
import '../../core/supabase/workout_comment_repository.dart';
import '../../core/supabase/workout_like_repository.dart';
import '../../core/supabase/workout_repository.dart';
import '../../core/supabase/profile_repository.dart';
import '../../l10n/app_text.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/role_guard.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? initialWorkout;
  final String? workoutId;

  const WorkoutDetailScreen({super.key, this.initialWorkout, this.workoutId});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  final _repo = WorkoutRepository();
  final _profileRepo = ProfileRepository();
  final _commentRepo = WorkoutCommentRepository();
  final _likeRepo = WorkoutLikeRepository();

  RealtimeChannel? _channel;

  bool _loading = true;
  bool _posting = false;
  String? _error;
  String _currentUserAvatarUrl = '';

  Map<String, dynamic>? _workout;
  List<Map<String, dynamic>> _comments = [];
  bool _isLiked = false;

  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _workout = widget.initialWorkout;
    _loadCurrentUserAvatar();
    _subscribeRealtime();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
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
    final id = widget.workoutId ?? widget.initialWorkout?['id']?.toString();
    if (id == null || id.isEmpty) return;

    _channel = sb.channel('workout-detail-$id')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'workout_comments',
        callback: (payload) {
          final record = payload.newRecord;
          final oldRecord = payload.oldRecord;
          final newWorkoutId = record['workout_id']?.toString();
          final oldWorkoutId = oldRecord['workout_id']?.toString();
          if (newWorkoutId == id || oldWorkoutId == id) {
            _load();
          }
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'workout_likes',
        callback: (payload) {
          final record = payload.newRecord;
          final oldRecord = payload.oldRecord;
          final newWorkoutId = record['workout_id']?.toString();
          final oldWorkoutId = oldRecord['workout_id']?.toString();
          if (newWorkoutId == id || oldWorkoutId == id) {
            _load();
          }
        },
      )
      ..subscribe();
  }

  Future<void> _loadCurrentUserAvatar() async {
    try {
      final profile = await _profileRepo.getMyProfile();
      if (!mounted || profile == null) return;

      final avatarUrl = (profile['avatar_url'] ?? '').toString().trim();
      if (avatarUrl == _currentUserAvatarUrl) return;

      setState(() {
        _currentUserAvatarUrl = avatarUrl;
      });
    } catch (_) {}
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

  String _timeAgo(BuildContext context, DateTime dt) {
    final t = context.appText;
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return t.justNow;
    if (diff.inHours < 1) return t.minutesAgoShort(diff.inMinutes);
    if (diff.inDays < 1) return t.hoursAgoShort(diff.inHours);
    if (diff.inDays < 7) return t.daysAgoShort(diff.inDays);
    return DateFormat('MMM d').format(dt);
  }

  Future<void> _load() async {
    try {
      final t = context.appText;
      final initialWorkout = _workout;
      Map<String, dynamic>? workout = initialWorkout;
      final targetId = widget.workoutId ?? initialWorkout?['id']?.toString();

      if (targetId == null || targetId.isEmpty) {
        throw Exception(t.workoutNotFound);
      }

      final fetched = await _repo.getWorkoutById(targetId);
      workout = fetched ?? initialWorkout;

      if (workout == null) {
        throw Exception(t.workoutNotFound);
      }

      final comments = await _commentRepo.listCommentsForWorkout(targetId);
      final liked = await _likeRepo.hasLiked(targetId);

      if (!mounted) return;
      setState(() {
        _workout = workout;
        _comments = comments;
        _isLiked = liked;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    final id = _workout?['id']?.toString();
    if (id == null || id.isEmpty) return;

    try {
      await _likeRepo.toggleLike(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _postComment() async {
    final id = _workout?['id']?.toString();
    if (id == null || id.isEmpty) return;

    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _posting = true;
    });

    try {
      await _commentRepo.createComment(workoutId: id, comment: text);
      _commentCtrl.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _posting = false;
        });
      }
    }
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

  Widget _imageSection(String imageUrl) {
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
    required String avatarUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: avatarColor,
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? const Icon(Icons.person, size: 16, color: Colors.white)
                : null,
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

  Widget _commentComposer() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFF0F766E),
          backgroundImage: _currentUserAvatarUrl.isNotEmpty
              ? NetworkImage(_currentUserAvatarUrl)
              : null,
          child: _currentUserAvatarUrl.isEmpty
              ? const Icon(Icons.person, size: 16, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 10),
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
                  controller: _commentCtrl,
                  maxLines: 1,
                  autofocus: false,
                  enableSuggestions: true,
                  autocorrect: true,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!_posting) _postComment();
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: context.appText.writeAComment,
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
            text: _posting ? '...' : context.appText.post,
            onTap: _posting ? () {} : _postComment,
          ),
        ),
      ],
    );
  }

  Widget _brandLogo() {
    return SizedBox(
      width: 110,
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
    final subtitle = _workout == null
        ? context.appText.workoutDetails
        : DateFormat('EEEE, MMMM d').format(
            DateTime.tryParse((_workout?['workout_date'] ?? '').toString()) ??
                DateTime.now(),
          );

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
                          context.appText.workoutDetailUpper,
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
                    child: SizedBox(
                      width: 132,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: const SizedBox(
                              width: 34,
                              height: 34,
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: Color(0xFF111318),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _brandLogo(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(width: 132),
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

  @override
  Widget build(BuildContext context) {
    final workout = _workout;

    if (_loading && workout == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (workout == null) {
      return Scaffold(
        body: Column(
          children: [
            _topHeader(),
            Expanded(
              child: Center(
                child: Text(
                  _error ?? context.appText.workoutNotFound,
                  style: _font(
                    16,
                    weight: FontWeight.w500,
                    color: const Color(0xFF667085),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final program = (workout['program_name'] ?? context.appText.workout)
        .toString();
    final author = (workout['created_by_name'] ?? context.appText.athlete615)
        .toString();
    final dateIso = (workout['workout_date'] ?? '').toString();
    final description = (workout['description'] ?? '').toString().trim();
    final type = (workout['workout_type'] ?? '').toString().trim();
    final imageUrl = (workout['image_url'] ?? '').toString();
    final likes = (workout['likes_count'] ?? 0).toString();
    final commentsCount = _comments.length.toString();

    String formattedDate = dateIso;
    try {
      final d = DateTime.parse(dateIso);
      formattedDate = DateFormat('MMMM d, yyyy').format(d);
    } catch (_) {}

    return Scaffold(
      body: Column(
        children: [
          _topHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                children: [
                  AppCard(
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
                        if (type.isNotEmpty) ...[
                          const SizedBox(height: 14),
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
                        _imageSection(imageUrl),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              context.appText.likesCount(likes),
                              style: _font(
                                12,
                                weight: FontWeight.w500,
                                color: const Color(0xFF8F96A3),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              context.appText.commentsCount(commentsCount),
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
                              icon: _isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              label: context.appText.like,
                              iconColor: _isLiked
                                  ? const Color(0xFFE11D48)
                                  : const Color(0xFF667085),
                              onTap: _toggleLike,
                            ),
                            _socialAction(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: context.appText.commentLabel,
                              iconColor: const Color(0xFF667085),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(height: 0.6, color: const Color(0xFFF1F3F6)),
                        const SizedBox(height: 14),
                        if (_comments.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                context.appText.noCommentsYet,
                                style: _font(
                                  12,
                                  weight: FontWeight.w500,
                                  color: const Color(0xFF98A2B3),
                                ),
                              ),
                            ),
                          )
                        else
                          ..._comments.map((comment) {
                            final name =
                                (comment['author_name'] ??
                                        context.appText.athleteFallback)
                                    .toString();
                            final text = (comment['comment'] ?? '').toString();

                            DateTime createdAt = DateTime.now();
                            try {
                              createdAt = DateTime.parse(
                                comment['created_at'].toString(),
                              ).toLocal();
                            } catch (_) {}

                            final avatarUrl =
                                (comment['author_avatar_url'] ?? '')
                                    .toString()
                                    .trim();

                            return _commentBubble(
                              name: name,
                              text: text,
                              timeAgo: _timeAgo(context, createdAt),
                              avatarColor: const Color(0xFF0F766E),
                              avatarUrl: avatarUrl,
                            );
                          }),
                        _commentComposer(),
                      ],
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
