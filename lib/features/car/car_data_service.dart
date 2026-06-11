// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:home_widget/home_widget.dart';

import '../../core/background/country_alert_strategy.dart';
import '../../core/background/hive_isolate_lock.dart';
import '../../core/background/provider_request_budget.dart';
import '../../core/cache/cache_manager.dart';
import '../../core/data/storage_repository.dart';
import '../../core/logging/error_logger.dart';
import '../../core/services/country_service_registry.dart';
import '../../core/storage/hive_storage.dart';
import '../../core/storage/storage_keys.dart';
import '../../core/utils/geo_utils.dart' show isUsableCoord;
import '../search/data/models/search_params.dart';
import '../search/domain/entities/fuel_type.dart';
import '../search/domain/entities/station.dart';
import '../widget/data/car_station_data.dart';

/// Android Auto v2 — PHASE-1 (#2947 / epic #2946): the headless Flutter entry
/// point the native [CarDataBridge] runs to fetch LIVE in-car Search AND Radar
/// lists.
///
/// ## Why a dedicated entry point
/// The v1 car screens rendered a stale SharedPreferences snapshot the last
/// *in-app* search / radar wrote (`CarStationWriter`) — empty for a driver who
/// never opened the phone app. Phase-1 replaces both the SEARCH (slice 1, #2987)
/// and the RADAR (slice 2) sources with a live, on-demand fetch: the native
/// `CarAppService`/Session (a BOUND service — never a started/foreground
/// service, preserving the #1498 FGS-avoidance) spins up a cached headless
/// [FlutterEngine], runs [carDataMain] through it, then asks this side over the
/// `tankstellen/car_data` [MethodChannel] for the freshest nearby stations.
/// Search and Radar share ONE live producer (same fix + country + profile
/// radius/fuel + distance sort + cap — the nearest priced stations, v1's in-app
/// radar shape); they differ ONLY in the snapshot key refreshed
/// ([CarStationData.searchKey] / [CarStationData.radarKey]).
///
/// ## Persisted-fix GPS only (never a live lock)
/// The contract (#2947) is the persisted last-known fix the nearest-widget
/// builder reads — `StorageKeys.userPositionLat/Lng` with the #2872
/// [isUsableCoord] guard. No live GPS in the car process in phase-1 (that + the
/// `requestPermissions` flow is a later phase), so this never blocks; an absent
/// / poisoned fix returns [kNoGpsMarker] and the screen keeps its snapshot.
///
/// ## Live fetch path — bulk-country-correct + never throws
/// The fetch goes through [CountryAlertStrategy.searchArea], resolving the right
/// strategy per `FuelServicePolicy.model`: a [PolledAlertStrategy] (DE/AT/…) or
/// a [BulkDatasetAlertStrategy] for bulk-file countries (ES/IT/AR/DK) —
/// deliberate, since `BackgroundPriceSource` returns empty in a bulk country.
/// The shared per-provider [ProviderRequestBudget] is consulted (never bypassed)
/// so the car fetch honours each free API's ToS spacing. Every public handler
/// completes — on any fault it returns an empty / no_gps payload, never throwing
/// into the OS-spawned engine; Hive opens under [HiveIsolateLock], closed in
/// `finally`.

/// The MethodChannel name the native [CarDataBridge] and this entry point share.
// i18n-ignore: platform channel name, not user-facing text.
const String kCarDataChannel = 'tankstellen/car_data';

/// `kind` argument the native bridge passes to identify the Search fetch.
// i18n-ignore: protocol token, not user-facing text.
const String kCarKindSearch = 'search';

/// `kind` argument the native bridge passes to identify the Radar fetch.
// i18n-ignore: protocol token, not user-facing text.
const String kCarKindRadar = 'radar';

/// Method the bridge invokes to fetch the live Search list.
// i18n-ignore: protocol token, not user-facing text.
const String kCarMethodFetchSearch = 'fetchSearch';

/// Method the bridge invokes to fetch the live Radar list (v2 phase-1 slice 2,
/// #2947) — same live producer as [kCarMethodFetchSearch], different snapshot.
// i18n-ignore: protocol token, not user-facing text.
const String kCarMethodFetchRadar = 'fetchRadar';

