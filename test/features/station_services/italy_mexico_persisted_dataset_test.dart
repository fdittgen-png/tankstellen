// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/services/persistent_dataset.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/station_services/italy/mise_station_service.dart';
import 'package:tankstellen/features/station_services/mexico/mexico_station_service.dart';

/// #2270 concern 2 — Italy (MIMIT CSV) + Mexico (CRE XML) bulk datasets now
/// carry bespoke JSON codecs and persist to Hive with a disk read-through, so
/// they survive a cold start + work offline exactly like DK/AR/ES (#2264). The
/// codec round-trip is exercised end-to-end: warm one instance, then prove a
/// fresh instance answers from the persisted copy without any network call,
/// and still answers when the network is offline. Search results are preserved.

/// In-memory CacheStorage so CacheManager works without Hive.
class _MemStorage implements CacheStorage {
  final Map<String, dynamic> _box = {};

  @override
  Future<void> cacheData(String key, dynamic data) async {
    if (data == null) {
      _box.remove(key);
    } else {
      _box[key] = data;
    }
  }

  @override
  Map<String, dynamic>? getCachedData(String key, {Duration? maxAge}) {
    final v = _box[key];
    return v is Map ? Map<String, dynamic>.from(v) : null;
  }

  @override
  Future<void> clearCache() async => _box.clear();

  @override
  int get cacheEntryCount => _box.length;

  @override
  Iterable<dynamic> get cacheKeys => _box.keys;

  @override
  Future<void> deleteCacheEntry(String key) async => _box.remove(key);
}

/// Maps request URLs to canned bodies and counts every network hit, so a test
/// can assert a cold instance served from disk (zero calls). Optionally fails
/// after [failAfter] calls to simulate going offline.
class _MapAdapter implements HttpClientAdapter {
  _MapAdapter(this.bodies, {this.failAfter});
  final Map<String, String> bodies;
  final int? failAfter;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    calls++;
    if (failAfter != null && calls > failAfter!) {
      throw DioException(
        type: DioExceptionType.connectionError,
        requestOptions: options,
        message: 'offline',
      );
    }
    final url = options.uri.toString();
    final body = bodies[url] ?? '';
    return ResponseBody.fromBytes(utf8.encode(body), 200, headers: {
      Headers.contentTypeHeader: ['text/plain'],
    });
  }

  @override
  void close({bool force = false}) {}
}

// ── Italy (MIMIT CSV) fixtures ─────────────────────────────────────────────
const _itStationsUrl =
    'https://www.mimit.gov.it/images/exportCSV/anagrafica_impianti_attivi.csv';
const _itPricesUrl =
    'https://www.mimit.gov.it/images/exportCSV/prezzo_alle_8.csv';

const _itStationsCsv = 'Data aggiornamento\n'
    'idImpianto|Gestore|Bandiera|TipoImpianto|NomeImpianto|Indirizzo|Comune|Provincia|Latitudine|Longitudine\n'
    '12345|ROSSI SRL|Eni|Stradale|Eni Rossi|Via Roma 1|Roma|RM|41.9028|12.4964';
const _itPricesCsv = 'Data aggiornamento\n'
    'idImpianto|descCarburante|prezzo|isSelf|dtComu\n'
    '12345|Benzina|1.879|1|29/03/2026 08:00:00\n'
    '12345|Gasolio|1.659|1|29/03/2026 08:00:00';

const _romaParams = SearchParams(lat: 41.9028, lng: 12.4964, radiusKm: 20);

MiseStationService _italy(CacheManager cache, HttpClientAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return MiseStationService(dio: dio, cache: cache);
}

Map<String, String> get _itBodies =>
    {_itStationsUrl: _itStationsCsv, _itPricesUrl: _itPricesCsv};

// ── Mexico (CRE XML) fixtures ──────────────────────────────────────────────
const _mxPlacesUrl = 'https://fake.cre/publicaciones/places';
const _mxPricesUrl = 'https://fake.cre/publicaciones/prices';

const _mxPlacesXml = '<?xml version="1.0" encoding="utf-8"?>\n'
    '<places>'
    '<place place_id="11702"><name>Gasolinera Centro</name>'
    '<location><x>-99.13</x><y>19.43</y></location></place>'
    '</places>';
const _mxPricesXml = '<?xml version="1.0" encoding="utf-8"?>\n'
    '<places>'
    '<place place_id="11702">'
    '<gas_price type="regular">22.95</gas_price>'
    '<gas_price type="premium">24.89</gas_price>'
    '<gas_price type="diesel">23.45</gas_price>'
    '</place>'
    '</places>';

const _cdmxParams = SearchParams(lat: 19.43, lng: -99.13, radiusKm: 10);

