// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/bulk_dataset_alert_strategy.dart';
import 'package:tankstellen/core/background/country_alert_strategy.dart';
import 'package:tankstellen/core/background/polled_alert_strategy.dart';
import 'package:tankstellen/core/background/provider_request_budget.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/services/fuel_service_policy.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/car/car_data_service.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';

import '../../fakes/fake_storage_repository.dart';

/// Android Auto v2 SLICE 1 (#2947) — the LIVE in-car Search data service.
///
/// These drive [CarDataService.resolveSearchJson] through the SAME real
/// [CountryAlertStrategy] subclasses production resolves — a real
/// [PolledAlertStrategy] for DE and a real [BulkDatasetAlertStrategy] for ES —
/// each backed by a RECORDED-real-API-shaped [StationService] fixture, NOT an
/// echo fake (per `feedback_fake_services_false_green`: an echo that returns
/// the requested fuel would hide the cross-border bulk bug — Spain sells E5,
/// not the requested E10, and `BackgroundPriceSource` returns EMPTY in bulk
/// countries, which is exactly why this path uses `searchArea`).
///
/// What they prove:
///  - DE (polled) E10 fix → priced E10 list, round-trips the `CarStation.parse`
///    JSON shape;
///  - ES (BULK) E5 fix → priced E5 list (the bulk path returns data where the
///    polled-only `BackgroundPriceSource.searchStations` would return empty);
///  - no persisted fix → `no_gps`, never throws;
///  - a degenerate `(0,0)` fix is rejected by the #2872 `isUsableCoord` guard
///    → `no_gps`;
///  - a throwing strategy → empty `[]`, never throws (the screen keeps its
///    snapshot);
///  - the snapshot cache key is written on a non-empty result.
void main() {
  /// A recorded-API-shaped bulk dataset behind [StationService]: holds the rows
  /// a real bulk primary (MITECO / MISE / …) would yield and answers
  /// `searchStations` by LOCAL geo-filter — exactly the real bulk behaviour once
  /// the whole-country dataset is in memory. Prices live on the rows; `getPrices`
  /// returns empty (the real bulk primaries do too).
  const esBulkPolicy = FuelServicePolicy(
    model: SourceModel.bulkFile,
    minInterval: Duration(minutes: 30),
    datasetTtlSoft: Duration(hours: 6),
    datasetTtlHard: Duration(hours: 24),
    searchResultTtl: Duration.zero,
    attribution: 'Test',
    license: 'Test',
    sourceUrl: 'https://example.test/',
  );

  group('DE (polled) — live E10 search round-trips the car JSON contract', () {
    test('priced E10 list from the real PolledAlertStrategy + recorded fixture',
        () async {
      final storage = FakeStorageRepository();
      // Persisted Berlin fix the nearest-widget builder reads (#2872 guard ok).
      await storage.putSetting(StorageKeys.userPositionLat, 52.52);
      await storage.putSetting(StorageKeys.userPositionLng, 13.405);
      await _seedProfile(storage, radiusKm: 8, fuel: 'e10');

      // Recorded DE rows (Tankerkönig shape: Germany prices E10).
      final deDataset = _RecordedDataset(
        ServiceSource.tankerkoenigApi,
        [
          _row('de-1', 'Aral', 52.521, 13.401, e10: 1.799, e5: 1.859,
              diesel: 1.699),
          _row('de-2', 'Shell', 52.516, 13.420, e10: 1.829, e5: 1.889,
              diesel: 1.719),
        ],
      );

      String? wroteKey;
      String? wroteValue;
      final service = CarDataService(
        strategyFactory: _polledFactory('DE', deDataset),
        writeSnapshot: (k, v) async {
          wroteKey = k;
          wroteValue = v;
        },
      );

      final json = await service.resolveSearchJson(storage, apiKey: 'k');
      final rows = (jsonDecode(json) as List).cast<Map<String, dynamic>>();

      expect(rows, hasLength(2));
      // The JSON round-trips the shape CarStation.parse (Kotlin) expects.
      for (final r in rows) {
        expect(r.keys, containsAll(<String>[
          'id', 'name', 'brand', 'lat', 'lng', 'priceText', 'fuelLabel',
          'band', 'bandColor', 'distanceKm', 'currency',
        ]));
      }
      // E10 priced (Germany sells E10) — sorted by distance.
      final byId = {for (final r in rows) r['id']: r};
      expect(byId['de-1']!['priceText'], '1.799');
      expect(byId['de-1']!['fuelLabel'], 'E10');
      expect(byId['de-2']!['priceText'], '1.829');

      // Snapshot fallback refreshed with the live JSON.
      expect(wroteKey, 'car_search_json');
      expect(wroteValue, json);
    });
  });

  group('ES (BULK) — live search returns priced data (not empty)', () {
    test('real BulkDatasetAlertStrategy + recorded E5 fixture → priced E5 list',
        () async {
      final storage = FakeStorageRepository();
      // Persisted Madrid fix.
      await storage.putSetting(StorageKeys.userPositionLat, 40.4168);
      await storage.putSetting(StorageKeys.userPositionLng, -3.7038);
      // Spain sells E5 (SP95-E5), not E10 — drive an E5 profile so the bulk
      // path returns the priced list the real in-app ES search would.
      await _seedProfile(storage, radiusKm: 6, fuel: 'e5');

      // Recorded ES rows: MITECO populates E5; the E10 field is empty (the
      // exact data-shape an echo fake would wrongly paper over).
      final esDataset = _RecordedDataset(
        ServiceSource.mitecoApi,
        [
          _row('es-1', 'Repsol', 40.4170, -3.7040, e5: 1.529, diesel: 1.419),
          _row('es-2', 'Cepsa', 40.4150, -3.7010, e5: 1.549, diesel: 1.439),
          // Far away (Barcelona) — must be geo-filtered out of a Madrid radius.
          _row('es-9', 'BP', 41.3874, 2.1686, e5: 1.999, diesel: 1.999),
        ],
      );

      final service = CarDataService(
        strategyFactory: _bulkFactory('ES', esDataset, esBulkPolicy),
        writeSnapshot: (_, _) async {},
      );

      final json = await service.resolveSearchJson(storage, apiKey: null);
      final rows = (jsonDecode(json) as List).cast<Map<String, dynamic>>();

      // The bulk path returns the two in-radius ES stations PRICED — a polled-
      // only source (BackgroundPriceSource.searchStations) would be empty here.
      expect(rows.map((r) => r['id']).toSet(), {'es-1', 'es-2'},
          reason: 'Barcelona is outside a 6 km Madrid radius');
      final byId = {for (final r in rows) r['id']: r};
      expect(byId['es-1']!['fuelLabel'], 'E5');
      expect(byId['es-1']!['priceText'], '1.529');
      expect(byId['es-2']!['priceText'], '1.549');
      expect(byId['es-1']!['currency'], '€');
    });
  });

  group('no persisted GPS → no_gps marker, never throws', () {
    test('absent fix returns the no_gps marker', () async {
      final storage = FakeStorageRepository();
      await _seedProfile(storage, radiusKm: 8, fuel: 'e10');
      final service = CarDataService(
        strategyFactory: _polledFactory('DE', _RecordedDataset(
          ServiceSource.tankerkoenigApi, const [])),
        writeSnapshot: (_, _) async {},
      );

      expect(await service.resolveSearchJson(storage), kNoGpsMarker);
    });

    test('a degenerate (0,0) fix is rejected by isUsableCoord → no_gps',
        () async {
      final storage = FakeStorageRepository();
      await storage.putSetting(StorageKeys.userPositionLat, 0.0);
      await storage.putSetting(StorageKeys.userPositionLng, 0.0);
      await _seedProfile(storage, radiusKm: 8, fuel: 'e10');
      final service = CarDataService(
        strategyFactory: _polledFactory('DE', _RecordedDataset(
          ServiceSource.tankerkoenigApi, const [])),
        writeSnapshot: (_, _) async {},
      );

      expect(await service.resolveSearchJson(storage), kNoGpsMarker,
          reason: '(0,0) is the unacquired-axis sentinel (#2872)');
    });

    test('getUserLocation returns no_gps when the fix is poisoned', () {
      final storage = FakeStorageRepository();
      final service = CarDataService();
      expect(service.readUserLocation(storage), {'source': kNoGpsMarker});
    });
  });

  group('never throws — a strategy fault degrades to an empty list (#2349)', () {
    test('a throwing strategy → empty [] (the screen keeps its snapshot)',
        () async {
      final storage = FakeStorageRepository();
      await storage.putSetting(StorageKeys.userPositionLat, 52.52);
      await storage.putSetting(StorageKeys.userPositionLng, 13.405);
      await _seedProfile(storage, radiusKm: 8, fuel: 'e10');

      final service = CarDataService(
        strategyFactory: _bulkFactory('DE', _ThrowingDataset(), esBulkPolicy),
        writeSnapshot: (_, _) async {},
      );

      // resolveSearchJson completes and yields an empty list, never throwing —
      // BulkDatasetAlertStrategy.searchArea spools the fault internally.
      await expectLater(service.resolveSearchJson(storage), completes);
      expect(await service.resolveSearchJson(storage), '[]');
    });

    test('getUserLocation reports the persisted fix payload', () {
      final storage = FakeStorageRepository();
      unawaited(storage.inner.putSetting(StorageKeys.userPositionLat, 48.8566));
      unawaited(storage.inner.putSetting(StorageKeys.userPositionLng, 2.3522));
      unawaited(storage.inner.putSetting(StorageKeys.userPositionSource, 'gps'));
      final loc = CarDataService().readUserLocation(storage);
      expect(loc['lat'], 48.8566);
      expect(loc['lng'], 2.3522);
      expect(loc['source'], 'gps');
    });
  });

  group('snapshot fallback — the cache key is NOT written on empty', () {
    test('an empty live result leaves the snapshot untouched', () async {
      final storage = FakeStorageRepository();
      await storage.putSetting(StorageKeys.userPositionLat, 52.52);
      await storage.putSetting(StorageKeys.userPositionLng, 13.405);
      await _seedProfile(storage, radiusKm: 8, fuel: 'e10');

      var wrote = false;
      final service = CarDataService(
        strategyFactory: _polledFactory('DE', _RecordedDataset(
          ServiceSource.tankerkoenigApi, const [])),
        writeSnapshot: (_, _) async => wrote = true,
      );

      expect(await service.resolveSearchJson(storage, apiKey: 'k'), '[]');
      expect(wrote, isFalse,
          reason: 'an empty list must not clobber the last good snapshot');
    });
  });

  // ── v2 PHASE-1 SLICE 2 (#2947) — LIVE Radar via the SAME producer ──────────

  group('Radar (DE polled) — live list round-trips + writes car_radar_json', () {
    test('priced E10 radar list from the real PolledAlertStrategy', () async {
      final storage = FakeStorageRepository();
      await storage.putSetting(StorageKeys.userPositionLat, 52.52);
      await storage.putSetting(StorageKeys.userPositionLng, 13.405);
      await _seedProfile(storage, radiusKm: 8, fuel: 'e10');

      final deDataset = _RecordedDataset(
        ServiceSource.tankerkoenigApi,
        [
          _row('de-1', 'Aral', 52.521, 13.401, e10: 1.799, e5: 1.859,
              diesel: 1.699),
          _row('de-2', 'Shell', 52.516, 13.420, e10: 1.829, e5: 1.889,
              diesel: 1.719),
        ],
      );

      String? wroteKey;
      String? wroteValue;
      final service = CarDataService(
        strategyFactory: _polledFactory('DE', deDataset),
        writeSnapshot: (k, v) async {
          wroteKey = k;
          wroteValue = v;
        },
      );

      final json = await service.resolveRadarJson(storage, apiKey: 'k');
      final rows = (jsonDecode(json) as List).cast<Map<String, dynamic>>();

      expect(rows, hasLength(2));
      final byId = {for (final r in rows) r['id']: r};
      expect(byId['de-1']!['priceText'], '1.799');
      expect(byId['de-1']!['fuelLabel'], 'E10');
      // Distance-sorted: the nearer station (de-1) comes first.
      expect(rows.first['id'], 'de-1');

      // The Radar fetch refreshes the RADAR snapshot key (not the search key).
      expect(wroteKey, 'car_radar_json');
      expect(wroteValue, json);
    });
  });

  group('Radar (ES BULK) — bulk coverage, priced E5 (not empty)', () {
    test('real BulkDatasetAlertStrategy + recorded E5 fixture → priced E5 list',
        () async {
      final storage = FakeStorageRepository();
      await storage.putSetting(StorageKeys.userPositionLat, 40.4168);
      await storage.putSetting(StorageKeys.userPositionLng, -3.7038);
      await _seedProfile(storage, radiusKm: 6, fuel: 'e5');

      final esDataset = _RecordedDataset(
        ServiceSource.mitecoApi,
        [
          _row('es-1', 'Repsol', 40.4170, -3.7040, e5: 1.529, diesel: 1.419),
          _row('es-2', 'Cepsa', 40.4150, -3.7010, e5: 1.549, diesel: 1.439),
          _row('es-9', 'BP', 41.3874, 2.1686, e5: 1.999, diesel: 1.999),
        ],
      );

      String? wroteKey;
      final service = CarDataService(
        strategyFactory: _bulkFactory('ES', esDataset, esBulkPolicy),
        writeSnapshot: (k, _) async => wroteKey = k,
      );

      final json = await service.resolveRadarJson(storage, apiKey: null);
      final rows = (jsonDecode(json) as List).cast<Map<String, dynamic>>();

      // The bulk path returns the two in-radius ES stations PRICED — a polled-
      // only source would be empty here. Barcelona is geo-filtered out.
      expect(rows.map((r) => r['id']).toSet(), {'es-1', 'es-2'},
          reason: 'Barcelona is outside a 6 km Madrid radius');
      final byId = {for (final r in rows) r['id']: r};
      expect(byId['es-1']!['fuelLabel'], 'E5');
      expect(byId['es-1']!['priceText'], '1.529');
      expect(wroteKey, 'car_radar_json');
    });
  });

  group('Radar — no_gps / fault degrade exactly like Search', () {
    test('absent fix → no_gps marker, never throws', () async {
      final storage = FakeStorageRepository();
      await _seedProfile(storage, radiusKm: 8, fuel: 'e10');
      final service = CarDataService(
        strategyFactory: _polledFactory('DE', _RecordedDataset(
          ServiceSource.tankerkoenigApi, const [])),
        writeSnapshot: (_, _) async {},
      );
      expect(await service.resolveRadarJson(storage), kNoGpsMarker);
    });

    test('a throwing strategy → empty [] (keeps the snapshot), never throws',
        () async {
      final storage = FakeStorageRepository();
      await storage.putSetting(StorageKeys.userPositionLat, 52.52);
      await storage.putSetting(StorageKeys.userPositionLng, 13.405);
      await _seedProfile(storage, radiusKm: 8, fuel: 'e10');

      var wrote = false;
      final service = CarDataService(
        strategyFactory: _bulkFactory('DE', _ThrowingDataset(), esBulkPolicy),
        writeSnapshot: (_, _) async => wrote = true,
      );

      await expectLater(service.resolveRadarJson(storage), completes);
      expect(await service.resolveRadarJson(storage), '[]');
      expect(wrote, isFalse,
          reason: 'a faulted radar must not clobber the last good snapshot');
    });
  });

  // ── v2 PHASE-1 SLICE 3 (#2947) — the address subtitle, lock-step ───────────

  group('address subtitle — present in the encoded row + survives round-trip',
      () {
    test('street + city address is encoded for each station', () async {
      final storage = FakeStorageRepository();
      await storage.putSetting(StorageKeys.userPositionLat, 52.52);
      await storage.putSetting(StorageKeys.userPositionLng, 13.405);
      await _seedProfile(storage, radiusKm: 8, fuel: 'e10');

      // A station WITH a full address + one with NO street (only city).
      final dataset = _RecordedDataset(
        ServiceSource.tankerkoenigApi,
        [
          _rowWithAddress('de-1', 'Aral', 52.521, 13.401,
              street: 'Hauptstr. 1', postCode: '10115', place: 'Berlin',
              e10: 1.799),
          _rowWithAddress('de-2', 'Shell', 52.516, 13.420,
              street: '', postCode: '10117', place: 'Berlin', e10: 1.829),
        ],
      );

      final service = CarDataService(
        strategyFactory: _polledFactory('DE', dataset),
        writeSnapshot: (_, _) async {},
      );

      final json = await service.resolveSearchJson(storage, apiKey: 'k');
      final rows = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      final byId = {for (final r in rows) r['id']: r};

      // Every row carries the address key (the Kotlin DTO reads it).
      for (final r in rows) {
        expect(r.containsKey('address'), isTrue);
      }
      // Full address: "street, postCode place".
      expect(byId['de-1']!['address'], 'Hauptstr. 1, 10115 Berlin');
      // No street → city only, no orphan comma (#2704 collapsing).
      expect(byId['de-2']!['address'], '10117 Berlin');
    });
  });
}

