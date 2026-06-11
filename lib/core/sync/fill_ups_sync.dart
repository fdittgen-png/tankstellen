// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../features/consumption/domain/entities/fill_up.dart';
import 'entity_sync.dart';
import 'sync_transport.dart';

/// Per-fill-up consumption-log sync with Supabase (#713), pulled out
/// of [SyncService] (#727). Since #3127 a thin codec config over the
/// shared [EntitySync] engine.
///
/// Same shape as [VehiclesSync]: the server row carries a full
/// [FillUp] JSON blob and the download branch decodes each row back
/// into the domain entity. Merge rule: dedupe by id (both directions
/// idempotent via `(user_id, id)` upsert conflict) + last-write-wins
/// for ids present on both sides (#3122). The extra `vehicle_id` +
/// `recorded_at` columns are for server-side filtering — clients only
/// read the `data` blob.
class FillUpsSync {
  FillUpsSync._();

  static final _sync = EntitySync<FillUp>(
    table: 'fill_ups',
    logName: 'FillUpsSync',
    idColumn: 'id',
    selectColumns: 'id, data, updated_at',
    onConflict: 'user_id,id',
    idOf: (f) => f.id,
    // #3122 — enables the LWW path for ids present on both sides.
    localStamp: (f) => f.updatedAt,
    encode: (f, userId) => {
      'id': f.id,
      'user_id': userId,
      'vehicle_id': f.vehicleId,
      'recorded_at': f.date.toIso8601String(),
      // #3125 — forensic origin stamps ride INSIDE the JSONB blob
      // (sync-transparent: decode ignores unknown keys, every re-upload
      // re-stamps with the writing device).
      'data': {...f.toJson(), ...EntitySync.forensicStamps()},
      // Carry the local edit stamp so the next LWW compare sees equal
      // stamps (skip) instead of a phantom-newer server row. Legacy
      // unstamped records fall back to upload time.
      'updated_at': EntitySync.lwwStamp(f.updatedAt),
    },
    decode: EntitySync.jsonbDataDecoder(
      FillUp.fromJson,
      where: 'FillUpsSync.merge decode failed',
    ),
  );

  /// Merge [localFillUps] with the user's `fill_ups` rows on
  /// Supabase. Returns the union, with the fresher side winning for ids
  /// present on both (#3122 LWW — see [SyncHelper.lwwSplit] for the
  /// tie/missing-stamp policy). Unauthenticated path returns the input
  /// unchanged. [transport] is injectable for tests.
  static Future<List<FillUp>> merge(
    List<FillUp> localFillUps, {
    SyncTransport? transport,
  }) =>
      _sync.merge(localFillUps, transport: transport);

  /// Remove a single fill-up from the server (called on explicit
  /// delete from the consumption log). Tombstone-first (journal-backed,
  /// #3078/#3123). Silent on failure.
  static Future<void> delete(String fillUpId, {SyncTransport? transport}) =>
      _sync.delete(fillUpId, transport: transport);
}
