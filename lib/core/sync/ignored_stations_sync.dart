// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'entity_sync.dart';
import 'sync_transport.dart';

/// Ignored-stations sync with Supabase, pulled out of [SyncService] (#727).
///
/// Same bidirectional-merge pattern as favorites — which is exactly why
/// both are now a one-line config over the shared [EntitySync.idSet]
/// engine (#3127): upload local-only ids (idempotent via
/// `(user_id, station_id)` upsert conflict), then return the union of
/// local + server sets. Unauthenticated path returns the input
/// unchanged — the feature keeps working on pure local state when the
/// user isn't signed in.
class IgnoredStationsSync {
  IgnoredStationsSync._();

  static final _sync = EntitySync.idSet(
      table: 'ignored_stations', logName: 'IgnoredStationsSync');

  /// Merge [localIgnoredIds] with the user's `ignored_stations` rows
  /// on Supabase. Returns the superset (local ∪ server). [transport]
  /// is injectable for tests.
  static Future<List<String>> merge(
    List<String> localIgnoredIds, {
    SyncTransport? transport,
  }) =>
      _sync.merge(localIgnoredIds, transport: transport);

  /// Un-ignore a single station on the server (#3078). Before this existed
  /// the un-ignore path only re-ran [merge], whose union re-added the still-
  /// server row, so the station never actually un-hid. Now the server row is
  /// deleted AND tombstoned (tombstone-first, journal-backed — #3123), so
  /// neither side resurrects it. Silent on failure.
  static Future<void> delete(String stationId, {SyncTransport? transport}) =>
      _sync.delete(stationId, transport: transport);
}
