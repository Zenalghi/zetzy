/// Compile-time Supabase configuration for Zetzy.
///
/// Provide `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
/// or `--dart-define-from-file=supabase.json` at build/run time to enable
/// cloud sync, authentication, and online Chess.
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      normalizeUrl(url).isNotEmpty && anonKey.trim().isNotEmpty;

  /// Normalizes a Supabase project URL by trimming whitespace, trailing
  /// slashes, and accidental API path suffixes such as `/rest/v1`.
  static String normalizeUrl(String raw) {
    var value = raw.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    for (final suffix in ['/rest/v1', '/auth/v1', '/storage/v1']) {
      if (value.endsWith(suffix)) {
        value = value.substring(0, value.length - suffix.length);
        break;
      }
    }
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
