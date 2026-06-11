// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/vehicle/domain/entities/vehicle_profile.dart';
import '../utils/json_extensions.dart';
import 'deletions_sync.dart';
import 'supabase_client.dart';
import 'sync_helper.dart';
import 'sync_transport.dart';
import '../../core/logging/error_logger.dart';

/// Per-vehicle profile sync with Supabase (#713), pulled out of
/// [SyncService] (#727).
///
/// Vehicles are the one sync concern where the server row carries a
/// full domain JSON blob (engine fuel type, display name, flex-fuel
/// config, per-vehicle defaults) rather than a bare id — the
/// download branch decodes each row back into a [VehicleProfile]
/// and appends it to the local list.
///
/// Per-device `UserProfile`s are NOT synced (each device keeps its
/// own defaulting), only the `VehicleProfile`s. That invariant is
/// what the merge rule here preserves.
class VehiclesSync {
  VehiclesSync._();

  /// Merge [localVehicles] with the user's `vehicles` rows on
  /// Supabase. Returns the union, with the fresher side winning for ids
  /// present on both (#3122 LWW — see [SyncHelper.lwwSplit] for the
  /// tie/missing-stamp policy). Unauthenticated path returns the input
  /// unchanged. [transport] is injectable for tests.
  static Future<List<VehicleProfile>> merge(
    List<VehicleProfile> localVehicles, {
    SyncTransport? transport,
  }) async {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) {
      debugPrint('VehiclesSync.merge: not authenticated');
      return localVehicles;
    }

    try {
      final serverRowsRaw =
          await t.select('vehicles', 'id, data, updated_at');

      // #3078 — drop tombstoned rows from BOTH sides so a delete on another
      // device can't resurrect through the union/re-upload below.
      final tombstoned =
          await DeletionsSync.fetchTombstonedIds('vehicles', transport: t);
      final serverRows = SyncHelper.removeTombstoned(
        serverRowsRaw,
        tombstoned,
        key: (r) => r.getString('id'),
      ).toList();
      final liveLocal =
          localVehicles.where((v) => !tombstoned.contains(v.id)).toList();

      final serverIds = serverRows
          .map((r) => r.getString('id'))
          .whereType<String>()
          .toSet();
      final localIds = liveLocal.map((v) => v.id).toSet();

      debugPrint('VehiclesSync.merge: local=${localIds.length}, '
          'server=${serverIds.length}');

      // #3122 — last-write-wins for ids present on both sides: a local
      // edit re-uploads, a fresher server row overwrites the local copy.
      final lww = SyncHelper.lwwSplit(
        local: liveLocal,
        serverRows: serverRows,
        id: (v) => v.id,
        localStamp: (v) => v.updatedAt,
        tombstoned: tombstoned,
      );

      // Upload local-only + local-newer vehicles.
      final localOnly =
          liveLocal.where((v) => !serverIds.contains(v.id)).toList();
      final toUpload = [...localOnly, ...lww.localNewer];
      if (toUpload.isNotEmpty) {
        final rows = toUpload
            .map((v) => {
                  'id': v.id,
                  'user_id': t.userId,
                  'data': v.toJson(),
                  // Carry the local edit stamp so the next LWW compare
                  // sees equal stamps (skip). Legacy unstamped profiles
                  // fall back to upload time.
                  'updated_at': (v.updatedAt ?? DateTime.now())
                      .toUtc()
                      .toIso8601String(),
                })
            .toList();
        await t.upsert('vehicles', rows, onConflict: 'user_id,id');
        debugPrint('VehiclesSync.merge: uploaded ${toUpload.length} '
            'vehicles (${lww.localNewer.length} local-newer edits)');
      }

      VehicleProfile? decode(Map<String, dynamic> r) {
        final data = r['data'];
        if (data is Map<String, dynamic>) {
          try {
            return VehicleProfile.fromJson(data);
          } catch (e, st) {
            unawaited(errorLogger.log(ErrorLayer.sync, e, st,
                context: const {'where': 'VehiclesSync.merge decode failed'}));
            return null;
          }
        }
        return null;
      }

      // Download server-only vehicles…
      final downloaded = serverRows
          .where((r) => !localIds.contains(r.getString('id')))
          .map(decode)
          .whereType<VehicleProfile>()
          .toList();
      // …and overwrite local copies the server has a fresher edit of.
      final serverNewerById = <String, VehicleProfile>{
        for (final v
            in lww.serverNewer.map(decode).whereType<VehicleProfile>())
          v.id: v,
      };

      return [
        for (final v in liveLocal) serverNewerById[v.id] ?? v,
        ...downloaded,
      ];
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {'where': 'VehiclesSync.merge FAILED'}));
      return localVehicles;
    }
  }

  /// Remove a single vehicle from the server (called on explicit
  /// delete from the vehicle list screen). Silent on failure — the
  /// local delete already happened and there's nothing the caller
  /// can do about a transient network blip.
  static Future<void> delete(String vehicleId) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      // #3078/#3123 — tombstone-first (journal-backed): the tombstone must
      // not depend on the row delete succeeding.
      await DeletionsSync.record('vehicles', vehicleId);
      await client
          .from('vehicles')
          .delete()
          .eq('user_id', userId)
          .eq('id', vehicleId);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {'where': 'VehiclesSync.delete FAILED'}));
    }
  }
}
