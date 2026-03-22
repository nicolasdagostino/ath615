import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final sb = Supabase.instance.client;

class AvatarRepository {
  final _picker = ImagePicker();

  Future<File?> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (picked == null) return null;
    return File(picked.path);
  }

  Future<String?> uploadAvatar(File file) async {
    final user = sb.auth.currentUser;
    if (user == null) return null;

    final parts = file.path.split('.');
    final ext = parts.length > 1 ? parts.last.toLowerCase() : '';
    final safeExt = ext.isEmpty ? 'jpg' : ext;
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    final path = "avatars/${user.id}/$fileName";

    await sb.storage
        .from("avatars")
        .upload(path, file, fileOptions: const FileOptions(upsert: false));

    final url = sb.storage.from("avatars").getPublicUrl(path);

    await sb.from("profiles").update({"avatar_url": url}).eq("id", user.id);

    return url;
  }
}