/// Method the bridge invokes to read the persisted user location.
// i18n-ignore: protocol token, not user-facing text.
const String kCarMethodGetUserLocation = 'getUserLocation';

/// Sentinel the entry point returns (in place of a JSON list) when there is
/// no usable persisted GPS fix — the native screen keeps its snapshot /
/// shows the `car_empty_no_gps` message rather than blanking.
// i18n-ignore: protocol sentinel, not user-facing text.
const String kNoGpsMarker = 'no_gps';

/// Hard ceiling on the live fetch's own work, independent of the native
/// bridge's own timeout. Keeps a slow provider from holding the engine open.
const Duration kCarFetchTimeout = Duration(seconds: 7);

/// Top-level headless entry point (annotated `vm:entry-point` so the native
/// engine can find it by name — model: the workmanager `callbackDispatcher`,
/// `background_service.dart`). Wires the [MethodChannel] the native
/// [CarDataBridge] talks to and delegates each call to [CarDataService].
@pragma('vm:entry-point')
void carDataMain() {
  WidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(kCarDataChannel);
  final service = CarDataService();

  channel.setMethodCallHandler((call) async {
    switch (call.method) {
      case kCarMethodFetchSearch:
        return service.fetchSearch();
      case kCarMethodFetchRadar:
        return service.fetchRadar();
      case kCarMethodGetUserLocation:
        return service.getUserLocation();
      default:
        throw MissingPluginException(
          'car_data: unknown method "${call.method}"',
        );
    }
  });
}

/// Factory for the per-country live-search strategy. Injected so a test drives
/// the SAME real [CountryAlertStrategy] subclasses production uses, backed by a
/// recorded-real-API [StationService] fixture — not an echo fake (which would
/// hide a bulk-vs-polled availability bug, per `feedback_fake_services_false_green`).
typedef CarStrategyFactory = CountryAlertStrategy? Function(
  String countryCode, {
  required StorageRepository storage,
  required CacheStrategy cache,
  String? apiKey,
  ProviderRequestBudget? budget,
});

/// The testable core behind [carDataMain]. Resolves the persisted fix →
/// active country + profile → a LIVE radius search via [CountryAlertStrategy]
/// → the shared [CarStationData] JSON the native [CarStation.parse] expects,
/// refreshing the snapshot cache key as the fallback.
class CarDataService {
  CarDataService({
    CarStrategyFactory? strategyFactory,
    Future<void> Function(String key, String value)? writeSnapshot,
    Duration fetchTimeout = kCarFetchTimeout,
  })  : _strategyFactory = strategyFactory ?? _defaultStrategyFactory,
        _writeSnapshot = writeSnapshot ?? _defaultWriteSnapshot,
        _fetchTimeout = fetchTimeout;

  final CarStrategyFactory _strategyFactory;
  final Future<void> Function(String key, String value) _writeSnapshot;
  final Duration _fetchTimeout;

  /// Default Hive-backed, snapshot-writing wiring shared by production and an
  /// integration test that wants the real isolate lifecycle. Tests that drive
  /// the pure path use [resolveSearchJson] with an in-memory storage.
  static CountryAlertStrategy? _defaultStrategyFactory(
    String countryCode, {
    required StorageRepository storage,
    required CacheStrategy cache,
    String? apiKey,
    ProviderRequestBudget? budget,
  }) =>
      CountryAlertStrategy.forCountry(
        countryCode,
        storage: storage,
        cache: cache,
        apiKey: apiKey,
        budget: budget,
      );

  /// Production snapshot write: the same `HomeWidgetPreferences` key the native
  /// [CarStation.read] consumes (Android `home_widget` always writes the fixed
  /// prefs file). Refreshing it means a later engine-failed render still has a
  /// recent fallback instead of the v1's last-in-app-search list.
  static Future<void> _defaultWriteSnapshot(String key, String value) =>
      HomeWidget.saveWidgetData(key, value);

  /// Handle [kCarMethodFetchSearch] — see [_fetch]; refreshes
  /// [CarStationData.searchKey]. Never throws.
  Future<String> fetchSearch() =>
      _fetch(CarStationData.searchKey, 'fetchSearch');

