// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/data/storage_repository.dart';
import '../../core/logging/error_logger.dart';
import '../../core/perf/launch_sync_trace.dart';
import '../../core/storage/hive_boxes.dart';
import '../../core/sync/supabase_client.dart';
import '../../core/sync/sync_events.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/sync/trips_sync.dart';
import '../../core/sync/trips_sync_enabled_provider.dart';
import '../../features/alerts/providers/alert_provider.dart';
import '../../features/consumption/data/trip_history_repository.dart';
import '../../features/consumption/providers/consumption_providers.dart';
import '../../features/feature_management/application/feature_flags_provider.dart';
import '../../features/feature_management/domain/feature.dart';
import '../../features/vehicle/providers/vehicle_providers.dart';

/// Launch-time server→local sync merges — extracted from `AppInitializer`
/// by the #3139 phase decomposition.
///
/// ## Ordering contract (#3139)
///
/// `AppInitializer.run()` awaits both merges inside the SAME
/// post-first-frame closure as `CommunityConfig.load()` and the TankSync
/// init, strictly AFTER both: the merges read `TankSyncClient.client`,
/// and they must also follow the #3126 `SyncRunTrace.begin('launch')`
/// mint so the per-table sync counts thread under one run id.
/// [runTripsSyncMerge] runs BEFORE [runEntitySyncMerge], preserving the
/// pre-decomposition order (the trips merge predates the entity pulls
/// and the entity pass piggybacks on its no-op guards being warm).
///
/// Every failure is caught and routed through [errorLogger]
/// (`ErrorLayer.sync`); nothing in this phase may block or crash the
/// running app.
class LaunchSyncPhase {
  LaunchSyncPhase._();

  /// Test seam for the `TankSyncClient.client != null` readiness guard —
  /// the static client has no injection point, so the launch-span tests
  /// (#3445) force readiness here instead of standing up Supabase.
  @visibleForTesting
  static bool Function()? clientReadyOverride;

  static bool get _clientReady =>
      clientReadyOverride?.call() ?? (TankSyncClient.client != null);

  /// #3445 — arm the launch-sync span recorder from the
  /// `Feature.startupTrace` devtool flag. Lives HERE (app layer) because
  /// core/perf must not import feature_management; returns `null` (zero
  /// overhead) when the flag is off.
  static LaunchSyncTrace? armTrace(ProviderContainer container) =>
      LaunchSyncTrace.maybeArm(
        enabled: container
            .read(enabledFeaturesProvider)
            .contains(Feature.startupTrace),
      );

