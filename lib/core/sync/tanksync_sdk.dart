// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:supabase_flutter/supabase_flutter.dart';

import 'secure_session_storage.dart';

/// The Supabase SDK singleton, as `TankSyncClient` uses it (#4162).
///
/// `Supabase.instance` is process-wide state the app flag in
/// `TankSyncClient` only mirrors — and the two can disagree: a second
/// `Supabase.initialize` is SKIPPED while the first client is live, so the
/// SDK keeps talking to the first URL (#4336). This seam names that state
/// so a test can model it (`test/core/sync/support/fake_tanksync_backend.dart`)
/// instead of pretending the SDK re-initialises.
abstract interface class TankSyncSdk {
  /// Whether the SDK singleton holds a client.
  bool get isInitialized;

  /// Host the live client talks to, lower-cased; null when not initialised.
  String? get host;

  /// The live client. Only valid while [isInitialized].
  SupabaseClient get client;

  /// Build the client for [url] — or, exactly like the SDK, do nothing when
  /// a client is already live, whatever its URL.
  Future<void> initialize({
    required String url,
    required String publishableKey,
    required String persistSessionKey,
  });

  /// Tear the client down (timers, streams, the lifecycle observer). The
  /// persisted session stays where it is.
  Future<void> dispose();
}

/// The production [TankSyncSdk] over `Supabase.instance`.
class SupabaseFlutterSdk implements TankSyncSdk {
  SupabaseFlutterSdk();

  // `Supabase.instance` asserts it is initialised, so its own flag cannot
  // be read before the first initialize. This mirrors it: this class is
  // the only caller of `Supabase.initialize` and `dispose` in the app.
  bool _initialized = false;
  String? _host;

  @override
  bool get isInitialized => _initialized;

  @override
  String? get host => _host;

  @override
  SupabaseClient get client => Supabase.instance.client;

  @override
  Future<void> initialize({
    required String url,
    required String publishableKey,
    required String persistSessionKey,
  }) async {
    // #3740 — keep the persisted session (incl. the refresh token) in the
    // platform keychain/keystore instead of the SDK's default plaintext
    // SharedPreferences slot.
    final instance = await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
      authOptions: FlutterAuthClientOptions(
        localStorage:
            SecureSessionLocalStorage(persistSessionKey: persistSessionKey),
      ),
    );
    if (_initialized) return;
    _initialized = true;
    _host = Uri.parse(instance.client.rest.url).host.toLowerCase();
  }

  @override
  Future<void> dispose() async {
    if (!_initialized) return;
    _initialized = false;
    _host = null;
    await Supabase.instance.dispose();
  }
}
