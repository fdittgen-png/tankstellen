import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the Supabase Flutter SDK.
///
/// Provides initialisation, anonymous auth, and a singleton accessor.
class TankSyncClient {
  static bool _initialized = false;

  /// Max retry attempts for the public.users upsert after auth signup/signin.
  static const maxUpsertRetries = 3;

  /// Base delay for exponential backoff between upsert retries.
  static const upsertRetryBaseDelay = Duration(milliseconds: 500);

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
      await _ensurePublicUser(c, userId);
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
      await _ensurePublicUser(c, userId);
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
      await _ensurePublicUser(c, userId);
    }
    return userId;
  }

  /// Ensure the user exists in `public.users` (required by FK constraints
  /// on favorites/alerts). Retries with exponential backoff; if all retries
  /// fail, signs out to restore consistent state and rethrows.
  static Future<void> _ensurePublicUser(
    SupabaseClient c,
    String userId,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < maxUpsertRetries; attempt++) {
      try {
        await c.from('users').upsert({'id': userId}, onConflict: 'id');
        return; // success
      } catch (e) {
        lastError = e;
        debugPrint(
          'TankSync: users upsert attempt ${attempt + 1}/$maxUpsertRetries failed: $e',
        );
        if (attempt < maxUpsertRetries - 1) {
          await Future<void>.delayed(
            upsertRetryBaseDelay * (1 << attempt),
          );
        }
      }
    }

    // All retries exhausted — sign out to prevent inconsistent state
    // where auth.users exists but public.users doesn't.
    debugPrint('TankSync: users upsert failed after $maxUpsertRetries attempts, signing out');
    try {
      await c.auth.signOut();
    } catch (e) {
      debugPrint('TankSync: sign-out after upsert failure also failed: $e');
    }
    _initialized = false;
    throw StateError(
      'Failed to create public.users row after $maxUpsertRetries attempts. '
      'Signed out to prevent inconsistent state. '
      'Original error: $lastError',
    );
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
