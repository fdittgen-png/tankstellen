import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/search_result_helpers.dart';

void main() {
  const berlinStation = Station(
    id: 's-1',
    name: 'Test 1',
    brand: 'TEST',
    street: 'Main 1',
    postCode: '10115',
    place: 'Berlin',
    lat: 52.52,
    lng: 13.41,
    isOpen: true,
    e10: 1.659,
  );

  const parisStation = Station(
    id: 's-2',
    name: 'Paris 1',
    brand: 'TOTAL',
    street: 'Champs',
    postCode: '75001',
    place: 'Paris',
    lat: 48.8566,
    lng: 2.3522,
    isOpen: true,
    e10: 1.759,
  );

  UserPositionData pos(double lat, double lng) => UserPositionData(
        lat: lat,
        lng: lng,
        updatedAt: DateTime(2024, 1, 1),
        source: 'GPS',
      );

  ServiceResult<List<Station>> fuelResult(
    List<Station> stations, {
    bool isStale = false,
    List<ServiceError> errors = const [],
    ServiceSource source = ServiceSource.tankerkoenigApi,
  }) {
    return ServiceResult(
      data: stations,
      source: source,
      fetchedAt: DateTime(2024, 1, 1, 12),
      isStale: isStale,
      errors: errors,
    );
  }

  group('recalcDistancesFrom', () {
    test('returns input unchanged when userPos is null', () {
      final stations = [berlinStation];
      final result = recalcDistancesFrom(stations, null);
      expect(identical(result, stations), isTrue);
    });

    test('rewrites dist from user position', () {
      // User in Paris, station in Berlin → >800 km.
      final result = recalcDistancesFrom([berlinStation], pos(48.86, 2.35));
      expect(result.first.dist, greaterThan(800));
      expect(result.first.dist, lessThan(1200));
    });

    test('rounds dist to 1 decimal place', () {
      final result = recalcDistancesFrom(
        [berlinStation],
        // Slightly offset from station
        pos(52.53, 13.42),
      );
      // Round-trip via toStringAsFixed(1) → at most 1 decimal.
      final asString = result.first.dist.toString();
      final decimals = asString.contains('.')
          ? asString.split('.').last.length
          : 0;
      expect(decimals, lessThanOrEqualTo(1));
    });

    test('handles empty list', () {
      expect(recalcDistancesFrom(const [], pos(0, 0)), isEmpty);
    });

    test('recomputes for each station independently', () {
      final result =
          recalcDistancesFrom([berlinStation, parisStation], pos(48.86, 2.35));
      // Berlin-from-Paris >> Paris-from-Paris.
      expect(result[0].dist, greaterThan(result[1].dist));
      expect(result[1].dist, lessThan(5.0));
    });
  });

  group('wrapFuelResultAsSearchItems', () {
    test('wraps each station as a FuelStationResult', () {
      final wrapped = wrapFuelResultAsSearchItems(fuelResult([berlinStation]));
      expect(wrapped.data, hasLength(1));
      expect(wrapped.data.first, isA<FuelStationResult>());
      expect(wrapped.data.first.id, 's-1');
    });

    test('preserves source, fetchedAt, isStale, errors', () {
      final err = ServiceError(
        source: ServiceSource.nativeGeocoding,
        message: 'boom',
        occurredAt: DateTime(2024, 1, 1),
      );
      final wrapped = wrapFuelResultAsSearchItems(fuelResult(
        [berlinStation],
        isStale: true,
        errors: [err],
        source: ServiceSource.cache,
      ));
      expect(wrapped.source, ServiceSource.cache);
      expect(wrapped.isStale, isTrue);
      expect(wrapped.errors, [err]);
    });

    test('returns empty list for empty input', () {
      final wrapped = wrapFuelResultAsSearchItems(fuelResult(const []));
      expect(wrapped.data, isEmpty);
    });
  });

  group('wrapEvResultAsSearchItems', () {
    test('wraps each charging station as an EVStationResult', () {
      const cs = ChargingStation(
        id: 'ev-1',
        name: 'OCM',
        latitude: 52.5,
        longitude: 13.4,
      );
      final wrapped = wrapEvResultAsSearchItems(ServiceResult(
        data: const [cs],
        source: ServiceSource.openChargeMapApi,
        fetchedAt: DateTime(2024, 1, 1),
      ));
      expect(wrapped.data, hasLength(1));
      expect(wrapped.data.first, isA<EVStationResult>());
      expect(wrapped.data.first.id, 'ev-1');
      expect(wrapped.source, ServiceSource.openChargeMapApi);
    });

    test('empty list in → empty list out', () {
      final wrapped = wrapEvResultAsSearchItems(ServiceResult(
        data: const <ChargingStation>[],
        source: ServiceSource.openChargeMapApi,
        fetchedAt: DateTime(2024, 1, 1),
      ));
      expect(wrapped.data, isEmpty);
    });
  });

  group('extractPostalCode', () {
    test('extracts 5-digit German-style zip', () {
      expect(extractPostalCode('10115 Berlin'), '10115');
    });

    test('extracts 4-digit zip', () {
      expect(extractPostalCode('1010 Vienna'), '1010');
    });

    test('returns null when no digit group matches', () {
      expect(extractPostalCode('Berlin Mitte'), isNull);
    });

    test('returns null on empty input', () {
      expect(extractPostalCode(''), isNull);
    });

    test('picks the first matching group when multiple are present', () {
      expect(extractPostalCode('34120 Pézenas 34120'), '34120');
    });

    test('ignores 3-digit or 6-digit numbers', () {
      expect(extractPostalCode('123 Short'), isNull);
      expect(extractPostalCode('123456 Too long'), isNull);
    });
  });

  group('withStations', () {
    test('replaces data, preserves all other fields', () {
      final err = ServiceError(
        source: ServiceSource.nativeGeocoding,
        message: 'x',
        occurredAt: DateTime(2024, 1, 1),
      );
      final original = fuelResult(
        [berlinStation],
        isStale: true,
        errors: [err],
        source: ServiceSource.cache,
      );

      final replaced = withStations(original, [parisStation]);

      expect(replaced.data, [parisStation]);
      expect(replaced.source, ServiceSource.cache);
      expect(replaced.fetchedAt, original.fetchedAt);
      expect(replaced.isStale, isTrue);
      expect(replaced.errors, [err]);
    });
  });

  group('mergeGeocodingIntoStationResult', () {
    test('appends geocoding errors before station errors', () {
      final geoErr = ServiceError(
        source: ServiceSource.nativeGeocoding,
        message: 'native failed',
        occurredAt: DateTime(2024, 1, 1),
      );
      final stationErr = ServiceError(
        source: ServiceSource.tankerkoenigApi,
        message: 'api failed',
        occurredAt: DateTime(2024, 1, 1),
      );

      final merged = mergeGeocodingIntoStationResult(
        stationResult: fuelResult([berlinStation], errors: [stationErr]),
        geocodingErrors: [geoErr],
        geocodingIsStale: false,
        adjustedStations: [parisStation],
      );

      expect(merged.errors, [geoErr, stationErr]);
      expect(merged.data, [parisStation]);
    });

    test('isStale is OR of station + geocoding staleness', () {
      final merged = mergeGeocodingIntoStationResult(
        stationResult: fuelResult([berlinStation], isStale: false),
        geocodingErrors: const [],
        geocodingIsStale: true,
        adjustedStations: [berlinStation],
      );
      expect(merged.isStale, isTrue);
    });

    test('isStale stays false when neither side is stale', () {
      final merged = mergeGeocodingIntoStationResult(
        stationResult: fuelResult([berlinStation], isStale: false),
        geocodingErrors: const [],
        geocodingIsStale: false,
        adjustedStations: [berlinStation],
      );
      expect(merged.isStale, isFalse);
    });

    test('source + fetchedAt come from the station result', () {
      final merged = mergeGeocodingIntoStationResult(
        stationResult: fuelResult(
          [berlinStation],
          source: ServiceSource.prixCarburantsApi,
        ),
        geocodingErrors: const [],
        geocodingIsStale: true,
        adjustedStations: [berlinStation],
      );
      expect(merged.source, ServiceSource.prixCarburantsApi);
      expect(merged.fetchedAt, DateTime(2024, 1, 1, 12));
    });
  });
}
