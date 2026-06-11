// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'entity_sync.dart';
import 'sync_transport.dart';

/// Favorites sync with Supabase, pulled out of [SyncService] (#727).
///
/// Bidirectional merge over the `favorites` table — local-only ids
/// upload (idempotent via `(user_id, station_id)` upsert conflict),
/// and the returned list is the union of local + server. Since #3127
/// this is a thin config over the shared [EntitySync.idSet] engine,
/// which carries the tombstone filter (#3078), the durable deletion
/// journal (#3123) and the per-table run-trace counts (#3126).
class FavoritesSync {
  FavoritesSync._();

  static final _sync =
      EntitySync.idSet(table: 'favorites', logName: 'FavoritesSync');

  /// Merge [localFavoriteIds] with the user's `favorites` rows on
  /// Supabase. Returns the superset (local ∪ server). Unauthenticated
  /// path returns the input unchanged. [transport] is injectable for
  /// tests.
  static Future<List<String>> merge(
    List<String> localFavoriteIds, {
    SyncTransport? transport,
  }) =>
      _sync.merge(localFavoriteIds, transport: transport);

  /// Delete a single favorite from the server. Called only when the
  /// user explicitly removes a favorite on this device — the union
  /// merge path never deletes. Tombstone-first (#3078/#3123): the
  /// durable "this id is dead" record must not depend on the row
  /// delete succeeding.
  static Future<void> delete(String stationId, {SyncTransport? transport}) =>
      _sync.delete(stationId, transport: transport);
}
