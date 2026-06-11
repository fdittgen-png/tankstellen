// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/bulk_dataset_alert_strategy.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/services/fuel_service_policy.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';

import '../../fakes/fake_storage_repository.dart';

/// A seeded whole-country bulk dataset behind the [StationService] interface:
/// holds a fixed list of priced stations and answers every `searchStations`
/// by LOCAL geo-filter (distance ≤ radius) over that list — exactly what the
/// real bulk primaries (MITECO / MISE / Argentina / Denmark) do once the
/// dataset is in memory. It counts network "downloads" so a test can prove the
/// strategy never re-downloads within the dataset TTL, and its `getPrices`
/// returns empty (the real bulk primaries do too — prices live on the rows).
class _SeededBulkDataset implements StationService {
  _SeededBulkDataset(this.stations);

  final List<Station> stations;

  int searchCalls = 0;
  int downloads = 0;
  int priceCalls = 0;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    // The first search loads the whole-country dataset; every later search is
    // local-only over the in-memory copy — the dataset-once contract.
    if (searchCalls == 0) downloads++;
    searchCalls++;
    final matched = <Station>[];
    for (final s in stations) {
      final dist = _planarKm(params.lat, params.lng, s.lat, s.lng);
      if (dist <= params.radiusKm) matched.add(s.copyWith(dist: dist));
    }
    return ServiceResult(
      data: matched,
      source: ServiceSource.mitecoApi,
      fetchedAt: DateTime(2026),
    );
  }

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
      List<String> ids) async {
    priceCalls++; // Bulk primaries return empty — prices live on the rows.
    return ServiceResult(
      data: const {},
      source: ServiceSource.mitecoApi,
      fetchedAt: DateTime(2026),
    );
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) =>
      throw UnimplementedError();
}

double _planarKm(double lat1, double lng1, double lat2, double lng2) {
  const kmPerDeg = 111.0; // Fine for the small distances under test.
  final dLat = (lat2 - lat1) * kmPerDeg;
  final dLng = (lng2 - lng1) * kmPerDeg;
  return math.sqrt(dLat * dLat + dLng * dLng);
}

Station _station(String id, double lat, double lng,
        {double? e5, double? diesel, bool open = true}) =>
    Station(
      id: id,
      name: id,
      brand: 'Brand',
      street: 'Street',
      postCode: '00000',
      place: 'Town',
      lat: lat,
      lng: lng,
      e5: e5,
      diesel: diesel,
      isOpen: open,
    );

/// A bulk [StationService] whose every call throws — for the #2349
/// never-throws fault-injection.
class _ThrowingBulkDataset implements StationService {
  @override
  Future<ServiceResult<List<Station>>> searchStations(SearchParams params,
          {CancelToken? cancelToken}) async =>
      throw const SocketException('injected bulk fault');
  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
          List<String> ids) async =>
      throw const SocketException('injected bulk fault');
  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) =>
      throw UnimplementedError();
}

/// A minimal ES-shaped bulk policy (soft 6 h / hard 24 h) so the strategy under
/// test has a real bulkFile policy without depending on registry constants.
const _esBulkPolicy = FuelServicePolicy(
  model: SourceModel.bulkFile,
  minInterval: Duration(minutes: 30),
  datasetTtlSoft: Duration(hours: 6),
  datasetTtlHard: Duration(hours: 24),
  searchResultTtl: Duration.zero,
  attribution: 'Test',
  license: 'Test',
  sourceUrl: 'https://example.test/',
);

