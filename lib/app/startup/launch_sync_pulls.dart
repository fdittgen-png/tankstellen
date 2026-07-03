// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/data/storage_repository.dart';
import '../../core/logging/error_logger.dart';
import '../../core/storage/hive_boxes.dart';
import '../../core/sync/baselines_sync.dart';
import '../../core/sync/sync_events.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/sync/sync_pull_coordinator.dart';
import '../../core/sync/trips_sync.dart';
import '../../core/sync/trips_sync_enabled_provider.dart';
import '../../core/utils/event_loop_yield.dart';
import '../../features/alerts/providers/alert_provider.dart';
import '../../features/consumption/data/trip_history_repository.dart';
import '../../features/consumption/providers/consumption_providers.dart';
import '../../features/itinerary/providers/itinerary_provider.dart';
import '../../features/sync/providers/baseline_sync_enabled_provider.dart';
import '../../features/vehicle/providers/vehicle_providers.dart';

/// The per-table pull thunks behind the #3447 [SyncPullCoordinator]
/// registration — the app-layer glue that reads feature providers, which
/// neither the core coordinator nor the feature-side "sync now" caller may
/// import. `LaunchSyncPhase.registerPulls` builds the entry list from
/// here; launch, app-resume and "sync now" all replay the SAME list, so
/// full pull coverage is one registration instead of three drifting call
/// sites.
///
/// Contracts every thunk honours:
///  * its consent gate is INSIDE (off → return 0 without touching the
///    network) — conservative, never pull data the user hasn't consented
///    to: vehicles/fill-ups ride `tripsSyncEnabledProvider` (#3448:
///    consent ∧ toggle), baselines ride `baselineSyncEnabledProvider`,
///    everything else rides the master `sync_enabled` gate the
///    coordinator itself checks;
///  * a `SyncTableChanged` emit AFTER the persist (#3446) — either at the
///    persist site inside the feature notifier, or here when the persist
///    site is length-frozen (`FillUpList.mergeFrom`, #3138);
///  * bulk Hive writes yield to the event loop every
///    [kBulkWriteYieldEvery] rows (#3451).
class LaunchSyncPulls {
  LaunchSyncPulls._();

  /// The full pull matrix. Every synced table in [SyncTables.all] must be
  /// covered by exactly one entry — pinned by
  /// `test/core/sync/sync_pull_matrix_test.dart`.
  static List<SyncPullEntry> buildEntries(
    ProviderContainer container,
    StorageRepository storage,
  ) =>
      [
        // #3450 — the trips merge downloads whole summary blobs; it gets a
        // wider 20 s budget than the 15 s per-table default.
        SyncPullEntry(
          tables: const [SyncTables.tripSummaries],
          timeout: const Duration(seconds: 20),
          pull: () => pullTrips(container),
        ),
        SyncPullEntry(
          tables: const [SyncTables.favorites, SyncTables.ignoredStations],
          pull: () => pullIdSets(container, storage),
        ),
        SyncPullEntry(
          tables: const [SyncTables.stationRatings],
          pull: () => container
              .read(syncStateProvider.notifier)
              .syncAndPersistRatings(storage),
        ),
        SyncPullEntry(
          tables: const [SyncTables.alerts],
          pull: () => container.read(alertProvider.notifier).pullFromServer(),
        ),
        SyncPullEntry(
          tables: const [SyncTables.itineraries],
          pull: () =>
              container.read(itineraryProvider.notifier).loadFromServer(),
        ),
        SyncPullEntry(
          tables: const [SyncTables.vehicles],
          pull: () => container.read(tripsSyncEnabledProvider)
              ? container
                  .read(vehicleProfileListProvider.notifier)
                  .pullFromServer()
              : Future.value(0),
        ),
        SyncPullEntry(
          tables: const [SyncTables.fillUps],
          pull: () => pullFillUps(container),
        ),
        SyncPullEntry(
          tables: const [SyncTables.obd2Baselines],
          pull: () => pullBaselines(container),
        ),
      ];

