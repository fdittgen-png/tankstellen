// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/storage_repository.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/storage/storage_providers.dart';
import '../data/itineraries_sync.dart';
import '../../../core/sync/deletions_sync.dart';
import '../../../core/sync/sync_events.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/utils/event_loop_yield.dart';
import '../domain/entities/saved_itinerary.dart';
import '../../route_search/domain/entities/route_info.dart';

part 'itinerary_provider.g.dart';

/// Whether the first server merge is still running (#3993).
///
/// [ItineraryNotifier.build] returns LOCAL rows synchronously, so the
/// list is usually correct immediately. It is not for the one user who
/// matters here: a fresh device whose routes exist only on the server.
/// For them the local list is empty until the merge lands, and the
/// screen would state — as fact — that they have no saved routes.
///
/// This flag is true only while that first merge is in flight AND the
/// local list came back empty, which is exactly the window where
/// "you have none" would be a lie.
@Riverpod(keepAlive: true)
class ItineraryFirstLoad extends _$ItineraryFirstLoad {
  @override
  bool build() => false;

  // ignore: use_setters_to_change_properties
  void set(bool value) => state = value;
}

/// Manages saved itineraries with local-first strategy:
/// - Save locally first, then sync to DB
/// - Load from DB first, then overwrite with local (local wins)
/// - Sync only adds/changes, never deletes (except explicit user delete)
@Riverpod(keepAlive: true)
class ItineraryNotifier extends _$ItineraryNotifier {
  bool _mergeInFlight = false;

  @override
  List<SavedItinerary> build() {
    // Start with local data immediately
    final storage = ref.read(storageRepositoryProvider);
    final local = _fromStorage(storage);
    // #3446 — refresh from LOCAL storage whenever a sync pull persists
    // itinerary rows (mirrors the LiveHarshEventBus subscribe idiom).
    // Re-reading storage (never the network) means no emit loops.
    final sub = SyncEvents.instance
        .forTable(SyncTables.itineraries)
        .listen((_) => _refreshFromStorage());
    ref.onDispose(sub.cancel);
    // Kick off async merge in background. #3993 — when there is nothing
    // local to show, the screen must say "loading", not "you have none",
    // until this lands. The flag is raised INSIDE the microtask:
    // Riverpod forbids a provider writing to another one while it is
    // still building.
    final localWasEmpty = local.isEmpty;
    unawaited(Future.microtask(() async {
      if (localWasEmpty) {
        ref.read(itineraryFirstLoadProvider.notifier).set(true);
      }
      await _loadAndMerge();
    }));
    return local;
  }

