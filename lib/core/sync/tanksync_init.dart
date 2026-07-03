// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logging/app_log.dart';
import '../logging/error_logger.dart';
import '../storage/hive_storage.dart';
import 'supabase_client.dart';

/// Terminal outcome of one [TankSyncInit.run] pass.
enum TankSyncInitOutcome {
  /// Sync is off or credentials are missing — nothing to initialise.
  notConfigured,

  /// Client initialised with a live session; pulls can run.
  ready,

  /// #3449 — the client initialised but there is NO session while a
  /// `sync_user_id` IS stored locally. The old flow silently minted a
  /// fresh anonymous UUID and OVERWROTE the stored id, orphaning every
  /// server row owned by the previous identity. We now stand down and let
  /// the sync settings surface re-link guidance instead.
  relinkRequired,

  /// Init threw (network, bad credentials, SDK fault) — a #3450 retry
  /// candidate.
  failed,
}

/// The TankSync launch initialisation body, extracted from
/// `AppInitializer._maybeInitTankSync` (#3449/#3450) — the caller keeps
/// the hard 8-second timeout; this class owns the logic so it can carry
/// the identity guard and be re-driven by [TankSyncInitRetry] without
/// growing the ratchet-tight initializer.
///
/// ## The #3449 identity guard
///
/// A stored `sync_user_id` is the user's identity — favorites, trips and
/// fill-ups on the server are keyed to it. When the Supabase session is
/// gone (expired refresh token, cleared SDK storage) the ONE forbidden
/// move is `signInAnonymously()`: it mints a brand-new UUID and the old
/// rows become unreachable. The guard:
///
///  * stored id + no session → NO anonymous sign-in, NO id overwrite;
///    outcome [TankSyncInitOutcome.relinkRequired]. Pulls no-op (they all
///    short-circuit unauthenticated) until the user either signs in with
///    email (re-links the same identity) or explicitly starts fresh.
///  * no stored id (fresh install / post-disconnect) → the old behaviour:
///    anonymous sign-in, persist the minted id.
///  * live session that differs from the stored id (e.g. an email sign-in
///    on this device) → adopt the session id, as before.
class TankSyncInit {
  TankSyncInit._();

  /// Outcome of the most recent [run] — `null` while a pass is in flight
  /// (or before the first one). The deferred launch block and the #3450
  /// retry scheduler read this instead of a return value because the
  /// caller's 8 s timeout can abandon the in-flight future.
  static TankSyncInitOutcome? lastOutcome;

  /// One init pass. The guard/no-op paths complete with an outcome; a
  /// thrown init/sign-in error records [TankSyncInitOutcome.failed] and
  /// propagates so the caller's existing catch + timeout telemetry keeps
  /// working. All collaborators are injectable seams for the unit tests
  /// (`TankSyncClient` is a static global).
  static Future<TankSyncInitOutcome> run(
    HiveStorage storage, {
    Future<void> Function({required String url, required String anonKey})?
        init,
    String? Function()? sessionUserId,
    Future<String?> Function()? signInAnonymously,
    Future<void> Function(String userId)? ensurePublicUser,
  }) async {
    lastOutcome = null;
    final outcome = await _run(
      storage,
      init: init ?? _defaultInit,
      sessionUserId:
          sessionUserId ?? () => TankSyncClient.client?.auth.currentUser?.id,
      signInAnonymously: signInAnonymously ?? TankSyncClient.signInAnonymously,
      ensurePublicUser: ensurePublicUser ?? _defaultEnsurePublicUser,
    );
    lastOutcome = outcome;
    return outcome;
  }

  static Future<TankSyncInitOutcome> _run(
    HiveStorage storage, {
    required Future<void> Function(
            {required String url, required String anonKey})
        init,
    required String? Function() sessionUserId,
    required Future<String?> Function() signInAnonymously,
    required Future<void> Function(String userId) ensurePublicUser,
  }) async {
    final syncEnabled = storage.getSetting('sync_enabled') as bool? ?? false;
    if (!syncEnabled) return TankSyncInitOutcome.notConfigured;
    final url = storage.getSetting('supabase_url') as String?;
    final key = storage.getSupabaseAnonKey();
    if (url == null || key == null) return TankSyncInitOutcome.notConfigured;

    try {
      await init(url: url, anonKey: key);
      final storedId = storage.getSetting('sync_user_id') as String?;
      if (sessionUserId() == null) {
        // #3449 — identity guard: a stored id with no session must NOT be
        // papered over with a fresh anonymous UUID.
        if (storedId != null) {
          log.info('TankSync: session lost for stored identity — '
              'relink required (#3449)');
          return TankSyncInitOutcome.relinkRequired;
        }
        log.info('TankSync: no session, signing in anonymously...');
        await signInAnonymously();
      }
      final sessionId = sessionUserId();
      if (sessionId != null && sessionId != storedId) {
        log.info('TankSync: userId changed');
        await storage.putSetting('sync_user_id', sessionId);
      }
      if (sessionId != null) {
        try {
          await ensurePublicUser(sessionId);
        } catch (e, st) {
          unawaited(errorLogger.log(ErrorLayer.sync, e, st,
              context: {'where': 'maybeInitTankSync users upsert'}));
        }
      }
      log.info('TankSync: ready');
      return TankSyncInitOutcome.ready;
    } catch (e, st) {
      lastOutcome = TankSyncInitOutcome.failed;
      // The caller (AppInitializer's timeout wrapper / the retry
      // scheduler) owns the logging + retry policy for a failed init.
      Error.throwWithStackTrace(e, st);
    }
  }

  static Future<void> _defaultInit(
          {required String url, required String anonKey}) =>
      TankSyncClient.init(url: url, anonKey: anonKey);

  static Future<void> _defaultEnsurePublicUser(String userId) async {
    final client = TankSyncClient.client;
    if (client == null) return;
    await client.from('users').upsert({'id': userId}, onConflict: 'id');
  }

  /// Reset the static outcome — test isolation only.
  @visibleForTesting
  static void resetForTest() => lastOutcome = null;
}
