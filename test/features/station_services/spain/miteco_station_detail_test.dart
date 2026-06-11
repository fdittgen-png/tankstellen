// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service_chain_codec.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/station_services/spain/miteco_station_service.dart';
import 'package:tankstellen/features/station_services/spain/spain_provinces.dart';

/// #2706 — MITECO is a BULK feed with no per-station detail endpoint, so
/// `getStationDetail` used to unconditionally throw "Detail not available".
/// That bit every out-of-search-cache tap (widget rows, deep links,
/// favorites) for ES. The fix resolves the detail from the rows a prior
/// search already cached in `_byProvince`; only a genuinely-cold cache throws.

/// Serves one richly-populated station per province so the test can assert the
/// real name + prices survive the search→cache→detail round-trip.
class _PerProvinceAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<void>? cancelFuture) async {
    final id = options.uri.path.split('/').last;
    final center = spainProvinceCenters[id]!;
    final body = {
      'ResultadoConsulta': 'OK',
      'ListaEESSPrecio': [
        {
          'IDEESS': 'p$id',
          'Rótulo': 'Repsol-$id',
          'Dirección': 'Calle $id',
          'Localidad': 'City-$id',
          'C.P.': '00000',
          'Latitud': center.$1.toString().replaceAll('.', ','),
          'Longitud (WGS84)': center.$2.toString().replaceAll('.', ','),
          'Precio Gasolina 95 E5': '1,599',
          'Precio Gasoleo A': '1,499',
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

MitecoStationService _service() {
  final dio = Dio()..httpClientAdapter = _PerProvinceAdapter();
  return MitecoStationService(dio: dio);
}

void main() {
  group('MITECO getStationDetail bulk-feed fallback (#2706)', () {
    test('resolves a detail from the warmed search cache instead of throwing',
        () async {
      final service = _service();

      // Warm `_byProvince` with a real search (Madrid = province 28).
      final search = await service.searchStations(
        const SearchParams(lat: 40.4168, lng: -3.7038, radiusKm: 5),
      );
      expect(search.data.map((s) => s.id), contains('es-p28'),
          reason: 'precondition: the bulk search must cache the station');

      // The out-of-search-cache path: ask for the detail by its `es-` id.
      final detail = await service.getStationDetail('es-p28');

      expect(detail.data, isA<StationDetail>());
      final station = detail.data.station;
      expect(station.id, 'es-p28');
      expect(station.name, 'Repsol-28',
          reason: 'the real bulk-row name must survive to the detail screen');
      expect(station.e5, 1.599);
      expect(station.diesel, 1.499);
      expect(detail.source, ServiceSource.cache);
    });

    test('an unknown / cold-cache id still throws (fallback preserved)',
        () async {
      final service = _service();
      // No prior search → cold cache → genuinely unresolvable.
      expect(
        () => service.getStationDetail('es-p99'),
        throwsA(isA<ApiException>()),
      );
    });

    test('an absent id after a warm search throws (not a wrong-station hit)',
        () async {
      final service = _service();
      await service.searchStations(
        const SearchParams(lat: 40.4168, lng: -3.7038, radiusKm: 5),
      );
      expect(
        () => service.getStationDetail('es-does-not-exist'),
        throwsA(isA<ApiException>()),
      );
    });

    test('the returned detail round-trips through the chain cache codec',
        () async {
      final service = _service();
      await service.searchStations(
        const SearchParams(lat: 40.4168, lng: -3.7038, radiusKm: 5),
      );

      final detail = await service.getStationDetail('es-p28');
      // It will now be cached under detail:es-p28, so it must survive the
      // serialize/deserialize the chain applies on write/read.
      final restored =
          deserializeStationDetail(serializeStationDetail(detail.data));

      expect(restored, isNotNull);
      expect(restored!.station.id, 'es-p28');
      expect(restored.station.name, 'Repsol-28');
      expect(restored.station.e5, 1.599);
    });
  });
}
