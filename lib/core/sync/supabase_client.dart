import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the Supabase Flutter SDK.
///
/// Provides initialisation, anonymous auth, and a singleton accessor.
class TankSyncClient {
  static bool _initialized = false;

  /// Initialize the Supabase client. Safe to call multiple times — subsequent
  /// calls are no-ops.
  static Future<void> init({
    required String url,
    required String anonKey,
  }) async {
    // Sanitize URL: trim whitespace/newlines, ensure no trailing slash
    final cleanUrl = url.replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'/+$'), '');
    final cleanKey = anonKey.replaceAll(RegExp(r'\s+'), '');

    // Validate URL format
    final uri = Uri.tryParse(cleanUrl);
    if (uri == null || !uri.hasScheme || !uri.host.contains('.')) {
      throw ArgumentError('Invalid Supabase URL: $cleanUrl');
    }

    if (_initialized) {
      // Already initialized — check if URL changed
      // If same URL, skip. If different, we need to re-init.
      // Supabase SDK doesn't support re-init, so just return
      // (the existing client is still valid).
      return;
    }
    await Supabase.initialize(url: cleanUrl, anonKey: cleanKey);
    _initialized = true;
  }

  /// The underlying Supabase client, or `null` if [init] has not been called.
  static SupabaseClient? get client =>
      _initialized ? Supabase.instance.client : null;

  /// Whether the client is initialised AND a user session exists.
  static bool get isConnected =>
      _initialized && client?.auth.currentUser != null;

  /// Sign in anonymously (UUID only, no email/password).
  ///
  /// Returns the user ID on success, or `null` if the client is not ready.
  /// Also ensures the user exists in `public.users` (required by FK constraints).
  static Future<String?> signInAnonymously() async {
    final c = client;
    if (c == null) return null;
    final response = await c.auth.signInAnonymously();
    final userId = response.user?.id;
    if (userId != null) {
      // Ensure user exists in public.users table.
      // Supabase auth creates auth.users but NOT public.users.
      // The FK constraint on favorites/alerts requires public.users to exist.
      try {
        await c.from('users').upsert(
          {'id': userId},
          onConflict: 'id',
        );
      } catch (e) {
        debugPrint('TankSync: users upsert failed: $e');
      }
    }
    return userId;
  }

  /// Sign up with email and password. Creates both auth.users and public.users rows.
  static Future<String?> signUpWithEmail(String email, String password) async {
    final c = client;
    if (c == null) return null;
    final response = await c.auth.signUp(
      email: email,
      password: password,
    );
    final userId = response.user?.id;
    if (userId != null) {
      try {
        await c.from('users').upsert({'id': userId}, onConflict: 'id');
      } catch (e) {
        debugPrint('TankSync: users upsert failed: $e');
      }
    }
    return userId;
  }

  /// Sign in with existing email account.
  static Future<String?> signInWithEmail(String email, String password) async {
    final c = client;
    if (c == null) return null;
    final response = await c.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final userId = response.user?.id;
    if (userId != null) {
      try {
        await c.from('users').upsert({'id': userId}, onConflict: 'id');
      } catch (e) {
        debugPrint('TankSync: users upsert failed: $e');
      }
    }
    return userId;
  }

  /// Get the current user's email (null for anonymous users).
  static String? get currentEmail => client?.auth.currentUser?.email;

  /// Whether the current user has an email account (not anonymous).
  static bool get hasEmailAccount {
    final email = client?.auth.currentUser?.email;
    return email != null && email.isNotEmpty;
  }

  /// Sign out and reset the initialisation flag so [init] can be called again.
  static Future<void> signOut() async {
    final c = client;
    if (c == null) return;
    await c.auth.signOut();
    _initialized = false;
  }
}