Station _rowWithAddress(
  String id,
  String brand,
  double lat,
  double lng, {
  required String street,
  required String postCode,
  required String place,
  double? e10,
}) =>
    Station(
      id: id,
      name: '$brand forecourt',
      brand: brand,
      street: street,
      postCode: postCode,
      place: place,
      lat: lat,
      lng: lng,
      e10: e10,
      isOpen: true,
    );

// ── recorded-fixture services + strategy factories ──────────────────────────

/// A recorded-API-shaped dataset answering [searchStations] by local geo-filter
/// over a fixed row list (the real bulk-primary behaviour once cached); used
/// behind the REAL polled / bulk strategy classes so the test drives production
/// code, not an echo fake.
class _RecordedDataset implements StationService {
  _RecordedDataset(this.source, this.stations);
  final ServiceSource source;
  final List<Station> stations;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    final matched = <Station>[];
    for (final s in stations) {
      final dist = _planarKm(params.lat, params.lng, s.lat, s.lng);
      if (dist <= params.radiusKm) matched.add(s.copyWith(dist: dist));
    }
    return ServiceResult(
      data: matched,
      source: source,
      fetchedAt: DateTime(2026),
    );
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
          List<String> ids) async =>
      ServiceResult(data: const {}, source: source, fetchedAt: DateTime(2026));

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String id) =>
      throw UnimplementedError();
}

