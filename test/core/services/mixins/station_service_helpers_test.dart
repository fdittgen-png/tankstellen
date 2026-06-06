// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/mixins/station_service_helpers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

class _TestHelper with StationServiceHelpers {}

void main() {
  late _TestHelper helper;

  setUp(() => helper = _TestHelper());

  group('throwApiException', () {
    test('throws ApiException from DioException with message', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        message: 'Connection timeout',
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 503,
        ),
      );
      expect(
        () => helper.throwApiException(dioError),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', contains('Connection timeout'))
            .having((e) => e.message, 'has path', contains('path: /test'))
            .having((e) => e.statusCode, 'statusCode', 503)),
      );
    });

    test('uses defaultMessage when DioException message is null', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
      );
      expect(
        () =>
            helper.throwApiException(dioError, defaultMessage: 'Custom error'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', contains('Custom error'))),
      );
    });

    test('uses "Network error" as default when no message provided', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
      );
      expect(
        () => helper.throwApiException(dioError),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', contains('Network error'))
            .having((e) => e.message, 'has path', contains('path: /test'))),
      );
    });

    test('statusCode is null when response is null', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        message: 'No connection',
      );
      expect(
        () => helper.throwApiException(dioError),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', isNull)),
      );
    });
  });

  group('sortStations', () {
    final stations = [
      _makeStation(id: 'a', dist: 5.0, e5: 1.80, e10: 1.75, diesel: 1.60),
      _makeStation(id: 'b', dist: 1.0, e5: 1.90, e10: 1.85, diesel: 1.70),
      _makeStation(id: 'c', dist: 3.0, e5: null, e10: null, diesel: 1.50),
    ];

    test('sorts by distance when sortBy is distance', () {
      final list = List<Station>.from(stations);
      helper.sortStations(
          list,
          const SearchParams(
            lat: 0,
            lng: 0,
            sortBy: SortBy.distance,
          ));
      expect(list.map((s) => s.id), ['b', 'c', 'a']);
    });

    test('sorts by price when sortBy is price', () {
      final list = List<Station>.from(stations);
      helper.sortStations(
          list,
          const SearchParams(
            lat: 0,
            lng: 0,
            sortBy: SortBy.price,
            fuelType: FuelType.diesel,
          ));
      expect(list.map((s) => s.id), ['c', 'a', 'b']);
    });

    test('stations with null prices for selected fuel use fallback', () {
      final list = List<Station>.from(stations);
      helper.sortStations(
          list,
          const SearchParams(
            lat: 0,
            lng: 0,
            sortBy: SortBy.price,
            fuelType: FuelType.e10,
          ));
      // c has null e10, falls back to diesel (1.50) which is cheapest
      expect(list.first.id, 'c');
    });

    test('station with all null prices sorts to bottom (sentinel 999)', () {
      final stationsWithNull = [
        _makeStation(id: 'x', dist: 1.0, e5: 1.80, e10: 1.75, diesel: 1.60),
        _makeStation(id: 'y', dist: 2.0), // all prices null
      ];
      final list = List<Station>.from(stationsWithNull);
      helper.sortStations(
          list,
          const SearchParams(
            lat: 0,
            lng: 0,
            sortBy: SortBy.price,
            fuelType: FuelType.e10,
          ));
      expect(list.last.id, 'y');
    });
  });

  group('roundedDistance', () {
    test('returns 0.0 for same point', () {
      expect(helper.roundedDistance(48.0, 2.0, 48.0, 2.0), 0.0);
    });

    test('returns distance rounded to 1 decimal', () {
      // Paris to Versailles ~17.1 km
      final d = helper.roundedDistance(48.8566, 2.3522, 48.8048, 2.1203);
      expect(d, closeTo(17.1, 1.0));
      // Check it's rounded to 1 decimal
      expect(d.toString().split('.').last.length, lessThanOrEqualTo(1));
    });

    test('returns positive distance regardless of point order', () {
      final d1 = helper.roundedDistance(48.0, 2.0, 49.0, 3.0);
      final d2 = helper.roundedDistance(49.0, 3.0, 48.0, 2.0);
      expect(d1, d2);
      expect(d1, greaterThan(0));
    });
  });

  group('filterByRadius', () {
    final stations = [
      _makeStation(id: 'near', dist: 3.0),
      _makeStation(id: 'mid', dist: 8.0),
      _makeStation(id: 'far', dist: 15.0),
      _makeStation(id: 'very_far', dist: 30.0),
    ];

    test('returns only stations within radius', () {
      final result = helper.filterByRadius(stations, 10.0);
      expect(result.map((s) => s.id), ['near', 'mid']);
    });

    test('returns nearest fallbackCount when none in radius', () {
      final result = helper.filterByRadius(stations, 0.5, fallbackCount: 2);
      expect(result.length, 2);
      expect(result.first.id, 'near');
      expect(result.last.id, 'mid');
    });

    test('default fallbackCount is 20', () {
      final result = helper.filterByRadius(stations, 0.5);
      // All 4 stations returned since 4 < 20
      expect(result.length, 4);
    });

    test('returns empty list when input is empty', () {
      expect(helper.filterByRadius([], 10.0), isEmpty);
    });

    test('returns all stations when all within radius', () {
      final result = helper.filterByRadius(stations, 100.0);
      expect(result.length, 4);
    });

    test('includes station exactly at radius boundary', () {
      final result = helper.filterByRadius(stations, 3.0);
      expect(result.map((s) => s.id), contains('near'));
    });
  });

  group('filterByFuel (#2926 — shared hard-fuel-filter chokepoint)', () {
    // Esso sells no E85 (e85 null); Total does (0.84). The hard filter keeps
    // ONLY the station that actually sells the selected fuel.
    final esso = _makeStation(id: 'esso', e5: 1.80, e10: 1.75, diesel: 1.60);
    final total =
        _makeStation(id: 'total', e5: 1.82, e10: 1.77, diesel: 1.62, e85: 0.84);

    test('a specific fuel keeps only stations that sell it', () {
      final result =
          StationServiceHelpers.filterByFuel([esso, total], FuelType.e85);
      expect(result.map((s) => s.id), ['total'],
          reason: 'Esso has no E85 price → dropped; Total sells it → kept');
    });

    test('drops stations whose price for the fuel is zero/negative', () {
      final zero = _makeStation(id: 'zero', e10: 0.0);
      final neg = _makeStation(id: 'neg', e10: -1.0);
      final ok = _makeStation(id: 'ok', e10: 1.75);
      final result =
          StationServiceHelpers.filterByFuel([zero, neg, ok], FuelType.e10);
      expect(result.map((s) => s.id), ['ok']);
    });

    test('FuelType.all returns every station unchanged (no filter)', () {
      final input = [esso, total, _makeStation(id: 'empty')];
      final result = StationServiceHelpers.filterByFuel(input, FuelType.all);
      expect(result, same(input),
          reason: 'all wildcard short-circuits — identical list returned');
    });

    test('electric/hydrogen are not hard-filtered (route to the EV feed)', () {
      // Station has no electric/hydrogen price (the entity never models them),
      // so a hard filter would wrongly empty the list. filterByFuel must NOT
      // drop on these — they go through their own EV feed.
      final input = [esso, total];
      expect(StationServiceHelpers.filterByFuel(input, FuelType.electric),
          same(input));
      expect(StationServiceHelpers.filterByFuel(input, FuelType.hydrogen),
          same(input));
    });

    test('empty input yields empty output', () {
      expect(StationServiceHelpers.filterByFuel(const [], FuelType.diesel),
          isEmpty);
    });
  });

  group('emptyPricesResult', () {
    test('returns ServiceResult with empty map', () {
      final result = helper.emptyPricesResult(ServiceSource.denmarkApi);
      expect(result.data, isEmpty);
      expect(result.source, ServiceSource.denmarkApi);
    });

    test('sets fetchedAt to approximately now', () {
      final before = DateTime.now();
      final result = helper.emptyPricesResult(ServiceSource.mitecoApi);
      final after = DateTime.now();
      expect(result.fetchedAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(result.fetchedAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });

  group('wrapStations', () {
    test('wraps stations with metadata', () {
      final stations = [_makeStation(id: 'x')];
      final result = helper.wrapStations(stations, ServiceSource.mitecoApi);
      expect(result.data.length, 1);
      expect(result.source, ServiceSource.mitecoApi);
    });

    test('limits to 50 by default', () {
      final stations = List.generate(100, (i) => _makeStation(id: '$i'));
      final result = helper.wrapStations(stations, ServiceSource.mitecoApi);
      expect(result.data.length, 50);
    });

    test('respects custom limit', () {
      final stations = List.generate(30, (i) => _makeStation(id: '$i'));
      final result =
          helper.wrapStations(stations, ServiceSource.mitecoApi, limit: 10);
      expect(result.data.length, 10);
    });

    test('does not truncate when stations count equals limit', () {
      final stations = List.generate(50, (i) => _makeStation(id: '$i'));
      final result = helper.wrapStations(stations, ServiceSource.mitecoApi);
      expect(result.data.length, 50);
    });

    test('does not truncate when stations count is below limit', () {
      final stations = List.generate(5, (i) => _makeStation(id: '$i'));
      final result = helper.wrapStations(stations, ServiceSource.mitecoApi);
      expect(result.data.length, 5);
    });
  });

  group('throwDetailUnavailable', () {
    test('throws ApiException with API name', () {
      expect(
        () => helper.throwDetailUnavailable('Danish APIs'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', contains('Danish APIs'))),
      );
    });

    test('message contains "Detail not available"', () {
      expect(
        () => helper.throwDetailUnavailable('Test API'),
        throwsA(isA<ApiException>().having(
            (e) => e.message, 'message', contains('Detail not available'))),
      );
    });
  });
}

Station _makeStation({
  required String id,
  double dist = 0,
  double? e5,
  double? e10,
  double? diesel,
  double? e85,
}) {
  return Station(
    id: id,
    name: 'Test',
    brand: 'Test',
    street: 'St',
    postCode: '00000',
    place: 'City',
    lat: 48.0,
    lng: 2.0,
    dist: dist,
    e5: e5,
    e10: e10,
    diesel: diesel,
    e85: e85,
    isOpen: true,
  );
}
