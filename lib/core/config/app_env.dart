import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  const AppEnv._();

  static const supabaseUrlKey = 'SUPABASE_URL';
  static const supabaseAnonKeyKey = 'SUPABASE_ANON_KEY';

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Tests and fresh clones may run before a local .env exists.
    }
  }

  static String get supabaseUrl => dotenv.maybeGet(supabaseUrlKey) ?? '';

  static String get supabaseAnonKey =>
      dotenv.maybeGet(supabaseAnonKeyKey) ?? '';

  static bool get hasSupabaseConfig {
    final url = supabaseUrl.trim();
    final anonKey = supabaseAnonKey.trim();
    final parsedUrl = Uri.tryParse(url);

    return parsedUrl != null &&
        parsedUrl.hasScheme &&
        parsedUrl.host.isNotEmpty &&
        anonKey.isNotEmpty &&
        !url.contains('your-project-ref') &&
        !anonKey.contains('your-public-anon-key');
  }
}