  /// #1541 — on app launch, merge local trip summaries with the
  /// server's `trip_summaries` rows so cross-device entries land in
  /// the user's history without needing a manual sync gesture. Heavy
  /// `trip_details` rows older than 90 days are pruned in the same
  /// pass.
  ///
  /// No-ops cleanly when:
  /// - TankSync isn't initialised (the user opted out or init
  ///   timed out above), or
  /// - the `obd2_trip_history` Hive box isn't open, or
  /// - the user isn't authenticated (the `TripsSync` methods
  ///   themselves short-circuit on null user id).
  ///
  /// Failures are caught + logged. The merge result tolerates a
  /// missing server row — `TripsSync.merge` returns the input
  /// unchanged on error so a transient network blip never costs the
  /// user their local history view.
  static Future<void> runTripsSyncMerge(
    ProviderContainer container, {
    LaunchSyncTrace? trace,
  }) async {
    // #1794 — `obd2TripHistory` is a deferred box; wait for the
    // post-first-frame opens before reading it.
    await HiveBoxes.initDeferred();
    if (!_clientReady) return;
    if (!Hive.isBoxOpen(HiveBoxes.obd2TripHistory)) return;
    // #1665 — gate the launch-time merge on the trajet-sync gate so an
    // anonymous session no longer downloads / heals trip rows.
    if (!container.read(tripsSyncEnabledProvider)) return;
    var saved = 0;
    await LaunchSyncTrace.spanned(trace, 'trips_merge', () async {
      try {
        final repo = TripHistoryRepository(
          box: Hive.box<String>(HiveBoxes.obd2TripHistory),
        );
        final local = repo.loadAll();
        final localIds = local.map((e) => e.id).toSet();
        final merged = await TripsSync.merge(local);
        // Persist server-only entries — those whose ids weren't in the
        // local set before the merge. The summaries-only blob lands now;
        // the heavy samples + gpsd payload arrives via the trip-detail
        // screen's lazy fetch on first open.
        for (final entry in merged) {
          if (localIds.contains(entry.id)) continue;
          await repo.save(entry);
          saved++;
        }
        // Retention pass — drop server-side detail blobs that have
        // aged past the default 90-day window so the per-user storage
        // budget stays bounded.
        await TripsSync.pruneOldDetails();
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.sync, e, st,
            context: {'where': 'runTripsSyncMerge'}));
      }
      // #3446 — the pulled summaries are in Hive now; refresh the trip
      // history UI. Emitted even when the catch above fired (whatever
      // was saved before the failure IS persisted).
      SyncEvents.instance
          .emit(SyncTableChanged(SyncTables.tripSummaries, saved));
    }, attributes: () => {'table': SyncTables.tripSummaries, 'pulled': saved});
  }

  /// #3077 — on app launch, pull the remaining server→local entities into
  /// local storage so cross-device rows land without a manual sync
  /// gesture. TankSync was upload-only for these: the download branch
  /// existed in each `*_sync.dart` but had no connect/launch caller
  /// (fill-ups + vehicles), its return was discarded (ratings), or it only
  /// fired on a local edit (alerts). The per-entity pull-persist seams are
  /// the unit-tested units; this method is the launch-time glue.
  ///
  /// Consent gates (conservative — never pull data the user hasn't
  /// consented to):
  /// - **ratings / alerts** ride the master TankSync consent — they pull
  ///   whenever `sync_enabled` is set (the same gate the existing
  ///   favorites/ignored pull and the alert-mutation pull already use).
  /// - **fill-ups / vehicles** are trip-data adjacent (fill-ups carry
  ///   linked trajet ids + OBD2-derived consumption; a vehicle profile is
  ///   the anchor trips attach to), so they ride the stricter trip-sync
  ///   gate (`tripsSyncEnabledProvider` = email ∧ cloudSync ∧ syncTrips).
  ///
  /// No-ops cleanly when TankSync isn't initialised or the user is signed
  /// out. Each entity is independently error-protected AND time-budgeted
  /// (#3128) so one failing or hung pull never blocks the others.
  static Future<void> runEntitySyncMerge(
    ProviderContainer container,
    StorageRepository storage, {
    LaunchSyncTrace? trace,
  }) async {
    if (!_clientReady) return;
    if (!container.read(syncStateProvider).enabled) return;

    // ratings + alerts ride the master consent; fill-ups + vehicles are
    // trip-data adjacent and ride the stricter trip-sync gate. Keys are
    // the Supabase table names — they double as the #3445 span names.
    final tripData = container.read(tripsSyncEnabledProvider);
    final pulls = <String, Future<int> Function()>{
      SyncTables.stationRatings: () => container
          .read(syncStateProvider.notifier)
          .syncAndPersistRatings(storage),
      SyncTables.alerts: () =>
          container.read(alertProvider.notifier).pullFromServer(),
      if (tripData)
        SyncTables.vehicles: () => container
            .read(vehicleProfileListProvider.notifier)
            .pullFromServer(),
      if (tripData)
        SyncTables.fillUps: () =>
            container.read(fillUpListProvider.notifier).pullFromServer(),
    };
    for (final entry in pulls.entries) {
      var pulled = 0;
      await LaunchSyncTrace.spanned(trace, entry.key, () async {
        try {
          pulled = await entry.value().timeout(const Duration(seconds: 15));
        } on TimeoutException catch (e, st) {
          unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: {
            'where': 'entity pull timed out',
            'entity': entry.key,
          }));
        } catch (e, st) {
          unawaited(errorLogger.log(ErrorLayer.sync, e, st,
              context: {'where': 'entity pull FAILED', 'entity': entry.key}));
        }
      }, attributes: () => {'table': entry.key, 'pulled': pulled});
      // #3446 — fill-ups' persist site (`FillUpList.mergeFrom`) lives in
      // the length-frozen consumption_providers.dart (#3138), so its
      // pull emits at this call site; every OTHER entity emits at its
      // persist site (ratings in SyncState, alerts/vehicles in their
      // notifiers).
      if (entry.key == SyncTables.fillUps) {
        SyncEvents.instance.emit(SyncTableChanged(entry.key, pulled));
      }
    }
  }
}
