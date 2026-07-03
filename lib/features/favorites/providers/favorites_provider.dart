// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/data/storage_repository.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/station_service.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/sync_events.dart';
import '../../../core/sync/sync_helper.dart';
import '../../../core/sync/favorites_sync.dart';
import '../../../core/domain/ev/charging_station.dart' as search_ev;
import '../../price_history/providers/price_prediction_provider.dart';
import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/station.dart';
import '../../search/providers/station_rating_provider.dart';
import '../../widget/data/home_widget_service.dart';
import '../../../core/logging/error_logger.dart';

// #727 — the file this replaces had outgrown its single purpose.
// `FavoriteStations` (fuel-detail fetch + per-country refresh) lives
// in `favorite_stations_provider.dart`, `isFavorite` / `isEvFavorite`
// in `is_favorite_provider.dart`. Re-exported below so existing
// callers that `import 'favorites_provider.dart'` keep working
// without a single call-site change.
export 'favorite_stations_provider.dart';
export 'is_favorite_provider.dart';

part 'favorites_provider.g.dart';

/// Manages the user's list of favorite station IDs.
///
/// ## Local-first pattern:
/// - **Writes**: Save to Hive immediately, then sync to Supabase asynchronously.
/// - **Reads**: Load from Hive on startup (instant), then merge with server data.
/// - **Deletes**: Remove locally + from server (exception to "sync never deletes" rule
///   because this is an explicit user action).
///
/// Uses `keepAlive: true` because favorites persist across the entire app lifecycle.
@Riverpod(keepAlive: true)
class Favorites extends _$Favorites {
  @override
  List<String> build() {
    final storage = ref.watch(storageRepositoryProvider);
    // #3446 — re-read storage whenever a sync pull persists favorites
    // rows (launch / connect / "sync now"); without this the pulled ids
    // appeared one restart late. Mirrors the LiveHarshEventBus idiom.
    final sub = SyncEvents.instance
        .forTable(SyncTables.favorites)
        .listen((_) => _reload());
    ref.onDispose(sub.cancel);
    // Merge fuel + EV favorite IDs into a single unified list.
    return [...storage.getFavoriteIds(), ...storage.getEvFavoriteIds()];
  }

  /// Reload state from storage (call after any mutation).
  void _reload() {
    final storage = ref.read(storageRepositoryProvider);
    state = [...storage.getFavoriteIds(), ...storage.getEvFavoriteIds()];
    // Push the new favorite set to the Android home-screen widget
    // right away (#712). Previously the widget only updated on the
    // hourly background task, so users who installed the app and added
    // favorites saw an empty widget until the first background run.
    _refreshWidget(storage);
  }

