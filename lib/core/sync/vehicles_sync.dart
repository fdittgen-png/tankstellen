// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../domain/vehicle_profile.dart';
import 'entity_sync.dart';
import 'sync_transport.dart';

/// Per-vehicle profile sync with Supabase (#713), pulled out of
/// [SyncService] (#727). Since #3127 a thin codec config over the
/// shared [EntitySync] engine.
///
/// The server row carries a full domain JSON blob (engine fuel type,
/// display name, flex-fuel config, per-vehicle defaults) rather than
/// a bare id — the download branch decodes each row back into a
/// [VehicleProfile] and appends it to the local list.
///
/// Per-device `UserProfile`s are NOT synced (each device keeps its
/// own defaulting), only the `VehicleProfile`s. That invariant is
/// what the merge rule here preserves.
class VehiclesSync {
  VehiclesSync._();

  static final _sync = EntitySync<VehicleProfile>(
    table: 'vehicles',
    logName: 'VehiclesSync',
    idColumn: 'id',
    selectColumns: 'id, data, updated_at',
    onConflict: 'user_id,id',
    idOf: (v) => v.id,
    // #3122 — enables the LWW path for ids present on both sides.
    localStamp: (v) => v.updatedAt,
    encode: (v, userId) => {
      'id': v.id,
      'user_id': userId,
      // #3125 — forensic origin stamps ride INSIDE the JSONB blob
      // (sync-transparent: decode ignores unknown keys, every re-upload
      // re-stamps with the writing device).
      'data': {...v.toJson(), ...EntitySync.forensicStamps()},
      // Carry the local edit stamp so the next LWW compare sees equal
      // stamps (skip). Legacy unstamped profiles fall back to upload time.
      'updated_at': EntitySync.lwwStamp(v.updatedAt),
    },
    decode: EntitySync.jsonbDataDecoder(
      VehicleProfile.fromJson,
      where: 'VehiclesSync.merge decode failed',
    ),
  );

  /// Merge [localVehicles] with the user's `vehicles` rows on
  /// Supabase. Returns the union, with the fresher side winning for ids
  /// present on both (#3122 LWW — see [SyncHelper.lwwSplit] for the
  /// tie/missing-stamp policy). Unauthenticated path returns the input
  /// unchanged. [transport] is injectable for tests.
  static Future<List<VehicleProfile>> merge(
    List<VehicleProfile> localVehicles, {
    SyncTransport? transport,
  }) =>
      _sync.merge(localVehicles, transport: transport);

  /// Remove a single vehicle from the server (called on explicit
  /// delete from the vehicle list screen). Tombstone-first
  /// (journal-backed, #3078/#3123). Silent on failure — the local
  /// delete already happened and there's nothing the caller can do
  /// about a transient network blip.
  static Future<void> delete(String vehicleId, {SyncTransport? transport}) =>
      _sync.delete(vehicleId, transport: transport);
}
