import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase initialization.
///
/// Credentials are injected via --dart-define at build time:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// This keeps secrets out of source control. Never hard-code credentials here.
final class SupabaseService {
  SupabaseService._();

  static const String _url = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Call once in [main] before [runApp].
  static Future<void> initialize() async {
    assert(
      _url.isNotEmpty && _anonKey.isNotEmpty,
      'SUPABASE_URL and SUPABASE_ANON_KEY must be provided via --dart-define. '
      'See the project README for setup instructions.',
    );

    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  /// Shorthand accessor used throughout the app.
  static SupabaseClient get client => Supabase.instance.client;

  /// Shorthand for the Storage API.
  static SupabaseStorageClient get storage => client.storage;

  /// Shorthand for the current authenticated session, if any.
  static Session? get currentSession => client.auth.currentSession;

  /// True when a user session is active.
  static bool get isAuthenticated => currentSession != null;

  // ── Storage bucket names ───────────────────────────────────────────

  /// Bucket where transfer receipt photos are uploaded.
  static const String transferBucket = 'transfer-receipts';
}
