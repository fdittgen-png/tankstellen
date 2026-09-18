// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';
import 'sync_pull_lease.dart';

/// A decoded Supabase row.
typedef JsonRow = Map<String, dynamic>;

/// Minimal transport seam over the user-scoped Supabase table operations
/// the sync classes perform (#3122).
///
/// Before this seam every `*_sync.dart` talked to `TankSyncClient.client`
/// directly, so the merge logic (id union, tombstone filter, last-write-wins
/// comparison, run counters) was untestable without a live Supabase session —
/// the unit tests could only pin the unauthenticated early-return. Each sync
/// entry point now accepts an optional [SyncTransport]; production passes
/// nothing and gets [SupabaseSyncTransport.currentOrNull], tests inject a
/// fake that records uploads and serves canned rows.
///
/// Every operation is implicitly scoped to the authenticated user
/// (`user_id = auth.uid()` mirrors the RLS policies), so a fake can't
/// accidentally model cross-user reads the real backend would reject.
abstract class SyncTransport {
  /// The authenticated user id every operation is scoped to.
  String get userId;

  /// #4047 — host of the backend this transport talks to. Defaults to
  /// null so existing fakes need no change; the production transport
  /// overrides it. Together with [userId] it identifies the context any
  /// locally-queued sync intent belongs to.
  String? get backendUrl => null;

  /// `SELECT [columns] FROM [table] WHERE user_id = userId [AND filters]`.
  Future<List<JsonRow>> select(
    String table,
    String columns, {
    Map<String, Object> filters = const {},
  });

  /// Upsert [rows] into [table] resolving conflicts on [onConflict].
  Future<void> upsert(
    String table,
    List<JsonRow> rows, {
    required String onConflict,
  });

  /// `DELETE FROM [table] WHERE user_id = userId AND filters`.
  Future<void> deleteWhere(String table, Map<String, Object> filters);

  /// `DELETE FROM [table] WHERE user_id = userId AND [column] < [before]`
  /// — the retention prune (#1479 phase 5; trips ride this seam since
  /// #4377). [before] is an ISO-8601 UTC stamp.
  Future<void> deleteOlderThan(String table, String column, String before);
}

/// Thrown by [SupabaseSyncTransport] when the client it was opened on is
/// no longer the live one (#4337): the Cloud Sync consent was withdrawn,
/// or sync was disconnected or pointed elsewhere, while a pass held the
/// transport. Nothing may reach the backend through it any more.
class SyncFencedException implements Exception {
  const SyncFencedException();

  @override
  String toString() => 'SyncFencedException: the sync client this pass '
      'opened is no longer live';
}

/// The production [SyncTransport] over the live [TankSyncClient].
///
/// Two fences, checked before every call: the client it was opened on
/// must still be the live one (#4337, [SyncFencedException]), and the
/// pull pass it runs inside — if any — must still be the current one
/// (#4377, [SyncPullAbandonedException]). The second is checked AGAIN
/// after every awaited answer: a select parked on the wire past its
/// pass's timeout answers into a pass that already ended, and that answer
/// must never reach the persist step.
class SupabaseSyncTransport implements SyncTransport {
  final SupabaseClient _client;

  @override
  final String userId;

  SupabaseSyncTransport._(this._client, this.userId);

  @override
  String? get backendUrl => TankSyncClient.backendHost;

  /// The transport for the current session, or `null` when the client is
  /// not initialised / no user is signed in — callers keep the existing
  /// "unauthenticated path returns the input unchanged" contract.
  static SyncTransport? currentOrNull() {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return null;
    return SupabaseSyncTransport._(client, userId);
  }

  @override
  Future<List<JsonRow>> select(
    String table,
    String columns, {
    Map<String, Object> filters = const {},
  }) async {
    _fence();
    var query = _client.from(table).select(columns).eq('user_id', userId);
    for (final filter in filters.entries) {
      query = query.eq(filter.key, filter.value);
    }
    final rows = await query;
    _settle();
    return List<JsonRow>.from(rows);
  }

  @override
  Future<void> upsert(
    String table,
    List<JsonRow> rows, {
    required String onConflict,
  }) async {
    _fence();
    await _client.from(table).upsert(rows, onConflict: onConflict);
    _settle();
  }

  @override
  Future<void> deleteWhere(String table, Map<String, Object> filters) async {
    _fence();
    var query = _client.from(table).delete().eq('user_id', userId);
    for (final filter in filters.entries) {
      query = query.eq(filter.key, filter.value);
    }
    await query;
    _settle();
  }

  @override
  Future<void> deleteOlderThan(
    String table,
    String column,
    String before,
  ) async {
    _fence();
    await _client
        .from(table)
        .delete()
        .eq('user_id', userId)
        .lt(column, before);
    _settle();
  }

  /// #4337 — refuse to touch a client that is no longer the live one;
  /// #4377 — or to start a call for a pull pass that was abandoned.
  void _fence() {
    if (!identical(TankSyncClient.client, _client)) {
      throw const SyncFencedException();
    }
    SyncPullLease.current?.checkLive();
  }

  /// #4377 — the answer arrived; refuse to hand it back to a pass that was
  /// abandoned while it was on the wire.
  void _settle() => SyncPullLease.current?.checkLive();
}
