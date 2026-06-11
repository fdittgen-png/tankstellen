// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

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
}

/// The production [SyncTransport] over the live [TankSyncClient].
class SupabaseSyncTransport implements SyncTransport {
  final SupabaseClient _client;

  @override
  final String userId;

  SupabaseSyncTransport._(this._client, this.userId);

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
    var query = _client.from(table).select(columns).eq('user_id', userId);
    for (final filter in filters.entries) {
      query = query.eq(filter.key, filter.value);
    }
    final rows = await query;
    return List<JsonRow>.from(rows);
  }

  @override
  Future<void> upsert(
    String table,
    List<JsonRow> rows, {
    required String onConflict,
  }) =>
      _client.from(table).upsert(rows, onConflict: onConflict);

  @override
  Future<void> deleteWhere(String table, Map<String, Object> filters) {
    var query = _client.from(table).delete().eq('user_id', userId);
    for (final filter in filters.entries) {
      query = query.eq(filter.key, filter.value);
    }
    return query;
  }
}
