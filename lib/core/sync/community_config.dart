/// Pre-configured credentials for the Tankstellen Community database.
///
/// This is the shared database that all community users connect to.
/// Credentials can be overridden at build time via `--dart-define`:
///
/// ```bash
/// flutter build apk --dart-define=COMMUNITY_SUPABASE_URL=https://...
///                    --dart-define=COMMUNITY_SUPABASE_ANON_KEY=eyJ...
/// ```
///
/// ## Reusability
/// Other apps can replace this class with their own community config.
/// The sync module does not reference this class directly — it's only
/// used by the UI layer when the user selects "Community" mode.
class CommunityConfig {
  CommunityConfig._();

  /// Supabase project URL for the community database.
  static const supabaseUrl = String.fromEnvironment(
    'COMMUNITY_SUPABASE_URL',
    defaultValue: 'https://tpxflmcpumtmehslcixx.supabase.co',
  );

  /// Supabase anonymous key for the community database.
  static const supabaseAnonKey = String.fromEnvironment(
    'COMMUNITY_SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
        '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRweGZsbWNwdW10bWVoc2xjaXh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2Mzg0NjYsImV4cCI6MjA5MDIxNDQ2Nn0'
        '.94L8m6ew6R7P2sOhTJJatLYdFqYLmQACyxCmYKlhGXc',
  );
}
