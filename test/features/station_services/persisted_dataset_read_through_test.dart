// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/services/persistent_dataset.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/features/station_services/argentina/argentina_station_service.dart';

/// #2264 concern 3 — bulk datasets persist to Hive under a keepAlive provider
/// and read-through on construction, so they survive a cold start + work
/// offline. Driven via Argentina (a CSV bulk source) against a real
/// [CacheManager] backed by an in-memory [CacheStorage].

const _csv =
    'indice_tiempo,idempresa,cuit,empresa,direccion,localidad,provincia,'
    'region,idproducto,producto,idtipohorario,tipohorario,precio,fecha_vigencia,'
    'idempresabandera,empresabandera,latitud,longitud,geojson\n'
    '2026-01-01,1,1,YPF SA,Av Siempreviva 100,Buenos Aires,Buenos Aires,'
    'Centro,2,Nafta (súper) entre 92 y 95 Ron,1,Diurno,1200.5,2026-01-01,'
    '1,YPF,-34.6037,-58.3816,{}';

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

/// Counts how many times the network adapter is hit, optionally failing.
class _CountingAdapter implements HttpClientAdapter {
  _CountingAdapter(this.body, {this.failAfter});
  final String body;
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
    return ResponseBody.fromBytes(utf8.encode(body), 200, headers: {
      Headers.contentTypeHeader: ['text/csv'],
    });
  }

  @override
  void close({bool force = false}) {}
}

const _params = SearchParams(lat: -34.6, lng: -58.4, radiusKm: 50.0);

ArgentinaStationService _service(CacheManager cache, HttpClientAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return ArgentinaStationService.withDio(dio, cache: cache);
}

void main() {
  group('Persisted bulk dataset read-through (#2264)', () {
    test('first search downloads and persists the dataset', () async {
      final cache = CacheManager(_MemStorage());
      final adapter = _CountingAdapter(_csv);
      final result = await _service(cache, adapter).searchStations(_params);

      expect(result.data, isNotEmpty);
      expect(adapter.calls, 1);
      // Persisted under the dataset: prefix.
      final key = PersistentDataset.datasetKey('AR', 'stations');
      expect(cache.get(key), isNotNull,
          reason: 'dataset must be persisted to the shared cache');
    });

    test('a fresh instance reads the dataset from disk without a network call',
        () async {
      final cache = CacheManager(_MemStorage());
      // Warm the cache via one instance.
      await _service(cache, _CountingAdapter(_csv)).searchStations(_params);

      // A brand-new instance (simulating a cold start / provider rebuild)
      // sharing the same persisted cache must NOT hit the network.
      final coldAdapter = _CountingAdapter(_csv);
      final cold = _service(cache, coldAdapter);
      final result = await cold.searchStations(_params);

      expect(result.data, isNotEmpty);
      expect(coldAdapter.calls, 0,
          reason: 'persisted dataset must be served from disk, no re-download');
    });

    test('serves the persisted copy when the network is offline', () async {
      final cache = CacheManager(_MemStorage());
      await _service(cache, _CountingAdapter(_csv)).searchStations(_params);

      // New instance, network always fails — must still answer from disk.
      final offline = _service(
        cache,
        _CountingAdapter(_csv, failAfter: 0),
      );
      final result = await offline.searchStations(_params);
      expect(result.data, isNotEmpty,
          reason: 'offline search must fall back to the persisted dataset');
    });

    test('with no cache wired the legacy in-memory path still works', () async {
      final adapter = _CountingAdapter(_csv);
      final dio = Dio()..httpClientAdapter = adapter;
      final service = ArgentinaStationService.withDio(dio); // no cache
      final result = await service.searchStations(_params);
      expect(result.data, isNotEmpty);
      expect(result.source, ServiceSource.argentinaApi);
    });
  });
}