  /// #1541/#3450 — merge local trip summaries with the server's
  /// `trip_summaries` rows and persist the server-only entries into the
  /// local history box (summaries only — the heavy `trip_details` blob
  /// arrives via the trip-detail screen's lazy fetch). Heavy detail rows
  /// older than 90 days are pruned in the same pass.
  ///
  /// No-ops cleanly when the `obd2_trip_history` box isn't available or
  /// the #3448 trip-sync gate (consent ∧ toggle) is off; unauthenticated
  /// merges return the input unchanged inside `TripsSync`.
  static Future<int> pullTrips(ProviderContainer container) async {
    // #1794 — deferred box; wait for the post-first-frame opens.
    await HiveBoxes.initDeferred();
    if (!Hive.isBoxOpen(HiveBoxes.obd2TripHistory)) return 0;
    if (!container.read(tripsSyncEnabledProvider)) return 0;
    var changed = 0;
    try {
      final repo = TripHistoryRepository(
        box: Hive.box<String>(HiveBoxes.obd2TripHistory),
      );
      changed = await mergeAndPruneTrips(repo, TripsSync.merge);
      await TripsSync.pruneOldDetails();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st,
          context: {'where': 'LaunchSyncPulls.pullTrips'}));
    }
    // #3446 — emitted even when the catch above fired: whatever was saved
    // before the failure IS persisted.
    SyncEvents.instance
        .emit(SyncTableChanged(SyncTables.tripSummaries, changed));
    return changed;
  }

  /// The trips persist step, seamed on [merge] so the #3453 removal
  /// contract is unit-testable without a live Supabase session.
  ///
  /// Two directions:
  ///  * **save** — entries in the merge result the box doesn't hold yet
  ///    (downloaded from another device);
  ///  * **remove (#3453)** — local entries ABSENT from the merge result:
  ///    `TripsSync.merge` drops tombstoned ids from its local input, so a
  ///    trip deleted server-side (single delete or the "delete my synced
  ///    data" wipe) disappears from this device on its next pull instead
  ///    of lingering forever. A failed/unauthenticated merge returns the
  ///    input unchanged, so nothing is ever removed on error.
  ///
  /// Returns the changed-entry count (saved + removed) for the #3446
  /// emit and #3445 trace attributes.
  @visibleForTesting
  static Future<int> mergeAndPruneTrips(
    TripHistoryRepository repo,
    Future<List<TripHistoryEntry>> Function(List<TripHistoryEntry>) merge,
  ) async {
    final local = repo.loadAll();
    final localIds = local.map((e) => e.id).toSet();
    final merged = await merge(local);
    final mergedIds = merged.map((e) => e.id).toSet();
    var changed = 0;
    for (final entry in merged) {
      if (localIds.contains(entry.id)) continue;
      await repo.save(entry);
      // #3451 — don't starve frame production during a big first pull.
      await yieldToEventLoopEvery(changed);
      changed++;
    }
    for (final entry in local) {
      if (mergedIds.contains(entry.id)) continue;
      await repo.delete(entry.id);
      await yieldToEventLoopEvery(changed);
      changed++;
    }
    return changed;
  }

  /// #3447 — favorites + ignored stations now pull at launch/resume too
  /// (previously connect + "sync now" only). The persist + per-table emits
  /// live in `SyncState.syncAndPersistIds`; the returned count is the
  /// combined id-set delta for the trace attributes.
  static Future<int> pullIdSets(
    ProviderContainer container,
    StorageRepository storage,
  ) async {
    // #3452 — the favorites merge spans BOTH stores (fuel + EV ids with
    // payloads), so the trace delta counts the EV set too.
    final favBefore = {
      ...storage.getFavoriteIds(),
      ...storage.getEvFavoriteIds(),
    };
    final ignBefore = storage.getIgnoredIds().toSet();
    await container.read(syncStateProvider.notifier).syncAndPersistIds(storage);
    int delta(Set<String> before, List<String> after) {
      final a = after.toSet();
      return a.difference(before).length + before.difference(a).length;
    }

    return delta(favBefore,
            [...storage.getFavoriteIds(), ...storage.getEvFavoriteIds()]) +
        delta(ignBefore, storage.getIgnoredIds());
  }

  /// Fill-ups ride the #3448 trip-data gate. The persist site
  /// (`FillUpList.mergeFrom`) lives in the length-frozen
  /// consumption_providers.dart (#3138), so the #3446 emit happens at THIS
  /// call site instead.
  static Future<int> pullFillUps(ProviderContainer container) async {
    if (!container.read(tripsSyncEnabledProvider)) return 0;
    final pulled =
        await container.read(fillUpListProvider.notifier).pullFromServer();
    SyncEvents.instance.emit(SyncTableChanged(SyncTables.fillUps, pulled));
    return pulled;
  }

  /// #3447 — per-vehicle OBD2 baselines now pull at launch/resume (the
  /// bespoke higher-sample-count merge previously only ran on the
  /// post-trip flush, so a second device never saw the baseline until it
  /// finished a trip of its own). Covers every locally-known vehicle:
  /// the profile list ∪ existing baseline box keys. A baseline whose
  /// vehicle is still server-only lands on the NEXT pass, after the
  /// parallel vehicles pull has persisted the profile.
  static Future<int> pullBaselines(ProviderContainer container) async {
    if (!container.read(baselineSyncEnabledProvider)) return 0;
    await HiveBoxes.initDeferred();
    if (!Hive.isBoxOpen(HiveBoxes.obd2Baselines)) return 0;
    final box = Hive.box<String>(HiveBoxes.obd2Baselines);
    const prefix = 'baseline:';
    final vehicleIds = <String>{
      for (final v in container.read(vehicleProfileListProvider)) v.id,
      for (final k in box.keys.whereType<String>())
        if (k.startsWith(prefix)) k.substring(prefix.length),
    };
    var changed = 0;
    for (final vehicleId in vehicleIds) {
      final key = '$prefix$vehicleId';
      final localJson = box.get(key);
      final merged = await BaselinesSync.merge(
        vehicleId: vehicleId,
        localJson: localJson,
      );
      if (merged == null || merged == localJson) continue;
      await box.put(key, merged);
      // #3451 — chunk the bulk persist.
      await yieldToEventLoopEvery(changed);
      changed++;
    }
    SyncEvents.instance
        .emit(SyncTableChanged(SyncTables.obd2Baselines, changed));
    return changed;
  }
}
