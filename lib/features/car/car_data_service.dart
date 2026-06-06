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

/// Android Auto v2 — SLICE 1 (#2947 / epic #2946): the headless Flutter entry
/// point the native [CarDataBridge] runs to fetch a LIVE in-car Search list.
///
/// ## Why a dedicated entry point
/// The v1 car Search screen rendered a SharedPreferences snapshot written by
/// the last *in-app* search (`CarStationWriter`) — stale, and empty for a
/// driver who never opened the phone app. Slice 1 replaces the SEARCH data
/// source with a live, on-demand fetch: the native `CarAppService`/Session
/// (a BOUND service — never a started/foreground service, preserving the
/// #1498 FGS-avoidance) spins up a cached headless [FlutterEngine] and runs
/// [carDataMain] through it, then asks this side, over the
/// `tankstellen/car_data` [MethodChannel], for the freshest nearby stations.
///
/// The Radar screen STAYS on the v1 snapshot in this slice (Radar = slice 2).
///
/// ## Persisted-fix GPS only (never a live lock)
/// The contract (#2947) is the persisted last-known fix, exactly as the
/// nearest-widget builder reads it — `StorageKeys.userPositionLat/Lng` with
/// the #2872 [isUsableCoord] guard. There is no live GPS in the car process
/// in slice 1 (that, plus the `requestPermissions` flow, is a later phase),
/// so this never blocks on a fix; an absent/poisoned fix returns the
/// [kNoGpsMarker] and the screen keeps its snapshot / empty-state.
///
/// ## Live fetch path — bulk-country-correct
/// The fetch goes through [CountryAlertStrategy.searchArea], which resolves
/// the right strategy per `FuelServicePolicy.model`: a [PolledAlertStrategy]
/// for polled APIs (DE/AT/…) and a [BulkDatasetAlertStrategy] for bulk-file
/// countries (ES/IT/AR/DK). This is deliberate — `BackgroundPriceSource`
/// would return empty in a bulk country, and `StationService.searchStations`
/// returns the wrapped `ServiceResult`. The shared per-provider
/// [ProviderRequestBudget] is consulted (never bypassed) so the live car
/// fetch honours each free API's ToS spacing, sharing one gate with the
/// foreground + background scan.
///
/// ## Never throws
/// Every public handler completes — on any fault it returns an empty / no_gps
/// payload, never throwing into the OS-spawned engine (mirrors the background
/// scan coordinator). Hive is opened under [HiveIsolateLock] and always
/// closed in `finally`.

/// The MethodChannel name the native [CarDataBridge] and this entry point share.
// i18n-ignore: platform channel name, not user-facing text.
const String kCarDataChannel = 'tankstellen/car_data';

/// `kind` argument the native bridge passes to identify the Search fetch.
// i18n-ignore: protocol token, not user-facing text.
const String kCarKindSearch = 'search';

/// Method the bridge invokes to fetch the live Search list.
// i18n-ignore: protocol token, not user-facing text.
const String kCarMethodFetchSearch = 'fetchSearch';

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

  /// Handle [kCarMethodFetchSearch]: open Hive under the isolate lock, load the
  /// API key, run [resolveSearchJson], and ALWAYS close the boxes in `finally`.
  ///
  /// Returns the car JSON string, or [kNoGpsMarker] when no usable fix exists.
  /// Never throws — any fault returns [kNoGpsMarker] so the screen degrades to
  /// its snapshot / empty-state.
  Future<String> fetchSearch() async {
    HiveIsolateLock? lock;
    try {
      lock = await HiveIsolateLock.create();
      final acquired = await lock.acquire();
      if (!acquired) {
        debugPrint('CarDataService.fetchSearch: Hive lock busy — no_gps');
        return kNoGpsMarker;
      }
      await HiveStorage.initInIsolate();
      await HiveStorage.loadApiKey();
      final storage = HiveStorage();
      return await resolveSearchJson(storage, apiKey: storage.getApiKey())
          .timeout(_fetchTimeout, onTimeout: () => kNoGpsMarker);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'CarDataService.fetchSearch',
      }));
      return kNoGpsMarker;
    } finally {
      try {
        await HiveStorage.closeIsolateBoxes();
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
          'where': 'CarDataService.fetchSearch: close boxes',
        }));
      }
      lock?.release();
    }
  }

  /// Handle [kCarMethodGetUserLocation]: return `{lat,lng,source,updatedAtMs}`
  /// for the persisted fix, or `{source: no_gps}` when absent / poisoned.
  /// Never throws.
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
        // Best-effort close — a stray fault here is never actionable.
      }
      lock?.release();
    }
  }

  /// Pure resolution used by both the live handler and the unit tests: read
  /// the persisted fix (with the #2872 guard), resolve the active country +
  /// profile, run a LIVE radius [CountryAlertStrategy.searchArea], and encode
  /// the result with [CarStationData.encode]. Refreshes the snapshot key on a
  /// non-empty result. Returns [kNoGpsMarker] when no usable fix exists; an
  /// empty `[]` when the fix is good but the live search returned nothing or
  /// faulted (the screen keeps its snapshot). Never throws.
  @visibleForTesting
  Future<String> resolveSearchJson(
    StorageRepository storage, {
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
      // searchArea is documented never-throws, but guard the seam anyway —
      // a fault must degrade to the snapshot, never crash the engine.
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'CarDataService.resolveSearchJson: searchArea',
      }));
      return '[]';
    }

    // Some country services honour sortBy server-side, others don't — sort
    // locally too, identical to the nearest-widget builder.
    final sorted = [...stations]..sort((a, b) => a.dist.compareTo(b.dist));
    final json = CarStationData.encode(sorted, profile.fuelType);

    if (sorted.isNotEmpty) {
      // Refresh the fallback snapshot so a later engine failure still renders
      // a recent list. Best-effort — a write fault never fails the fetch.
      try {
        await _writeSnapshot(CarStationData.searchKey, json);
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: const {
          'where': 'CarDataService.resolveSearchJson: snapshot write',
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
