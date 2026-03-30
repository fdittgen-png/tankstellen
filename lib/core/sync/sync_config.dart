/// How the user chose to sync their data.
///
/// This enum is persisted in Hive so the app remembers the choice.
/// The privacy level increases from top to bottom:
/// - [community] — shared with all Tankstellen users (least private)
/// - [joinExisting] — shared with a group (family/friends)
/// - [private] — user's own database (most private, self-hosted)
/// - [none] — no sync, local only
enum SyncMode {
  /// Join the default Tankstellen community database.
  /// Credentials are pre-configured — no setup needed from user.
  community,

  /// Join an existing 3rd party database (via QR code or manual entry).
  /// Shared with a family/friends group.
  joinExisting,

  /// User's own self-hosted Supabase instance.
  /// Full data control, nobody else can see the data.
  private,

  /// No cloud sync. Everything stays on device only.
  none,
}

/// Configuration model for cloud sync (Supabase-backed).
///
/// This is a pure data class with no dependencies on any specific app.
/// It can be reused by any Flutter app that needs Supabase sync.
class SyncConfig {
  final bool enabled;
  final String? supabaseUrl;
  final String? supabaseAnonKey;
  final String? userId;
  final SyncMode mode;
  final String? userEmail;

  const SyncConfig({
    this.enabled = false,
    this.supabaseUrl,
    this.supabaseAnonKey,
    this.userId,
    this.mode = SyncMode.none,
    this.userEmail,
  });

  /// Whether all required fields are present to attempt a connection.
  bool get isConfigured =>
      enabled && supabaseUrl != null && supabaseAnonKey != null;

  /// Human-readable mode name for UI display.
  String get modeName => switch (mode) {
    SyncMode.community => 'Tankstellen Community',
    SyncMode.joinExisting => 'Shared Group',
    SyncMode.private => 'Private Database',
    SyncMode.none => 'Local Only',
  };

  /// Whether this is an email-based account (not anonymous).
  bool get hasEmail => userEmail != null && userEmail!.isNotEmpty;
}
