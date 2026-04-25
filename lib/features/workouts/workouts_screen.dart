import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_bootstrap.dart';
import '../../core/supabase/workout_comment_repository.dart';
import '../../core/supabase/workout_like_repository.dart';
import '../../core/supabase/workout_repository.dart';
import '../../core/supabase/profile_repository.dart';
import '../../core/supabase/gym_repository.dart';
import '../../core/supabase/notification_repository.dart';
import '../../core/supabase/program_repository.dart';
import '../../core/supabase/storage_repository.dart';
import '../../core/auth/user_session.dart';
import 'widgets/create_workout_sheet.dart';
import '../../l10n/app_text.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/role_guard.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/app_bottom_sheet.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final _repo = WorkoutRepository();
  final _profileRepo = ProfileRepository();
  final _gymRepo = GymRepository();
  final _commentRepo = WorkoutCommentRepository();
  final _likeRepo = WorkoutLikeRepository();
  final _notificationRepo = NotificationRepository();
  final _programRepo = ProgramRepository();
  final _storageRepo = StorageRepository();

  RealtimeChannel? _channel;

  bool _loading = true;
  String? _error;
  String _currentUserAvatarUrl = '';
  String _gymName = '';
  String _gymLogoUrl = '';
  List<Map<String, dynamic>> _workouts = [];
  List<Map<String, dynamic>> _programs = [];
  final Map<String, List<Map<String, dynamic>>> _commentsByWorkout = {};
  final Map<String, bool> _likedByWorkout = {};
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _postingWorkoutIds = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAvatar();
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
      final gym = await _gymRepo.myGymInfo();
      final gymName = (gym?['name'] ?? '').toString().trim();
      final gymLogo = (gym?['logo_url'] ?? '').toString().trim();
      final gymId = (await _gymRepo.resolveGymId() ?? '').trim();
      final programs = gymId.isEmpty
          ? <Map<String, dynamic>>[]
          : await _programRepo.listPrograms(gymId);

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
        _programs = programs;
        _gymName = gymName;
        _gymLogoUrl = gymLogo;
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
        _error = context.appText.couldNotLoadWorkouts;
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
      AppToast.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
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

  String _programNameForId(String programId) {
    for (final program in _programs) {
      if ((program['id'] ?? '').toString() == programId) {
        return (program['name'] ?? '').toString().trim();
      }
    }
    return '';
  }

  Future<void> _showEditWorkoutSheet(Map<String, dynamic> item) async {
    final result = await showCreateWorkoutSheet(
      context,
      programs: _programs,
      onCreateProgram: _createProgramFromWorkoutSheet,
      item: item,
    );
    if (result == null) return;

    try {
      final gymId = (await _gymRepo.resolveGymId() ?? '').trim();
      if (gymId.isEmpty) {
        throw Exception(context.appText.gymIdRequiredError);
      }

      final id = item['id'].toString();
      final programId = (result['programId'] ?? '').toString().trim();
      final programName = (result['programName'] ?? '').toString().trim();
      final title = programName.isEmpty
          ? _programNameForId(programId)
          : programName;
      final description = (result['description'] ?? '').toString().trim();
      final workoutDate = (result['workoutDate'] ?? '').toString().trim();
      final imageFile = result['imageFile'];
      String imageUrl = (result['existingImageUrl'] ?? '').toString().trim();

      if (programId.isEmpty || title.isEmpty) {
        throw Exception(context.appText.programRequiredError);
      }
      if (workoutDate.isEmpty) {
        throw Exception(context.appText.workoutDateRequiredError);
      }

      if (imageFile != null) {
        imageUrl = await _storageRepo.uploadWorkoutImage(imageFile);
      }

      final existing = await _repo.findExistingWorkoutForProgramOnDate(
        gymId: gymId,
        programId: programId,
        workoutDate: workoutDate,
        excludeWorkoutId: id,
      );
      if (existing != null) {
        final existingTitle = (existing['title'] ?? 'Workout')
            .toString()
            .trim();
        throw Exception(
          context.appText.duplicateWorkoutForProgramDateError(existingTitle),
        );
      }

      await _repo.updateWorkout(
        gymId: gymId,
        id: id,
        programId: programId,
        title: title,
        description: description.isEmpty ? null : description,
        workoutDate: workoutDate,
        timeCapMinutes: null,
        workoutType: null,
        imageUrl: imageUrl,
      );

      if (!mounted) return;
      AppToast.show(context, context.appText.workoutUpdated);
      await _loadToday();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _deleteWorkout(Map<String, dynamic> item) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AppBottomSheetScaffold(
          title: context.appText.deleteWorkoutTitle,
          subtitle: context.appText.deleteWorkoutActionSubtitle,
          scrollable: false,
          child: AppSheetActions(
            busy: false,
            primaryText: context.appText.delete,
            cancelText: context.appText.cancel,
            primaryColor: const Color(0xFFB42318),
            pressedColor: const Color(0xFF912018),
            onCancel: () => Navigator.pop(sheetContext, false),
            onPrimary: () => Navigator.pop(sheetContext, true),
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      final gymId = (await _gymRepo.resolveGymId() ?? '').trim();
      if (gymId.isEmpty) {
        throw Exception(context.appText.gymIdRequiredError);
      }

      await _repo.deleteWorkout(gymId: gymId, id: item['id'].toString());

      if (!mounted) return;
      AppToast.show(context, context.appText.workoutDeleted);
      await _loadToday();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _showWorkoutActions(Map<String, dynamic> item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AppBottomSheetScaffold(
          scrollable: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSheetActionTile(
                icon: Icons.edit_rounded,
                title: context.appText.isSpanish
                    ? 'Editar workout'
                    : 'Edit workout',
                iconBg: const Color(0xFFF7F3EA),
                iconColor: const Color(0xFFB59B6A),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showEditWorkoutSheet(item);
                },
              ),
              const SizedBox(height: 10),
              AppSheetActionTile(
                icon: Icons.delete_outline_rounded,
                title: context.appText.deleteWorkoutTitle,
                iconBg: const Color(0xFFFEE4E2),
                iconColor: const Color(0xFFB42318),
                titleColor: const Color(0xFFB42318),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _deleteWorkout(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _createProgramFromWorkoutSheet(
    String name,
  ) async {
    try {
      final gymId = (await _gymRepo.resolveGymId() ?? '').trim();
      if (gymId.isEmpty) {
        throw Exception(context.appText.gymIdRequiredError);
      }

      await _programRepo.createProgram(gymId: gymId, name: name);
      final programs = await _programRepo.listPrograms(gymId);
      final created = programs.cast<Map<String, dynamic>?>().firstWhere(
        (p) =>
            (p?['name'] ?? '').toString().trim().toLowerCase() ==
            name.trim().toLowerCase(),
        orElse: () => null,
      );

      if (!mounted) return created;
      setState(() => _programs = programs);
      AppToast.show(context, context.appText.programCreated);
      return created;
    } catch (e) {
      if (!mounted) return null;
      AppToast.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
      return null;
    }
  }

  Future<void> _showCreateWorkoutSheet() async {
    final result = await showCreateWorkoutSheet(
      context,
      programs: _programs,
      onCreateProgram: _createProgramFromWorkoutSheet,
    );
    if (result == null) return;

    try {
      final gymId = (await _gymRepo.resolveGymId() ?? '').trim();
      if (gymId.isEmpty) {
        throw Exception(context.appText.gymIdRequiredError);
      }

      final programId = (result['programId'] ?? '').toString().trim();
      final programName = (result['programName'] ?? '').toString().trim();
      final workoutDate = (result['workoutDate'] ?? '').toString().trim();
      String title = (result['title'] ?? '').toString().trim();

      if (title.isEmpty) {
        try {
          final d = DateTime.parse(workoutDate);
          title =
              '${d.day.toString().padLeft(2, '0')}${d.month.toString().padLeft(2, '0')}${d.year}';
        } catch (_) {
          title = context.appText.workout;
        }
      }
      final description = (result['description'] ?? '').toString().trim();
      final imageFile = result['imageFile'];

      if (programId.isEmpty || title.isEmpty) {
        throw Exception(context.appText.programRequiredError);
      }
      if (workoutDate.isEmpty) {
        throw Exception(context.appText.workoutDateRequiredError);
      }

      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _storageRepo.uploadWorkoutImage(imageFile);
      }

      final existing = await _repo.findExistingWorkoutForProgramOnDate(
        gymId: gymId,
        programId: programId,
        workoutDate: workoutDate,
      );
      if (existing != null) {
        final existingTitle = (existing['title'] ?? 'Workout')
            .toString()
            .trim();
        throw Exception(
          context.appText.duplicateWorkoutForProgramDateError(existingTitle),
        );
      }

      final workoutId = await _repo.createWorkout(
        gymId: gymId,
        programId: programId,
        title: title,
        description: description.isEmpty ? null : description,
        workoutDate: workoutDate,
        timeCapMinutes: null,
        workoutType: null,
        createdBy: null,
        imageUrl: imageUrl,
      );

      await _notificationRepo.publishWorkoutNotificationIfNeeded(
        gymId: gymId,
        workoutId: workoutId,
        workoutTitle: title,
        workoutDate: workoutDate,
        programId: programId,
        programName: programName,
      );

      if (!mounted) return;
      AppToast.show(
        context,
        context.appText.isSpanish
            ? 'Workout creado correctamente.'
            : 'Workout created successfully.',
      );
      await _loadToday();
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _editProgram(Map<String, dynamic> program) async {
    final controller = TextEditingController(
      text: (program['name'] ?? '').toString().trim(),
    );

    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AppBottomSheetScaffold(
        title: context.appText.editProgram,
        subtitle: context.appText.isSpanish
            ? 'Actualiza el nombre del programa.'
            : 'Update the program name.',
        scrollable: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSheetTextField(
              controller: controller,
              label: context.appText.programName,
              textInputAction: TextInputAction.done,
              onTapOutside: (_) => FocusScope.of(sheetContext).unfocus(),
            ),
            const SizedBox(height: 16),
            AppSheetActions(
              busy: false,
              primaryText: context.appText.saveChanges,
              cancelText: context.appText.cancel,
              onCancel: () => Navigator.pop(sheetContext),
              onPrimary: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(sheetContext, value);
              },
            ),
          ],
        ),
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    try {
      final gymId = (await _gymRepo.resolveGymId() ?? '').trim();
      if (gymId.isEmpty) throw Exception(context.appText.gymIdRequiredError);

      await _programRepo.updateProgram(
        gymId: gymId,
        id: program['id'].toString(),
        name: name.trim(),
      );

      await _loadToday();
      if (!mounted) return;
      AppToast.show(context, context.appText.programUpdated);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _deleteProgram(Map<String, dynamic> program) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AppBottomSheetScaffold(
        title: context.appText.isSpanish
            ? 'Eliminar programa'
            : 'Delete program',
        subtitle: context.appText.isSpanish
            ? 'Si no tiene workouts vinculados, se eliminará definitivamente.'
            : 'If it has no linked workouts, it will be permanently deleted.',
        scrollable: false,
        child: AppSheetActions(
          busy: false,
          primaryText: context.appText.delete,
          cancelText: context.appText.cancel,
          primaryColor: const Color(0xFFB42318),
          pressedColor: const Color(0xFF912018),
          onCancel: () => Navigator.pop(sheetContext, false),
          onPrimary: () => Navigator.pop(sheetContext, true),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final gymId = (await _gymRepo.resolveGymId() ?? '').trim();
      if (gymId.isEmpty) throw Exception(context.appText.gymIdRequiredError);

      await _programRepo.deleteProgram(
        gymId: gymId,
        id: program['id'].toString(),
      );

      await _loadToday();
      if (!mounted) return;
      AppToast.show(context, context.appText.programDeleted);
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      AppToast.show(
        context,
        raw.contains('PROGRAM_HAS_LINKED_ITEMS')
            ? context.appText.deleteProgramLinkedError
            : raw.replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _createProgramFromManagePrograms() async {
    final controller = TextEditingController();

    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AppBottomSheetScaffold(
        title: context.appText.createProgramTitle,
        subtitle: context.appText.isSpanish
            ? 'Crea un programa para organizar tus workouts.'
            : 'Create a program to organize your workouts.',
        scrollable: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSheetTextField(
              controller: controller,
              label: context.appText.programName,
              hint: 'CrossFit / Strength / Hyrox',
              textInputAction: TextInputAction.done,
              onTapOutside: (_) => FocusScope.of(sheetContext).unfocus(),
            ),
            const SizedBox(height: 16),
            AppSheetActions(
              busy: false,
              primaryText: context.appText.createProgramTitle,
              cancelText: context.appText.cancel,
              onCancel: () => Navigator.pop(sheetContext),
              onPrimary: () {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(sheetContext, value);
              },
            ),
          ],
        ),
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    final created = await _createProgramFromWorkoutSheet(name.trim());
    if (created == null) return;

    await _loadToday();
  }

  void _showProgramActions(Map<String, dynamic> program) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AppBottomSheetScaffold(
          title: (program['name'] ?? '').toString().trim(),
          subtitle: context.appText.isSpanish
              ? 'Editar o eliminar este programa.'
              : 'Edit or delete this program.',
          scrollable: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSheetActionTile(
                icon: Icons.edit_rounded,
                title: context.appText.editProgram,
                subtitle: context.appText.isSpanish
                    ? 'Cambiar el nombre del programa.'
                    : 'Change the program name.',
                iconBg: const Color(0xFFF7F3EA),
                iconColor: const Color(0xFFB59B6A),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _editProgram(program);
                },
              ),
              const SizedBox(height: 10),
              AppSheetActionTile(
                icon: Icons.delete_outline_rounded,
                title: context.appText.delete,
                subtitle: context.appText.isSpanish
                    ? 'Eliminar este programa si no tiene contenido vinculado.'
                    : 'Delete this program if it has no linked content.',
                iconBg: const Color(0xFFFEE4E2),
                iconColor: const Color(0xFFB42318),
                titleColor: const Color(0xFFB42318),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _deleteProgram(program);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showManageProgramsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AppBottomSheetScaffold(
        title: context.appText.programActionsTitle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSheetActionTile(
              icon: Icons.add_rounded,
              title: context.appText.createProgramTitle,
              subtitle: context.appText.isSpanish
                  ? 'Añade un nuevo programa a la lista.'
                  : 'Add a new program to the list.',
              iconBg: const Color(0xFFF7F3EA),
              iconColor: const Color(0xFFB59B6A),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _createProgramFromManagePrograms();
              },
            ),
            const SizedBox(height: 12),
            ..._programs.map((program) {
              final name = (program['name'] ?? '').toString().trim();

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFEAECEF)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showProgramActions(program);
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F3EA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.category_rounded,
                            size: 22,
                            color: Color(0xFFB59B6A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: appSheetFont(
                                  17,
                                  weight: FontWeight.w800,
                                  color: const Color(0xFF111318),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                context.appText.isSpanish
                                    ? 'Editar o eliminar programa'
                                    : 'Edit or delete program',
                                style: appSheetFont(
                                  13,
                                  weight: FontWeight.w500,
                                  color: const Color(0xFF667085),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
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

  String _timeAgo(BuildContext context, DateTime dt) {
    final t = context.appText;
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return t.justNow;
    if (diff.inHours < 1) return t.minutesAgoShort(diff.inMinutes);
    if (diff.inDays < 1) return t.hoursAgoShort(diff.inHours);
    if (diff.inDays < 7) return t.daysAgoShort(diff.inDays);
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    return DateFormat('MMM d', localeTag).format(dt);
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
            text: posting ? '...' : context.appText.post,
            onTap: posting ? () {} : () => _postComment(workoutId),
          ),
        ),
      ],
    );
  }

  String _capitalizeDateLabel(String raw) {
    final parts = raw.split(' ');
    final normalized = parts
        .map((part) {
          if (part.isEmpty) return part;
          return part[0].toUpperCase() + part.substring(1);
        })
        .join(' ');
    return normalized.replaceAllMapped(RegExp(r'(^|\s)([a-záéíóúñ])'), (m) {
      return '${m.group(1)}${m.group(2)!.toUpperCase()}';
    });
  }

  Widget _brandLogo() {
    final gymName = _gymName.trim().isEmpty ? 'ATHLETE LAB' : _gymName.trim();

    return SizedBox(
      width: 132,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gymName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _font(
              16,
              weight: FontWeight.w800,
              color: const Color(0xFF0E0E11),
              letterSpacing: -0.2,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'ATHLETE LAB',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _font(
              10,
              weight: FontWeight.w700,
              color: const Color(0xFF8F96A3),
              letterSpacing: 0.7,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topHeader() {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final rawToday = DateFormat(
      'EEEE, MMMM d',
      localeTag,
    ).format(DateTime.now());
    final todayText = _capitalizeDateLabel(rawToday);

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
                          context.appText.todaysWorkoutsUpper,
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
                        child: UserSession().isAdmin
                            ? IconButton(
                                onPressed: _showManageProgramsSheet,
                                icon: const Icon(
                                  Icons.tune_rounded,
                                  color: Color(0xFFB59B6A),
                                ),
                              )
                            : Container(
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

    final rawProgram = (item['program_name'] ?? '').toString().trim();
    final rawTitle = (item['title'] ?? '').toString().trim();
    final program = rawProgram.isNotEmpty && rawProgram.toLowerCase() != 'null'
        ? rawProgram
        : (rawTitle.isNotEmpty ? rawTitle : context.appText.workout);
    final author = _gymName.trim().isNotEmpty
        ? _gymName.trim()
        : context.appText.athlete615;
    final dateIso = (item['workout_date'] ?? '').toString();

    String formattedDate = dateIso;
    try {
      final d = DateTime.parse(dateIso);
      final localeTag = Localizations.localeOf(context).toLanguageTag();
      final rawDate = DateFormat('MMMM d, yyyy', localeTag).format(d);
      formattedDate = rawDate.isNotEmpty
          ? rawDate[0].toUpperCase() + rawDate.substring(1)
          : rawDate;
    } catch (_) {}

    final description = (item['description'] ?? '').toString().trim();
    String dateFallback = context.appText.workout;
    try {
      final d = DateTime.parse(dateIso);
      dateFallback =
          '${d.day.toString().padLeft(2, '0')}${d.month.toString().padLeft(2, '0')}${d.year}';
    } catch (_) {}

    final title = rawTitle.isNotEmpty ? rawTitle : dateFallback;

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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE9EEF5),
                  backgroundImage: _gymLogoUrl.isNotEmpty
                      ? NetworkImage(_gymLogoUrl)
                      : null,
                  child: _gymLogoUrl.isEmpty
                      ? const Icon(
                          Icons.fitness_center,
                          size: 20,
                          color: Color(0xFF8A90A0),
                        )
                      : null,
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
                RoleGuard(
                  child: IconButton(
                    onPressed: () => _showWorkoutActions(item),
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: Color(0xFF98A2B3),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _imageSection(item),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
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
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: _font(
                25,
                weight: FontWeight.w800,
                color: const Color(0xFF111318),
                letterSpacing: -0.35,
                height: 1.0,
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 14),
              _parsedDescription(description),
            ],
            const SizedBox(height: 16),
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
                  icon: isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: context.appText.like,
                  iconColor: isLiked
                      ? const Color(0xFFE11D48)
                      : const Color(0xFF667085),
                  onTap: () => _toggleLike(workoutId),
                ),
                _socialAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: context.appText.commentLabel,
                  iconColor: const Color(0xFF667085),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(height: 0.6, color: const Color(0xFFF1F3F6)),
            const SizedBox(height: 14),
            if (comments.isEmpty)
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
              ...comments.map((comment) {
                final name =
                    (comment['author_name'] ?? context.appText.athleteFallback)
                        .toString();
                final text = (comment['comment'] ?? '').toString();

                DateTime createdAt = DateTime.now();
                try {
                  createdAt = DateTime.parse(
                    comment['created_at'].toString(),
                  ).toLocal();
                } catch (_) {}

                final avatarUrl = (comment['author_avatar_url'] ?? '')
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
      floatingActionButton: UserSession().isAdmin
          ? FloatingActionButton(
              heroTag: 'create_workout_fab',
              backgroundColor: const Color(0xFFB59B6A),
              foregroundColor: Colors.white,
              elevation: 3,
              onPressed: _showCreateWorkoutSheet,
              child: const Icon(Icons.add_rounded),
            )
          : null,
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
                              context.appText.restDayUpper,
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
                              context.appText.restDayMessage,
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
            borderRadius: BorderRadius.circular(16),
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
