// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/alerts/data/models/price_alert.dart';
import '../utils/json_extensions.dart';
import 'deletions_sync.dart';
import 'supabase_client.dart';
import 'sync_helper.dart';
import 'sync_transport.dart';
import '../../core/logging/error_logger.dart';

/// Price-alert sync with Supabase, pulled out of [SyncService] (#727).
///
/// Bidirectional merge:
///   - local-only alerts upload to the `alerts` table (`id`-conflict
///     upsert so replaying an already-synced alert is a no-op).
///   - server-only alerts download and the caller returns a merged
///     `[localAlerts, ...downloaded]` list.
///
/// Unauthenticated / offline paths return the input list unchanged —
/// the alert UI keeps working on pure-local state.
///
/// **#3122 LWW deferral:** unlike `fill_ups` / `vehicles`, the `alerts`
/// table carries neither a JSONB `data` blob nor an `updated_at` column,
/// so there is no server-side stamp to compare a local edit against —
/// adding one is a new explicit column, i.e. a self-host schema change
/// (HARD RULE 5: wizard SQL + verifier + `kSupabaseSchemaVersion` bump).
/// Per that rule this stays a pure id-union merge for now; edit
/// propagation for alerts is deferred to the sync epic alongside the
/// schema-version bump.
class AlertsSync {
  AlertsSync._();

  /// Merge [localAlerts] with the user's `alerts` rows on Supabase.
  /// Returns the superset ([local] + server-only downloaded).
  /// [transport] is injectable for tests.
  static Future<List<PriceAlert>> merge(
    List<PriceAlert> localAlerts, {
    SyncTransport? transport,
  }) async {
    final t = transport ?? SupabaseSyncTransport.currentOrNull();
    if (t == null) {
      debugPrint('AlertsSync.merge: not authenticated');
      return localAlerts;
    }

    try {
      final serverRows = await t.select('alerts', '*');
      // #3121 — drop tombstoned ids from BOTH sides before the union so a
      // deleted alert can't resurrect through the launch pull or another
      // device's still-local copy (same seam as favorites/ignored, #3078).
      final tombstoned =
          await DeletionsSync.fetchTombstonedIds('alerts', transport: t);
      final liveServerRows = SyncHelper.removeTombstoned(
        serverRows,
        tombstoned,
        key: (r) => r.getString('id'),
      ).toList();
      final liveLocalAlerts =
          localAlerts.where((a) => !tombstoned.contains(a.id)).toList();
      final serverAlertIds = liveServerRows
          .map((r) => r.getString('id'))
          .whereType<String>()
          .toSet();
      final localAlertIds = liveLocalAlerts.map((a) => a.id).toSet();

      debugPrint('AlertsSync.merge: local=${localAlertIds.length}, '
          'server=${serverAlertIds.length}');

      // Upload local-only alerts.
      final localOnly =
          liveLocalAlerts.where((a) => !serverAlertIds.contains(a.id)).toList();
      if (localOnly.isNotEmpty) {
        final rows = localOnly
            .map((a) => {
                  'id': a.id,
                  'user_id': t.userId,
                  'station_id': a.stationId,
                  'station_name': a.stationName,
                  'fuel_type': a.fuelType.name,
                  'target_price': a.targetPrice,
                  'is_active': a.isActive,
                  'created_at': a.createdAt.toUtc().toIso8601String(),
                })
            .toList();
        await t.upsert('alerts', rows, onConflict: 'id');
        debugPrint('AlertsSync.merge: uploaded ${localOnly.length} alerts');
      }

      // Download server-only alerts.
      final serverOnly = liveServerRows
          .where((r) => !localAlertIds.contains(r.getString('id')));
      final downloaded = serverOnly.map((r) {
        return PriceAlert.fromJson({
          'id': r.getString('id') ?? '',
          'stationId': r.getString('station_id') ?? '',
          'stationName': r.getString('station_name') ?? '',
          'fuelType': r.getString('fuel_type') ?? '',
          'targetPrice': r.getDouble('target_price') ?? 0.0,
          'isActive': r.getBool('is_active') ?? true,
          'createdAt': r.getString('created_at') ?? '',
        });
      }).toList();

      return [...liveLocalAlerts, ...downloaded];
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {'where': 'AlertsSync.merge FAILED'}));
      return localAlerts;
    }
  }

  /// Delete a single alert row from the server and tombstone the id
  /// (#3121). Called only when the user explicitly removes an alert on
  /// this device — the merge path doesn't delete. Mirrors the
  /// `FavoritesSync.delete` pattern.
  ///
  /// Local-first: the caller's local delete has already happened, so a
  /// server failure is logged, not rethrown — and the `deletions`
  /// tombstone is recorded regardless, so every later [merge] filters the
  /// id out even when the row delete failed transiently.
  static Future<void> delete(String id) async {
    final client = TankSyncClient.client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    try {
      await client.from('alerts').delete().eq('user_id', userId).eq('id', id);
      debugPrint('AlertsSync.delete: $id removed from server');
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: const {'where': 'AlertsSync.delete FAILED'}));
    }
    // #3121 — tombstone regardless of the row-delete outcome (record has
    // its own internal guard), so the next merge filters the id either way.
    await DeletionsSync.record('alerts', id);
  }
}