  /// Fire-and-forget: tells [HomeWidgetService] to rebuild both the
  /// favorites and nearest widgets from the current Hive state.
  ///
  /// The nearest widget now queries the real station search (#609) —
  /// reading the active country's [StationService] from Riverpod so it
  /// works for users with zero favorites. When the station service
  /// isn't configured yet (unit tests, pre-API-key cold start) the
  /// nearest update degrades to the legacy favorites-distance path.
  void _refreshWidget(StorageRepository storage) {
    unawaited(() async {
      try {
        // Wire the price predictor for the predictive variant (#1121).
        // The widget config decides whether to render predictive nudges;
        // we always attach the data so the user's choice doesn't need a
        // second refresh round-trip.
        predictor(String stationId, FuelType fuel) =>
            ref.read(pricePredictionProvider(stationId, fuel));
        await HomeWidgetService.updateWidget(
          storage,
          profileStorage: storage,
          settingsStorage: storage,
          pricePredictor: predictor,
        );
        // Resolve the station service lazily + defensively — some test
        // harnesses don't wire stationServiceProvider, and the nearest
        // widget should still render (degraded) in that case.
        StationService? stationService;
        try {
          stationService = ref.read(stationServiceProvider);
        // #3164 — kept: expected fallback when the provider isn't
        // initialized yet; degraded path is logged via debugPrint.
        } catch (e, st) { // ignore: unused_catch_stack
          debugPrint(
            'Favorites._refreshWidget: stationService unavailable, '
            'falling back to legacy nearest update: $e',
          );
        }
        await HomeWidgetService.updateNearestWidget(
          storage,
          storage,
          profileStorage: storage,
          stationService: stationService,
          pricePredictor: predictor,
        );
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'Favorites._refreshWidget'}));
      }
    }());
  }

  /// Whether a station ID belongs to an EV charging station.
  ///
  /// OpenChargeMap IDs are prefixed with `ocm-` by EVChargingService.
  static bool _isEvId(String id) => id.startsWith('ocm-');

  /// Add a station to favorites. Detects EV stations by ID prefix and
  /// routes to the correct storage automatically.
  ///
  /// Pass [stationData] for fuel stations or [rawJson] for any station
  /// type (used by the EV detail screen which has a search/ ChargingStation).
  Future<void> add(String stationId,
      {Station? stationData, Map<String, dynamic>? rawJson}) async {
    final storage = ref.read(storageRepositoryProvider);
    final isEv = _isEvId(stationId);
    debugPrint(
        '[Favorites.add] id=$stationId isEv=$isEv rawJsonKeys=${rawJson?.keys.toList()}');

    if (isEv) {
      // Persist JSON BEFORE the id so a crash between the two writes
      // cannot leave an id without data (#690). The id is what drives
      // the reactive rebuild chain; writing it last means every observer
      // sees a consistent state.
      final json = rawJson ?? stationData?.toJson();
      if (json != null) {
        await storage.saveEvFavoriteStationData(stationId, json);
        // Verify the write actually landed. On encrypted Hive boxes
        // with deeply-nested freezed types, put() can silently drop
        // unsupported payloads. If the readback fails, bail out before
        // writing the id so we don't leave an orphan.
        final verify = storage.getEvFavoriteStationData(stationId);
        if (verify == null) {
          debugPrint(
            '[Favorites.add] CRITICAL: JSON save succeeded but readback '
            'returned null for $stationId. Hive may have dropped the '
            'payload. Skipping id write to avoid orphan.',
          );
          return;
        }
        debugPrint(
          '[Favorites.add] JSON verified for $stationId '
          '(${verify.keys.length} keys)',
        );
      } else {
        debugPrint(
            '[Favorites.add] WARNING: EV favorite added WITHOUT station JSON');
      }
      await storage.addEvFavorite(stationId);
      debugPrint(
          '[Favorites.add] EV storage now has ids=${storage.getEvFavoriteIds()}');
      // #3452 — EV favorites sync too: upload the new id + payload.
      // Emit local state first (mirrors the #2114 fuel-path ordering).
      _reload();
      await SyncHelper.syncIfEnabled(
        ref,
        'Favorites.addEv',
        () => FavoritesSync.merge(FavoritesSync.localRecords(storage)),
      );
      debugPrint('[Favorites.add] state after reload=$state');
      return;
    } else {
      await storage.addFavorite(stationId);
      final json = rawJson ?? stationData?.toJson();
      if (json != null) {
        await storage.saveFavoriteStationData(stationId, json);
      }
      // #2114 — emit the new local state BEFORE awaiting the sync
      // round-trip. Without this, the star icon on the search-results
      // card stays empty while `FavoritesSync.merge` blocks on
      // Supabase (often > 1 s on flaky networks), and users perceive
      // the tap as a no-op until the next search redraws the row.
      _reload();
      // #3452 — the merge now carries full records (fuel + EV ids WITH
      // their station payloads), so the just-added favorite reaches other
      // devices renderable, not as a bare id.
      await SyncHelper.syncIfEnabled(
        ref,
        'Favorites.add',
        () => FavoritesSync.merge(FavoritesSync.localRecords(storage)),
      );
      // No second _reload() here — fuel-station sync never mutates local
      // storage, so a second call would only trigger extra widget IO with
      // no state change (#2314).
      debugPrint('[Favorites.add] state after reload=$state');
    }
  }

  /// Add an EV charging station to favorites (explicit ev/ entity).
  Future<void> addEv(String stationId,
      {search_ev.ChargingStation? stationData}) async {
    final storage = ref.read(storageRepositoryProvider);
    await storage.addEvFavorite(stationId);

    if (stationData != null) {
      await storage.saveEvFavoriteStationData(stationId, stationData.toJson());
    }

    _reload();
    // #3452 — EV favorites sync: upload the new id + payload.
    await SyncHelper.syncIfEnabled(
      ref,
      'Favorites.addEv',
      () => FavoritesSync.merge(FavoritesSync.localRecords(storage)),
    );
  }

  /// Remove a station from favorites (checks both fuel and EV storage).
  Future<void> remove(String stationId) async {
    final storage = ref.read(storageRepositoryProvider);

    // Try fuel storage
    if (storage.isFavorite(stationId)) {
      await storage.removeFavorite(stationId);
      await storage.removeFavoriteStationData(stationId);

      try {
        await ref.read(stationRatingsProvider.notifier).remove(stationId);
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'Cleanup'}));
      }
      try {
        await storage.clearPriceHistoryForStation(stationId);
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'Cleanup'}));
      }

      await SyncHelper.fireAndForget(
        ref,
        'Favorites.remove',
        () => FavoritesSync.delete(stationId),
      );
    }

    // Try EV storage
    if (storage.isEvFavorite(stationId)) {
      await storage.removeEvFavorite(stationId);
      await storage.removeEvFavoriteStationData(stationId);

      // #3452 — EV favorites sync too: tombstone + server delete so the
      // removal reaches other devices instead of resurrecting from them.
      await SyncHelper.fireAndForget(
        ref,
        'Favorites.removeEv',
        () => FavoritesSync.delete(stationId),
      );
    }

    _reload();
  }

  /// Toggle a station's favorite status. EV stations (ocm- prefix) are
  /// automatically routed to EV storage.
  ///
  /// Pass [stationData] for fuel stations or [rawJson] for any type.
  Future<void> toggle(String stationId,
      {Station? stationData, Map<String, dynamic>? rawJson}) async {
    if (state.contains(stationId)) {
      await remove(stationId);
    } else {
      await add(stationId, stationData: stationData, rawJson: rawJson);
    }
  }

  /// Toggle an EV station's favorite status.
  Future<void> toggleEv(String stationId,
      {search_ev.ChargingStation? stationData}) async {
    if (state.contains(stationId)) {
      await remove(stationId);
    } else {
      await addEv(stationId, stationData: stationData);
    }
  }
}