void main() {
  final storage = FakeStorageRepository();
  final cache = CacheManager(storage);

  group('isBulk — branches on the registry policy.model (#2863)', () {
    test('bulk-file countries are bulk; polled / stub / unknown are not', () {
      for (final code in ['ES', 'IT', 'AR', 'DK']) {
        expect(BulkDatasetAlertStrategy.isBulk(code), isTrue,
            reason: '$code is a bulkFile policy');
      }
      for (final code in ['DE', 'AT', 'PT', 'KR', 'AU', 'ZZ']) {
        expect(BulkDatasetAlertStrategy.isBulk(code), isFalse,
            reason: '$code is not a bulkFile policy');
      }
    });
  });

  group('local geo-filter, zero per-alert network', () {
    late _SeededBulkDataset dataset;
    late BulkDatasetAlertStrategy strategy;

    // Two ES stations a few hundred metres apart near Madrid, plus one far
    // away (Barcelona) that must never match a Madrid radius search.
    final madridA = _station('es-1', 40.4168, -3.7038, e5: 1.50, diesel: 1.40);
    final madridB = _station('es-2', 40.4180, -3.7050, e5: 1.55, diesel: 1.45);
    final barcelona = _station('es-9', 41.3874, 2.1686, e5: 1.99, diesel: 1.99);

    setUp(() {
      dataset = _SeededBulkDataset([madridA, madridB, barcelona]);
      strategy = BulkDatasetAlertStrategy(
        countryCode: 'ES',
        storage: storage,
        cache: cache,
        policy: _esBulkPolicy,
        service: dataset,
        // Seed the alert station's coordinates directly (no Hive needed).
        coordsResolver: (id) => switch (id) {
          'es-1' => (lat: 40.4168, lng: -3.7038),
          'es-2' => (lat: 40.4180, lng: -3.7050),
          _ => null,
        },
      );
    });

    test('searchArea returns only stations inside the radius', () async {
      final found = await strategy.searchArea(
          const SearchParams(lat: 40.4168, lng: -3.7038, radiusKm: 5));
      expect(found.map((s) => s.id).toSet(), {'es-1', 'es-2'},
          reason: 'Barcelona is far outside a 5 km Madrid radius');
    });

    test('fetchPrices answers the alert stations + prices by local filter',
        () async {
      final prices = await strategy.fetchPrices({'es-1', 'es-2'});
      expect(prices.keys.toSet(), {'es-1', 'es-2'});
      expect(prices['es-1']!['status'], 'open');
      expect(prices['es-1']!['e5'], 1.50);
      expect(prices['es-1']!['diesel'], 1.40);
      expect(prices['es-2']!['e5'], 1.55);
    });

    test('a station id with no resolvable coordinates is skipped', () async {
      final prices = await strategy.fetchPrices({'es-1', 'es-unknown'});
      expect(prices.keys, {'es-1'},
          reason: 'es-unknown has no cached coords → skipped this scan');
    });

    test('the dataset is downloaded once — repeated alerts cost zero extra '
        'network within the TTL', () async {
      // A first search loads the dataset (downloads == 1); every later search —
      // including the two per-station probes in fetchPrices — is a local filter
      // over the SAME in-memory dataset.
      await strategy.searchArea(
          const SearchParams(lat: 40.4168, lng: -3.7038, radiusKm: 5));
      await strategy.fetchPrices({'es-1', 'es-2'});
      await strategy.searchArea(
          const SearchParams(lat: 40.4168, lng: -3.7038, radiusKm: 5));

      expect(dataset.downloads, 1,
          reason: 'whole-country dataset downloaded at most once');
      expect(dataset.priceCalls, 0,
          reason: 'bulk fetchPrices must NOT hit the per-station price '
              'endpoint — it local-filters the dataset');
      expect(dataset.searchCalls, greaterThan(1),
          reason: 'all later answers come from local filtering');
    });
  });

  group('never throws — a bulk fault is spooled, not propagated (#2349)', () {
    // The documented never-throws boundary (bulk_dataset_alert_strategy.dart):
    // a throwing dataset/service must be caught + spooled, never bubble into
    // the OS-spawned isolate.
    BulkDatasetAlertStrategy throwing() => BulkDatasetAlertStrategy(
          countryCode: 'ES',
          storage: storage,
          cache: cache,
          policy: _esBulkPolicy,
          service: _ThrowingBulkDataset(),
          coordsResolver: (id) => (lat: 40.0, lng: -3.0),
        );

    test('searchArea completes (empty) when the dataset throws', () async {
      await expectLater(
        throwing().searchArea(
            const SearchParams(lat: 40.0, lng: -3.0, radiusKm: 5)),
        completes,
      );
      expect(
        await throwing().searchArea(
            const SearchParams(lat: 40.0, lng: -3.0, radiusKm: 5)),
        isEmpty,
      );
    });

    test('fetchPrices completes (empty) when the dataset throws', () async {
      await expectLater(throwing().fetchPrices({'es-1'}), completes);
      expect(await throwing().fetchPrices({'es-1'}), isEmpty);
    });
  });
}