  /// Handle [kCarMethodFetchRadar] (v2 phase-1 slice 2, #2947) — the SAME live
  /// producer as [fetchSearch] (nearest priced stations within the active radius,
  /// distance-sorted + capped — the v1 in-app radar shape), refreshing
  /// [CarStationData.radarKey] instead. Never throws.
  Future<String> fetchRadar() =>
      _fetch(CarStationData.radarKey, 'fetchRadar');

  /// Shared Hive-lock + isolate-init wrapper behind [fetchSearch] / [fetchRadar]:
  /// open Hive under the isolate lock, load the API key, run [_resolveJson] for
  /// [snapshotKey] ([where] tags the error-log context), and ALWAYS close the
  /// boxes in `finally`. Never throws — any fault returns [kNoGpsMarker] so the
  /// screen degrades to its snapshot / empty-state.
  Future<String> _fetch(String snapshotKey, String where) async {
    HiveIsolateLock? lock;
    try {
      lock = await HiveIsolateLock.create();
      final acquired = await lock.acquire();
      if (!acquired) {
        debugPrint('CarDataService.$where: Hive lock busy — no_gps');
        return kNoGpsMarker;
      }
      await HiveStorage.initInIsolate();
      await HiveStorage.loadApiKey();
      final storage = HiveStorage();
      return await _resolveJson(storage, snapshotKey, apiKey: storage.getApiKey())
          .timeout(_fetchTimeout, onTimeout: () => kNoGpsMarker);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: {
        'where': 'CarDataService.$where',
      }));
      return kNoGpsMarker;
    } finally {
      try {
        await HiveStorage.closeIsolateBoxes();
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.other, e, st, context: {
          'where': 'CarDataService.$where: close boxes',
        }));
      }
      lock?.release();
    }
  }

  /// Handle [kCarMethodGetUserLocation]: `{lat,lng,source,updatedAtMs}` for the
  /// persisted fix, or `{source: no_gps}` when absent / poisoned. Never throws.
  Future<Map<String, dynamic>> getUserLocation() async {
    HiveIsolateLock? lock;
    try {
      lock = await HiveIsolateLock.create();
      if (!await lock.acquire()) return const {'source': kNoGpsMarker};
      await HiveStorage.initInIsolate();
      return readUserLocation(HiveStorage());
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'CarDataService.getUserLocation',
      }));
      return const {'source': kNoGpsMarker};
    } finally {
      try {
        await HiveStorage.closeIsolateBoxes();
      } catch (_) {
        // ignore: silent_catch — Best-effort close — a stray fault here is never actionable.
      }
      lock?.release();
    }
  }

  /// Pure resolution of the live Search JSON — see [_resolveJson]. Refreshes
  /// the [CarStationData.searchKey] snapshot on a non-empty result.
  @visibleForTesting
  Future<String> resolveSearchJson(
    StorageRepository storage, {
    String? apiKey,
  }) =>
      _resolveJson(storage, CarStationData.searchKey, apiKey: apiKey);

  /// Pure resolution of the live Radar JSON — see [_resolveJson]. Identical
  /// producer to [resolveSearchJson] (same fix + country + profile radius/fuel +
  /// distance sort, capped at [CarStationData.maxStations] — the nearest priced
  /// stations, the v1 in-app radar shape), differing ONLY in refreshing the
  /// [CarStationData.radarKey] snapshot.
  @visibleForTesting
  Future<String> resolveRadarJson(
    StorageRepository storage, {
    String? apiKey,
  }) =>
      _resolveJson(storage, CarStationData.radarKey, apiKey: apiKey);

  /// Pure resolution used by both the live handlers and the unit tests: read
  /// the persisted fix (with the #2872 guard), resolve the active country +
  /// profile, run a LIVE radius [CountryAlertStrategy.searchArea], encode with
  /// [CarStationData.encode], and refresh [snapshotKey] on a non-empty result.
  /// Returns [kNoGpsMarker] when no usable fix exists; an empty `[]` when the
  /// fix is good but the search returned nothing or faulted (the screen keeps
  /// its snapshot). Never throws.
  Future<String> _resolveJson(
    StorageRepository storage,
    String snapshotKey, {
    String? apiKey,
  }) async {
    final fix = _persistedFix(storage);
    if (fix == null) return kNoGpsMarker;

    final country = CountryServiceRegistry.countryForLatLng(fix.lat, fix.lng) ??
        (storage.getSetting('active_country_code') as String?) ??
        'DE';

    final profile = _activeProfile(storage);
    final budget = ProviderRequestBudget(storage);
    final strategy = _strategyFactory(
      country,
      storage: storage,
      cache: CacheManager(storage),
      apiKey: apiKey,
      budget: budget,
    );
    if (strategy == null) return '[]';

    List<Station> stations;
    try {
      stations = await strategy.searchArea(
        SearchParams(
          lat: fix.lat,
          lng: fix.lng,
          radiusKm: profile.radiusKm,
          fuelType: profile.fuelType,
          sortBy: SortBy.distance,
        ),
      );
    } catch (e, st) {
      // searchArea is documented never-throws; guard the seam anyway so a fault
      // degrades to the snapshot rather than crashing the engine.
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: {
        'where': 'CarDataService._resolveJson($snapshotKey): searchArea',
      }));
      return '[]';
    }

    // Sort locally too (some services honour sortBy server-side, some don't).
    final sorted = [...stations]..sort((a, b) => a.dist.compareTo(b.dist));
    final json = CarStationData.encode(sorted, profile.fuelType);

    if (sorted.isNotEmpty) {
      // Best-effort fallback-snapshot refresh (a write fault never fails fetch).
      try {
        await _writeSnapshot(snapshotKey, json);
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: {
          'where': 'CarDataService._resolveJson($snapshotKey): snapshot write',
        }));
      }
    }
    return json;
  }

  /// The `{lat,lng,source,updatedAtMs}` location payload, or `{source:no_gps}`.
  @visibleForTesting
  Map<String, dynamic> readUserLocation(StorageRepository storage) {
    final fix = _persistedFix(storage);
    if (fix == null) return const {'source': kNoGpsMarker};
    return <String, dynamic>{
      'lat': fix.lat,
      'lng': fix.lng,
      'source': (storage.getSetting(StorageKeys.userPositionSource) as String?) ??
          'persisted',
      'updatedAtMs': _updatedAtMs(storage),
    };
  }

  /// Read the persisted fix the same way the nearest-widget builder does, then
  /// apply the #2872 [isUsableCoord] guard so a `(0,0)` / one-axis / NaN fix is
  /// rejected (returns null → the caller emits [kNoGpsMarker]).
  ({double lat, double lng})? _persistedFix(StorageRepository storage) {
    final lat =
        (storage.getSetting(StorageKeys.userPositionLat) as num?)?.toDouble();
    final lng =
        (storage.getSetting(StorageKeys.userPositionLng) as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    if (!isUsableCoord(lat, lng)) return null;
    return (lat: lat, lng: lng);
  }

  int? _updatedAtMs(StorageRepository storage) {
    final raw = storage.getSetting(StorageKeys.userPositionTimestamp);
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed.millisecondsSinceEpoch;
      return int.tryParse(raw);
    }
    return null;
  }

  /// Active-profile radius + fuel, mirroring the nearest-widget builder's
  /// `_activeProfile` (default 10 km / E10 when no profile is set).
  _CarProfile _activeProfile(StorageRepository storage) {
    final id = storage.getActiveProfileId();
    if (id == null) return const _CarProfile();
    final raw = storage.getProfile(id);
    if (raw == null) return const _CarProfile();
    final radius = (raw['defaultSearchRadius'] as num?)?.toDouble() ?? 10.0;
    FuelType fuel = FuelType.e10;
    final key = raw['preferredFuelType']?.toString();
    if (key != null) {
      try {
        fuel = FuelType.fromString(key);
      // #3164 — kept: preference validation; unknown fuel key falls back.
      } catch (e, st) { // ignore: unused_catch_stack
        debugPrint('CarDataService: unknown preferred fuel "$key": $e');
      }
    }
    return _CarProfile(radiusKm: radius, fuelType: fuel);
  }
}

/// Active-profile snapshot for one car fetch.
class _CarProfile {
  final double radiusKm;
  final FuelType fuelType;
  const _CarProfile({this.radiusKm = 10.0, this.fuelType = FuelType.e10});
}
