// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3196 (PT) — extended DGEG fuel-id coverage + DataAtualizacao mapping,
// driven by a RECORDED REAL PesquisarPostos slice
// (test/fixtures/pt_dgeg_postos_slice.json, captured 2026-06-10 with the
// extended id set; stations 93086 Odivelas and 94406 V.N. de Famalicão).
//
// The service used to query only `3201,2101` (95 simples + gasóleo simples),
// so the 98/GPL merge branches never received rows and `DataAtualizacao`
// was dropped. The recorded payload also pins the 'Gasolina especial 95'
// hazard: the live feed lists it right after 'Gasolina simples 95' for the
// same station, and a last-wins merge would stamp the premium price into
// the regular slot.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/features/station_services/portugal/portugal_station_service.dart';
import '../../../helpers/silence_error_logger.dart';

/// Serves [body] for every request and records the request URIs.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body);
  final String body;
  final List<Uri> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options.uri);
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  silenceErrorLoggerSpool();
  late String fixture;

  setUpAll(() {
    fixture =
        File('test/fixtures/pt_dgeg_postos_slice.json').readAsStringSync();
  });

  ({PortugalStationService service, _RecordingAdapter adapter}) build() {
    final adapter = _RecordingAdapter(fixture);
    final dio = Dio()..httpClientAdapter = adapter;
    return (service: PortugalStationService(dio: dio), adapter: adapter);
  }

  group('PT extended DGEG fuel-id coverage (#3196)', () {
    test('queries the full known fuel-id set (98 simples/especial, '
        '95 especial, GPL Auto)', () async {
      final (:service, :adapter) = build();
      await service.searchStations(
          const SearchParams(lat: 38.79, lng: -9.21, radiusKm: 10));
      expect(adapter.calls, hasLength(1));
      expect(adapter.calls.single.queryParameters['idsTiposComb'],
          '3201,2101,3400,3405,3205,1120');
    });

    test('Gasolina 98 reaches e98 and GPL Auto reaches lpg (recorded 93086)',
        () async {
      final (:service, adapter: _) = build();
      final result = await service.searchStations(
          const SearchParams(lat: 38.79, lng: -9.21, radiusKm: 10));
      final s = result.data.singleWhere((s) => s.id == 'pt-93086');
      expect(s.e98, closeTo(1.959, 0.0001));
      expect(s.lpg, closeTo(0.949, 0.0001));
      expect(s.diesel, closeTo(1.819, 0.0001));
    });

    test(
        "'Gasolina especial 95' listed AFTER simples must not overwrite the "
        'regular 95 price (recorded 93086 ordering)', () async {
      final (:service, adapter: _) = build();
      final result = await service.searchStations(
          const SearchParams(lat: 38.79, lng: -9.21, radiusKm: 10));
      final s = result.data.singleWhere((s) => s.id == 'pt-93086');
      expect(s.e5, closeTo(1.839, 0.0001),
          reason: 'simples 95 is 1,839 €; the especial row (1,869 €) follows '
              'it in the recorded feed and must not win the regular slot');
    });

    test(
        "'Gasolina especial 95' listed BEFORE simples also loses to the "
        'plain row (recorded 94406 ordering)', () async {
      final (:service, adapter: _) = build();
      final result = await service.searchStations(
          const SearchParams(lat: 41.43, lng: -8.43, radiusKm: 10));
      final s = result.data.singleWhere((s) => s.id == 'pt-94406');
      expect(s.e5, closeTo(1.954, 0.0001));
      expect(s.e98, closeTo(2.054, 0.0001));
    });

    test('DataAtualizacao maps to Station.updatedAt (dd/MM HH:mm)', () async {
      final (:service, adapter: _) = build();
      final result = await service.searchStations(
          const SearchParams(lat: 38.79, lng: -9.21, radiusKm: 10));
      final s = result.data.singleWhere((s) => s.id == 'pt-93086');
      expect(s.updatedAt, '08/06 13:15');
    });
  });
}
