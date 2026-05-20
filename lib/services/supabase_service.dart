import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_env.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  return SupabaseService.client;
});

class SupabaseService {
  const SupabaseService._();

  static Future<bool> initialize() async {
    if (!AppEnv.hasSupabaseConfig) {
      return false;
    }

    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );

    return true;
  }

  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static bool get isConfigured => client != null;
}
