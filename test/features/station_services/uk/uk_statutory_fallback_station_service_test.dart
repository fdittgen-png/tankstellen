// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/station_services/uk/uk_statutory_fallback_station_service.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3190 — GB primary/fallback composition: statutory Fuel Finder PRIMARY,
/// legacy retailer fan-out demoted to fallback (fires on primary failure or
/// an empty primary result).

Station _station(String id) => Station(
      id: id,
      name: 'S $id',
      brand: 'BP',
      street: '',
      postCode: '',
      place: '',
      lat: 51.5,
      lng: -0.12,
      dist: 1.0,
    );

ServiceResult<List<Station>> _result(List<Station> stations) => ServiceResult(
      data: stations,
      source: ServiceSource.ukApi,
      fetchedAt: DateTime.now(),
    );

class _StubService implements StationService {
  _StubService({this.stations, this.error});

  final List<Station>? stations;
  final Exception? error;
  int searchCalls = 0;

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    CancelToken? cancelToken,
  }) async {
    searchCalls++;
    final e = error;
    if (e != null) throw e;
    return _result(stations ?? const []);
  }

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String stationId) =>
      throw UnimplementedError();

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
          List<String> ids) =>
      throw UnimplementedError();
}

const _params = SearchParams(lat: 51.5, lng: -0.12, radiusKm: 10);

void main() {
  silenceErrorLoggerSpool();

  group('UkStatutoryFallbackStationService (#3190)', () {
    test('a healthy statutory primary answers — the legacy fan-out is NOT '
        'touched', () async {
      final primary = _StubService(stations: [_station('uk-p1')]);
      final fallback = _StubService(stations: [_station('uk-legacy')]);
      final service = UkStatutoryFallbackStationService(
          primary: primary, fallback: fallback);

      final result = await service.searchStations(_params);

      expect(result.data.single.id, 'uk-p1');
      expect(fallback.searchCalls, 0);
    });

    test('primary failure falls back to the legacy fan-out', () async {
      final primary =
          _StubService(error: const ApiException(message: 'feed down'));
      final fallback = _StubService(stations: [_station('uk-legacy')]);
      final service = UkStatutoryFallbackStationService(
          primary: primary, fallback: fallback);

      final result = await service.searchStations(_params);

      expect(result.data.single.id, 'uk-legacy');
      expect(primary.searchCalls, 1);
    });

    test('an EMPTY primary result cross-checks the legacy fan-out', () async {
      final primary = _StubService(stations: const []);
      final fallback = _StubService(stations: [_station('uk-legacy')]);
      final service = UkStatutoryFallbackStationService(
          primary: primary, fallback: fallback);

      final result = await service.searchStations(_params);

      expect(result.data.single.id, 'uk-legacy');
      expect(fallback.searchCalls, 1);
    });

    test('empty primary + failing fallback → the honest empty stands',
        () async {
      final primary = _StubService(stations: const []);
      final fallback =
          _StubService(error: const ApiException(message: 'all feeds dead'));
      final service = UkStatutoryFallbackStationService(
          primary: primary, fallback: fallback);

      final result = await service.searchStations(_params);

      expect(result.data, isEmpty);
    });

    test('both paths failing rethrows the fallback error', () async {
      final primary =
          _StubService(error: const ApiException(message: 'feed down'));
      final fallback =
          _StubService(error: const ApiException(message: 'all feeds dead'));
      final service = UkStatutoryFallbackStationService(
          primary: primary, fallback: fallback);

      expect(
        () => service.searchStations(_params),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