  /// Re-read the persisted itineraries (newest edit first — the same
  /// ordering `_loadAndMerge` applies).
  void _refreshFromStorage() {
    final storage = ref.read(storageRepositoryProvider);
    state = _fromStorage(storage)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<SavedItinerary> _fromStorage(ItineraryStorage storage) {
    try {
      return storage.getItineraries().map((r) {
        return SavedItinerary(
          id: r['id'] as String,
          name: r['name'] as String,
          waypoints: (r['waypoints'] as List).cast<Map<String, dynamic>>(),
          distanceKm: (r['distanceKm'] as num?)?.toDouble() ?? (r['distance_km'] as num?)?.toDouble() ?? 0,
          durationMinutes: (r['durationMinutes'] as num?)?.toDouble() ?? (r['duration_minutes'] as num?)?.toDouble() ?? 0,
          avoidHighways: r['avoidHighways'] as bool? ?? r['avoid_highways'] as bool? ?? false,
          fuelType: r['fuelType'] as String? ?? r['fuel_type'] as String? ?? 'e10',
          selectedStationIds: (r['selectedStationIds'] as List?)?.cast<String>() ??
              (r['selected_station_ids'] as List?)?.cast<String>() ?? [],
          createdAt: DateTime.tryParse(r['createdAt']?.toString() ?? r['created_at']?.toString() ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(r['updatedAt']?.toString() ?? r['updated_at']?.toString() ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {'where': 'ItineraryNotifier._fromStorage'}));
      return [];
    }
  }

  /// Load from DB first, then merge with local (local wins on conflict).
  /// Returns the count of server-only itineraries persisted locally.
  ///
  /// Concurrent invocations are coalesced: if a merge is already
  /// in-flight the second caller returns immediately (with 0). This
  /// prevents the double-fetch that would otherwise happen when build()
  /// and initState() both call this at navigation time.
  Future<int> _loadAndMerge() async {
    if (_mergeInFlight) return 0;
    _mergeInFlight = true;
    var added = 0;
    try {
      final syncState = ref.read(syncStateProvider);
      if (!syncState.enabled) return 0;

      final serverItineraries = await ItinerariesSync.fetchAll();
      if (serverItineraries.isEmpty) return 0;

      final storage = ref.read(storageRepositoryProvider);
      final localIds = state.map((i) => i.id).toSet();

      // Merge: add server-only items, local items win on conflict
      final merged = [...state];
      for (final serverItem in serverItineraries) {
        if (!localIds.contains(serverItem.id)) {
          merged.add(serverItem);
          // Also save to local storage
          await storage.addItinerary(_toMap(serverItem));
          // #3451 — chunk the bulk persist.
          await yieldToEventLoopEvery(added);
          added++;
        }
      }
      // #3446 — pulled rows are persisted; announce them on the sync bus
      // (dropped when zero) AFTER the writes above.
      SyncEvents.instance
          .emit(SyncTableChanged(SyncTables.itineraries, added));

      // Sort by updatedAt descending
      merged.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = merged;

      // Upload local-only items to server in parallel (sync adds, never deletes).
      final serverIds = serverItineraries.map((i) => i.id).toSet();
      var localOnly = state.where((i) => !serverIds.contains(i.id)).toList();
      if (localOnly.isNotEmpty) {
        // #4056 — a local-only itinerary is not always "never uploaded":
        // after "Delete synced data → Itineraries" it is a copy the user
        // chose to KEEP HERE, and its id is tombstoned. Re-uploading it
        // would undo the deletion on every other device.
        final tombstoned =
            await DeletionsSync.fetchTombstonedIds('itineraries');
        if (tombstoned.isNotEmpty) {
          localOnly =
              localOnly.where((i) => !tombstoned.contains(i.id)).toList();
        }
        if (localOnly.isNotEmpty) {
          await Future.wait(localOnly.map(ItinerariesSync.save));
        }
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {'where': 'ItineraryNotifier._loadAndMerge'}));
    } finally {
      _mergeInFlight = false;
      // #3993 — the first-load window closes on EVERY exit path,
      // including the sync-disabled early return and the error branch:
      // a flag that only clears on success strands the screen on a
      // spinner forever.
      ref.read(itineraryFirstLoadProvider.notifier).set(false);
    }
    return added;
  }

  /// Reload from server (pull-to-refresh, launch/resume/sync-now pulls).
  /// Returns the count of server-only itineraries persisted (#3447).
  Future<int> loadFromServer() => _loadAndMerge();

  /// Save a new itinerary — local first, then sync.
  Future<bool> saveRoute({
    required String name,
    required List<RouteWaypoint> waypoints,
    required double distanceKm,
    required double durationMinutes,
    required bool avoidHighways,
    required String fuelType,
    List<String> selectedStationIds = const [],
  }) async {
    final itinerary = SavedItinerary(
      id: const Uuid().v4(),
      name: name,
      waypoints: waypoints.map((w) => <String, dynamic>{
        'lat': w.lat,
        'lng': w.lng,
        'label': w.label,
      }).toList(),
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      avoidHighways: avoidHighways,
      fuelType: fuelType,
      selectedStationIds: selectedStationIds,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 1. Save locally first
    final storage = ref.read(storageRepositoryProvider);
    await storage.addItinerary(_toMap(itinerary));
    state = [itinerary, ...state];

    // 2. Sync to server (non-blocking)
    try {
      await ItinerariesSync.save(itinerary);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {'where': 'ItineraryNotifier.saveRoute'}));
    }

    return true;
  }

  /// Delete an itinerary — local + server.
  Future<void> delete(String id) async {
    // 1. Delete locally
    final storage = ref.read(storageRepositoryProvider);
    await storage.deleteItinerary(id);
    state = state.where((i) => i.id != id).toList();

    // 2. Delete from server
    try {
      await ItinerariesSync.delete(id);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: const {'where': 'ItineraryNotifier.delete'}));
    }
  }

  /// Put a deleted itinerary back exactly as it was (#3993).
  ///
  /// The undo path, not a second save: [saveRoute] mints a new id and
  /// fresh timestamps, which would resurrect the route as a stranger —
  /// a different row on the server, and a different position in the
  /// newest-first list. This restores the captured entity verbatim.
  Future<void> restore(SavedItinerary itinerary) async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.addItinerary(_toMap(itinerary));
    state = [...state, itinerary]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    try {
      await ItinerariesSync.save(itinerary);
    } catch (e, st) {
      // ADR 0021 — new code goes through the one logging façade
      // rather than reaching for the error logger by hand.
      log.error(e, st, layer: ErrorLayer.sync,
          context: const {'where': 'ItineraryNotifier.restore'});
    }
  }

  Map<String, dynamic> _toMap(SavedItinerary i) => {
    'id': i.id,
    'name': i.name,
    'waypoints': i.waypoints,
    'distanceKm': i.distanceKm,
    'durationMinutes': i.durationMinutes,
    'avoidHighways': i.avoidHighways,
    'fuelType': i.fuelType,
    'selectedStationIds': i.selectedStationIds,
    'createdAt': i.createdAt.toIso8601String(),
    'updatedAt': i.updatedAt.toIso8601String(),
  };
}
