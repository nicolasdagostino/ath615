import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_keys.dart';

class SupabaseBootstrap {
  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseKeys.url,
      anonKey: SupabaseKeys.anonKey,
    );
  }
}

SupabaseClient get sb => Supabase.instance.client;