/// A dataset whose every call throws — for the #2349 never-throws assertion.
class _ThrowingDataset implements StationService {
  @override
  Future<ServiceResult<List<Station>>> searchStations(SearchParams params,
          {CancelToken? cancelToken}) async =>
      throw const SocketException('injected fault');
  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
          List<String> ids) async =>
      throw const SocketException('injected fault');
  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String id) =>
      throw UnimplementedError();
}

/// Build the REAL [PolledAlertStrategy] for [code] backed by [dataset] via the
/// #2862 `serviceBuilder` seam — production strategy code, recorded service.
CarStrategyFactory _polledFactory(String code, _RecordedDataset dataset) {
  return (
    country, {
    required StorageRepository storage,
    required CacheStrategy cache,
    String? apiKey,
    ProviderRequestBudget? budget,
  }) =>
      PolledAlertStrategy.forCountry(
        code,
        storage: storage,
        cache: cache,
        apiKey: apiKey,
        deps: PolledAlertStrategyDeps(
          budget: budget,
          serviceBuilder: (_, {String? apiKey}) => dataset,
        ),
      );
}

/// Build the REAL [BulkDatasetAlertStrategy] for [code] backed by [dataset] via
/// its `service` override — production strategy code, recorded service.
CarStrategyFactory _bulkFactory(
    String code, StationService dataset, FuelServicePolicy policy) {
  return (
    country, {
    required StorageRepository storage,
    required CacheStrategy cache,
    String? apiKey,
    ProviderRequestBudget? budget,
  }) =>
      BulkDatasetAlertStrategy(
        countryCode: code,
        storage: storage,
        cache: cache,
        policy: policy,
        service: dataset,
        budget: budget,
      );
}

Future<void> _seedProfile(
  FakeStorageRepository storage, {
  required double radiusKm,
  required String fuel,
}) async {
  await storage.saveProfile('p1', {
    'id': 'p1',
    'name': 'Default',
    'defaultSearchRadius': radiusKm,
    'preferredFuelType': fuel,
  });
  await storage.setActiveProfileId('p1');
}

Station _row(
  String id,
  String brand,
  double lat,
  double lng, {
  double? e5,
  double? e10,
  double? diesel,
}) =>
    Station(
      id: id,
      name: '$brand forecourt',
      brand: brand,
      street: 'Main 1',
      postCode: '00000',
      place: 'Town',
      lat: lat,
      lng: lng,
      e5: e5,
      e10: e10,
      diesel: diesel,
      isOpen: true,
    );

double _planarKm(double lat1, double lng1, double lat2, double lng2) {
  const kmPerDeg = 111.0; // Fine for the small distances under test.
  final dLat = (lat2 - lat1) * kmPerDeg;
  final dLng = (lng2 - lng1) * kmPerDeg;
  return math.sqrt(dLat * dLat + dLng * dLng);
}
