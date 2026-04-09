import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_bootstrap.dart';

class StorageRepository {
  Future<String> uploadGymLogo(File file, String gymId) async {
    final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
    final safeExt = ext.isEmpty ? 'jpg' : ext;
    final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    final path = 'gyms/$gymId/$fileName';

    await sb.storage
        .from('workout-images')
        .upload(path, file, fileOptions: const FileOptions(upsert: true));

    return sb.storage.from('workout-images').getPublicUrl(path);
  }

  Future<String> uploadWorkoutImage(File file) async {
    final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
    final safeExt = ext.isEmpty ? 'jpg' : ext;
    final fileName =
        'workout_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    final path = fileName;

    await sb.storage
        .from('workout-images')
        .upload(path, file, fileOptions: const FileOptions(upsert: true));

    return sb.storage.from('workout-images').getPublicUrl(path);
  }
}
