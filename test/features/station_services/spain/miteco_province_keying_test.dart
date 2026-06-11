// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/features/station_services/spain/miteco_station_service.dart';
import 'package:tankstellen/features/station_services/spain/spain_provinces.dart';

/// #2264 concern 6 — MITECO's unkeyed `_cachedStations` served province A's
/// stations for a search in province B. The fix keys the cache by provinceId
/// and merges stations across province borders near the search point.

/// Serves a distinct station per province so the test can prove which
/// province('s) data a search returns. Counts hits per province path.
class _PerProvinceAdapter implements HttpClientAdapter {
  final Map<String, int> hits = {};

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    final path = options.uri.path;
    // Path ends with /FiltroProvincia/<id>
    final id = path.split('/').last;
    hits[id] = (hits[id] ?? 0) + 1;
    final center = spainProvinceCenters[id]!;
    final body = {
      'ResultadoConsulta': 'OK',
      'ListaEESSPrecio': [
        {
          'IDEESS': 'p$id',
          'Rótulo': 'Station-$id',
          'Dirección': 'Calle $id',
          'Localidad': 'City-$id',
          'C.P.': '00000',
          // Put the station exactly at the province centre.
          'Latitud': center.$1.toString().replaceAll('.', ','),
          'Longitud (WGS84)': center.$2.toString().replaceAll('.', ','),
          'Precio Gasolina 95 E5': '1,599',
          'Horario': '24H',
          'Margen': 'D',
        },
      ],
    };
    return ResponseBody.fromBytes(utf8.encode(jsonEncode(body)), 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

MitecoStationService _service(HttpClientAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return MitecoStationService(dio: dio);
}

void main() {
  group('spainProvincesNear (#2264)', () {
    test('a deep-interior point resolves to its single province', () {
      // Madrid centre, tiny radius → just Madrid (28).
      final ids = spainProvincesNear(40.4168, -3.7038, 1);
      expect(ids, contains('28'));
    });

    test('always includes the nearest province even with a tiny radius', () {
      final ids = spainProvincesNear(41.3851, 2.1734, 0.1); // Barcelona
      expect(ids, contains('08'));
    });

    test('a large radius spans several neighbouring provinces', () {
      final ids = spainProvincesNear(40.4168, -3.7038, 120); // Madrid + ring
      expect(ids.length, greaterThan(1));
      expect(ids, contains('28'));
    });
  });

  group('MITECO province isolation + merge (#2264)', () {
    test('a search in Barcelona does not serve Madrid-cached stations',
        () async {
      final adapter = _PerProvinceAdapter();
      final service = _service(adapter);

      // Warm the cache with a Madrid search.
      final madrid = await service.searchStations(
        const SearchParams(lat: 40.4168, lng: -3.7038, radiusKm: 5),
      );
      expect(madrid.data.map((s) => s.id), contains('es-p28'));

      // Now search Barcelona — must NOT return the Madrid station.
      final barca = await service.searchStations(
        const SearchParams(lat: 41.3851, lng: 2.1734, radiusKm: 5),
      );
      final ids = barca.data.map((s) => s.id).toList();
      expect(ids, contains('es-p08'),
          reason: 'Barcelona search must return Barcelona stations');
      expect(ids, isNot(contains('es-p28')),
          reason: 'province A must not be served for province B (#2264)');
    });

    test('merges stations across province borders near the search point',
        () async {
      final adapter = _PerProvinceAdapter();
      final service = _service(adapter);

      // A wide-radius search around Madrid pulls in several provinces; the
      // result must contain stations from more than one province id.
      final result = await service.searchStations(
        const SearchParams(lat: 40.4168, lng: -3.7038, radiusKm: 150),
      );
      final provinceIds = result.data
          .map((s) => s.id.replaceFirst('es-p', ''))
          .toSet();
      expect(provinceIds.length, greaterThan(1),
          reason: 'border merge must span multiple provinces');
    });

    test('a repeat search in the same province reuses the cached province',
        () async {
      final adapter = _PerProvinceAdapter();
      final service = _service(adapter);
      const params = SearchParams(lat: 40.4168, lng: -3.7038, radiusKm: 5);

      await service.searchStations(params);
      await service.searchStations(params);

      expect(adapter.hits['28'], 1,
          reason: 'second same-province search must hit the in-memory cache');
    });
  });
}
