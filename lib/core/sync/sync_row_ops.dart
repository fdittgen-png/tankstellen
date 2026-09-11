// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../../core/error/guarded.dart';
import '../../core/logging/error_logger.dart';
import '../../core/logging/app_log.dart';
import '../time/app_clock.dart';
import 'deletions_sync.dart';
import 'sync_device_identity.dart';
import 'sync_transport.dart';

/// The row-level Supabase conventions every synced entity shares — the
/// half of the sync layer that knows nothing about a merge.
///
/// These lived as statics on `EntitySync<T>` but never touched a single
/// instance field or the type parameter: a tombstone-and-delete, the
/// forensic origin stamps, the LWW `updated_at` value and the resilient
/// JSONB-blob decoder are facts about *a row on the wire*, not about the
/// merge engine. Entities with a bespoke read path (ratings, baselines,
/// itineraries) call them without ever constructing an [EntitySync], so
/// hanging them off it only made the engine file the place to look for
/// something it does not do.
class SyncRowOps {
  const SyncRowOps._();

  /// Delete one server row and record its durable tombstone
  /// (#3078/#3121/#3123) so no later merge resurrects it. Used by
  /// `EntitySync.delete` AND by the entities that share the delete but
  /// not the read path. Returns `true` when the server row delete
  /// succeeded, `false` when unauthenticated or on a transient failure
  /// (the tombstone intent stays journaled either way, #3123).
  static Future<bool> deleteRow({
    required String table,
    required String idColumn,
    required String recordId,
    required String logContext,
    bool tombstoneFirst = true,
    SyncTransport? transport,
  }) async {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) return false;

    // #3078/#3123 — tombstone-first (journal-backed) by default: the
    // durable "this id is dead" record must not depend on the row delete
    // succeeding. `recordAll` has its own internal guard and does not
    // throw back into this flow.
    if (tombstoneFirst) {
      await DeletionsSync.recordAll(table, [recordId], transport: t);
    }
    var deleted = false;
    try {
      await t.deleteWhere(table, {idColumn: recordId});
      debugPrint('$logContext: $recordId removed from server');
      deleted = true;
    } catch (e, st) {
      log.error(e, st,
          layer: ErrorLayer.sync, context: {'where': '$logContext FAILED'});
    }
    // #3121 — the alerts ordering: tombstone regardless of the row-delete
    // outcome, after the delete attempt.
    if (!tombstoneFirst) {
      await DeletionsSync.recordAll(table, [recordId], transport: t);
    }
    return deleted;
  }

  /// The #3125 forensic origin stamps every uploaded JSONB `data` blob
  /// carries (sync-transparent: decode ignores unknown keys, every
  /// re-upload re-stamps with the writing device).
  static Map<String, dynamic> forensicStamps() => {
        'device_id': SyncDeviceIdentity.deviceId,
        'app_version': SyncDeviceIdentity.appVersion,
      };

  /// The `updated_at` column value for an upload: carry the local edit
  /// stamp so the next LWW compare sees equal stamps (skip) instead of a
  /// phantom-newer server row; legacy unstamped records fall back to
  /// upload time. Always UTC (#3124).
  ///
  /// The fallback reads the wall clock through the #3660 [AppClock] seam
  /// rather than raw, so a test can pin the stamp the same way it pins
  /// every other time-dependent assertion.
  static String lwwStamp(DateTime? updatedAt,
          {AppClock clock = const SystemClock()}) =>
      (updatedAt ?? clock.now()).toUtc().toIso8601String();

  /// A per-row resilient decoder for the JSONB-`data`-blob tables
  /// (`fill_ups` / `vehicles`): a corrupt row logs under [where] and is
  /// skipped instead of aborting the whole merge.
  static T? Function(JsonRow) jsonbDataDecoder<T>(
    T Function(Map<String, dynamic> json) fromJson, {
    required String where,
  }) =>
      (row) {
        final data = row['data'];
        if (data is! Map<String, dynamic>) return null;
        try {
          return fromJson(data);
        } catch (e, st) {
          logFailure(e, st, where: where, layer: ErrorLayer.sync);
          return null;
        }
      };
}
