/// Supabase configuration.
/// Replace these placeholder values with your actual Supabase project credentials.
/// Go to: https://supabase.com → Your Project → Settings → API
class SupabaseConfig {
  /// Your Supabase project URL (e.g. https://xxxx.supabase.co)
  static String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';

  /// Your Supabase anon/public key (safe to put in app)
  static String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';

  /// Returns true when real credentials have been configured
  static bool get isConfigured =>
      supabaseUrl != 'https://YOUR_PROJECT.supabase.co' &&
      supabaseAnonKey != 'YOUR_ANON_KEY_HERE';
}