MexicoStationService _mexico(CacheManager cache, HttpClientAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return MexicoStationService(
    dio: dio,
    baseUrl: 'https://fake.cre/publicaciones',
    cache: cache,
  );
}

Map<String, String> get _mxBodies =>
    {_mxPlacesUrl: _mxPlacesXml, _mxPricesUrl: _mxPricesXml};

void main() {
  group('Italy MIMIT persisted dataset read-through (#2270)', () {
    test('first search downloads and persists under the dataset: key',
        () async {
      final cache = CacheManager(_MemStorage());
      final result =
          await _italy(cache, _MapAdapter(_itBodies)).searchStations(_romaParams);

      expect(result.data, isNotEmpty);
      expect(result.data.first.e5, closeTo(1.879, 0.001));
      expect(cache.get(PersistentDataset.datasetKey('IT', 'stations')),
          isNotNull,
          reason: 'IT dataset must be persisted to the shared cache');
    });

    test('codec round-trips: a cold instance reads from disk, no network call',
        () async {
      final cache = CacheManager(_MemStorage());
      await _italy(cache, _MapAdapter(_itBodies)).searchStations(_romaParams);

      final coldAdapter = _MapAdapter(_itBodies);
      final cold = _italy(cache, coldAdapter);
      final result = await cold.searchStations(_romaParams);

      expect(coldAdapter.calls, 0,
          reason: 'persisted IT dataset must be served from disk');
      // Search results preserved across the toJson/fromJson round-trip.
      expect(result.data, hasLength(1));
      final s = result.data.first;
      expect(s.name, 'Eni Rossi');
      expect(s.brand, 'Eni');
      expect(s.e5, closeTo(1.879, 0.001));
      expect(s.diesel, closeTo(1.659, 0.001));
      expect(s.updatedAt, '29/03 08:00');
    });

    test('serves the persisted copy when the network is offline', () async {
      final cache = CacheManager(_MemStorage());
      await _italy(cache, _MapAdapter(_itBodies)).searchStations(_romaParams);

      final offline = _italy(cache, _MapAdapter(_itBodies, failAfter: 0));
      final result = await offline.searchStations(_romaParams);
      expect(result.data, isNotEmpty,
          reason: 'offline search must fall back to the persisted IT dataset');
    });

    test('with no cache wired the legacy in-memory path still works', () async {
      final dio = Dio()..httpClientAdapter = _MapAdapter(_itBodies);
      final result =
          await MiseStationService(dio: dio).searchStations(_romaParams);
      expect(result.data, isNotEmpty);
    });
  });

  group('Mexico CRE persisted dataset read-through (#2270)', () {
    test('first search downloads and persists under the dataset: key',
        () async {
      final cache = CacheManager(_MemStorage());
      final result = await _mexico(cache, _MapAdapter(_mxBodies))
          .searchStations(_cdmxParams);

      expect(result.data, isNotEmpty);
      expect(result.data.first.e5, 22.95);
      expect(cache.get(PersistentDataset.datasetKey('MX', 'stations')),
          isNotNull,
          reason: 'MX dataset must be persisted to the shared cache');
    });

    test('codec round-trips: a cold instance reads from disk, no network call',
        () async {
      final cache = CacheManager(_MemStorage());
      await _mexico(cache, _MapAdapter(_mxBodies)).searchStations(_cdmxParams);

      final coldAdapter = _MapAdapter(_mxBodies);
      final cold = _mexico(cache, coldAdapter);
      final result = await cold.searchStations(_cdmxParams);

      expect(coldAdapter.calls, 0,
          reason: 'persisted MX dataset must be served from disk');
      // Search results preserved across the toJson/fromJson round-trip.
      expect(result.data, hasLength(1));
      final s = result.data.first;
      expect(s.id, 'mx-11702');
      expect(s.name, 'Gasolinera Centro');
      expect(s.e5, 22.95);
      expect(s.e10, 24.89);
      expect(s.diesel, 23.45);
    });

    test('serves the persisted copy when the network is offline', () async {
      final cache = CacheManager(_MemStorage());
      await _mexico(cache, _MapAdapter(_mxBodies)).searchStations(_cdmxParams);

      final offline = _mexico(cache, _MapAdapter(_mxBodies, failAfter: 0));
      final result = await offline.searchStations(_cdmxParams);
      expect(result.data, isNotEmpty,
          reason: 'offline search must fall back to the persisted MX dataset');
    });

    test('with no cache wired the legacy in-memory path still works', () async {
      final dio = Dio()..httpClientAdapter = _MapAdapter(_mxBodies);
      final result = await MexicoStationService(
        dio: dio,
        baseUrl: 'https://fake.cre/publicaciones',
      ).searchStations(_cdmxParams);
      expect(result.data, isNotEmpty);
    });
  });
}
