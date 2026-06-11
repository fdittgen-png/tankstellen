// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/logging/error_logger.dart';
import '../../features/consumption/data/baseline_sync.dart';
import 'deletions_sync.dart';
import 'entity_sync.dart';
import 'sync_transport.dart';

/// Per-vehicle OBD2 baseline sync with Supabase (#780), pulled out of
/// [SyncService] (#727).
///
/// Baselines keep a bespoke merge (NOT the #3127 [EntitySync] union:
/// the payload is a JSON blob keyed by driving situation, and the merge
/// rule is "for every situation, the accumulator with the higher sample
/// count wins" — that logic lives in
/// `features/consumption/data/baseline_sync.dart` (`mergeBaselineJson`,
/// `totalSampleCount`)). Since #3127 the I/O rides the injectable
/// [SyncTransport] seam and the delete shares [EntitySync.deleteRow].
class BaselinesSync {
  BaselinesSync._();

  static const _table = 'obd2_baselines';

  /// Two-way merge of one vehicle's baseline. Returns the merged JSON
  /// payload that callers should persist locally; returns the
  /// original [localJson] unchanged when offline or unauthenticated,
  /// so baseline recording keeps working without the cloud layer.
  ///
  /// [totalSampleCountOverride] lets the caller supply a pre-computed
  /// total — the Dart layer already counts samples for the status UI,
  /// so we avoid decoding the JSON twice when it's already available.
  /// [transport] is injectable for tests.
  static Future<String?> merge({
    required String vehicleId,
    required String? localJson,
    int? totalSampleCountOverride,
    SyncTransport? transport,
  }) async {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) {
      debugPrint('BaselinesSync.merge: not authenticated');
      return localJson;
    }

    try {
      // #3078 — a baseline the user "forgot" on another device must not be
      // re-uploaded here. If this vehicle's baseline is tombstoned, leave the
      // local copy untouched and don't push it back to the server.
      final tombstoned =
          await DeletionsSync.fetchTombstonedIds(_table, transport: t);
      if (tombstoned.contains(vehicleId)) {
        debugPrint('BaselinesSync.merge: $vehicleId tombstoned — skipping');
        return localJson;
      }

      final serverRows = await t.select(
        _table,
        'data',
        filters: {'vehicle_id': vehicleId},
      );
      final serverData = serverRows.isEmpty
          ? null
          : (serverRows.first['data'] as Map?)?.cast<String, dynamic>();

      final merged = mergeBaselineJson(
        localJson,
        serverData == null ? null : jsonEncode(serverData),
      );
      if (merged == null) return localJson;

      final mergedDecoded =
          (jsonDecode(merged) as Map).cast<String, dynamic>();
      final total =
          totalSampleCountOverride ?? totalSampleCount(mergedDecoded);

      await t.upsert(
        _table,
        [
          {
            'user_id': t.userId,
            'vehicle_id': vehicleId,
            'total_samples': total,
            'data': mergedDecoded,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
        ],
        onConflict: 'user_id,vehicle_id',
      );
      return merged;
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'BaselinesSync.merge FAILED'}));
      return localJson;
    }
  }

  /// Remove a single vehicle's baseline from the server. Called on
  /// explicit "Forget baseline" from the vehicle edit UI. Tombstone-
  /// first (journal-backed, #3078/#3123) via the shared
  /// [EntitySync.deleteRow]. Silent on failure — there's nothing the
  /// caller can do about a network blip, and the local copy is already
  /// gone by the time this runs.
  static Future<void> delete(String vehicleId, {SyncTransport? transport}) =>
      EntitySync.deleteRow(
        table: _table,
        idColumn: 'vehicle_id',
        recordId: vehicleId,
        logContext: 'BaselinesSync.delete',
        transport: transport,
      );
}
