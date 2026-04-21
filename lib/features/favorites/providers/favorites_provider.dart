import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/data/storage_repository.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/sync_helper.dart';
import '../../../core/sync/sync_service.dart';
import '../../search/domain/entities/charging_station.dart' as search_ev;
import '../../search/domain/entities/station.dart';
import '../../search/providers/station_rating_provider.dart';
import '../../widget/data/home_widget_service.dart';

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
  void _refreshWidget(StorageRepository storage) {
    unawaited(() async {
      try {
        await HomeWidgetService.updateWidget(
          storage,
          profileStorage: storage,
          settingsStorage: storage,
        );
        await HomeWidgetService.updateNearestWidget(
          storage,
          storage,
          profileStorage: storage,
        );
      } catch (e) {
        debugPrint('Favorites._refreshWidget: $e');
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
    } else {
      await storage.addFavorite(stationId);
      final json = rawJson ?? stationData?.toJson();
      if (json != null) {
        await storage.saveFavoriteStationData(stationId, json);
      }
      await SyncHelper.syncIfEnabled(
        ref,
        'Favorites.add',
        () => SyncService.syncFavorites(storage.getFavoriteIds()),
      );
    }

    _reload();
    debugPrint('[Favorites.add] state after reload=$state');
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
      } catch (e) {
        debugPrint('Cleanup: $e');
      }
      try {
        await storage.clearPriceHistoryForStation(stationId);
      } catch (e) {
        debugPrint('Cleanup: $e');
      }

      await SyncHelper.fireAndForget(
        ref,
        'Favorites.remove',
        () => SyncService.deleteFavorite(stationId),
      );
    }

    // Try EV storage
    if (storage.isEvFavorite(stationId)) {
      await storage.removeEvFavorite(stationId);
      await storage.removeEvFavoriteStationData(stationId);
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
