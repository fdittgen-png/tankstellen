// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../features/alerts/data/models/price_alert.dart';
import '../telemetry/collectors/breadcrumb_collector.dart';
import '../utils/json_extensions.dart';
import 'entity_sync.dart';
import 'sync_transport.dart';

/// Price-alert sync with Supabase, pulled out of [SyncService] (#727).
/// Since #3127 a thin codec config over the shared [EntitySync] engine.
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
/// Per that rule this stays a pure id-union merge for now (no
/// `localStamp` in the config below); edit propagation for alerts is
/// deferred to the sync epic alongside the schema-version bump.
class AlertsSync {
  AlertsSync._();

  static final _sync = EntitySync<PriceAlert>(
    table: 'alerts',
    logName: 'AlertsSync',
    idColumn: 'id',
    selectColumns: '*',
    onConflict: 'id',
    idOf: (a) => a.id,
    encode: (a, userId) => {
      'id': a.id,
      'user_id': userId,
      'station_id': a.stationId,
      'station_name': a.stationName,
      'fuel_type': a.fuelType.name,
      'target_price': a.targetPrice,
      'is_active': a.isActive,
      'created_at': a.createdAt.toUtc().toIso8601String(),
    },
    decode: (r) => PriceAlert.fromJson({
      'id': r.getString('id') ?? '',
      'stationId': r.getString('station_id') ?? '',
      'stationName': r.getString('station_name') ?? '',
      'fuelType': r.getString('fuel_type') ?? '',
      'targetPrice': r.getDouble('target_price') ?? 0.0,
      'isActive': r.getBool('is_active') ?? true,
      'createdAt': r.getString('created_at') ?? '',
    }),
    // #3121 — alerts tombstone AFTER the row-delete attempt (and
    // regardless of its outcome); see [EntitySync.tombstoneFirstDelete].
    tombstoneFirstDelete: false,
  );

  /// Merge [localAlerts] with the user's `alerts` rows on Supabase.
  /// Returns the superset ([local] + server-only downloaded). The
  /// engine drops tombstoned ids from BOTH sides before the union so a
  /// deleted alert can't resurrect through the launch pull or another
  /// device's still-local copy (#3121, same seam as favorites #3078).
  /// [transport] is injectable for tests.
  /// #3370 — the `alerts.id` column is a Postgres `uuid`, but two creation
  /// paths historically minted non-UUID ids (a `stationId_fuel_ts` composite
  /// in the create-alert dialog; the bare station id in the station-info
  /// section), so syncing them hit `22P02 invalid input syntax for type uuid`
  /// on every merge (recurring field reports). Such alerts can never round-trip
  /// to Supabase, so partition them out of the SERVER sync and keep them
  /// local-only — the user still sees them; they simply don't sync until they
  /// carry a valid UUID. No data loss (they were erroring, not syncing).
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static Future<List<PriceAlert>> merge(
    List<PriceAlert> localAlerts, {
    SyncTransport? transport,
  }) async {
    final syncable = <PriceAlert>[];
    final localOnly = <PriceAlert>[];
    for (final a in localAlerts) {
      (_uuidPattern.hasMatch(a.id) ? syncable : localOnly).add(a);
    }
    if (localOnly.isNotEmpty) {
      BreadcrumbCollector.add(
        'alerts sync: ${localOnly.length} alert(s) kept local — non-UUID id',
        detail: 'legacy station/composite ids cannot round-trip the uuid '
            'column (#3370); they stay on this device.',
      );
    }
    final merged = await _sync.merge(syncable, transport: transport);
    // Union: server-merged UUID alerts + the local-only non-UUID ones, so the
    // user keeps seeing every alert regardless of whether it can sync.
    return [...merged, ...localOnly];
  }

  /// Delete a single alert row from the server and tombstone the id
  /// (#3121). Called only when the user explicitly removes an alert on
  /// this device — the merge path doesn't delete.
  ///
  /// Local-first: the caller's local delete has already happened, so a
  /// server failure is logged, not rethrown — and the `deletions`
  /// tombstone is recorded regardless, so every later [merge] filters the
  /// id out even when the row delete failed transiently.
  static Future<void> delete(String id, {SyncTransport? transport}) =>
      _sync.delete(id, transport: transport);
}
