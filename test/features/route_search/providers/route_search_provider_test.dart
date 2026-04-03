import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/route_search/providers/route_search_provider.dart';
import 'package:tankstellen/features/route_search/domain/route_search_strategy.dart';
import 'package:tankstellen/features/route_search/data/strategies/uniform_search_strategy.dart';
import 'package:tankstellen/features/route_search/data/strategies/cheapest_search_strategy.dart';
import 'package:tankstellen/features/route_search/data/strategies/balanced_search_strategy.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('strategyFor', () {
    test('returns UniformSearchStrategy for uniform type', () {
      final strategy = strategyFor(RouteSearchStrategyType.uniform);
      expect(strategy, isA<UniformSearchStrategy>());
    });

    test('returns CheapestSearchStrategy for cheapest type', () {
      final strategy = strategyFor(RouteSearchStrategyType.cheapest);
      expect(strategy, isA<CheapestSearchStrategy>());
    });

    test('returns BalancedSearchStrategy for balanced type', () {
      final strategy = strategyFor(RouteSearchStrategyType.balanced);
      expect(strategy, isA<BalancedSearchStrategy>());
    });
  });

  group('RouteSearchStrategyType', () {
    test('has correct key values', () {
      expect(RouteSearchStrategyType.uniform.key, 'uniform');
      expect(RouteSearchStrategyType.cheapest.key, 'cheapest');
      expect(RouteSearchStrategyType.balanced.key, 'balanced');
    });

    test('has correct l10nKey values', () {
      expect(RouteSearchStrategyType.uniform.l10nKey, 'uniformSearch');
      expect(RouteSearchStrategyType.cheapest.l10nKey, 'cheapestSearch');
      expect(RouteSearchStrategyType.balanced.l10nKey, 'balancedSearch');
    });

    test('all values are present', () {
      expect(RouteSearchStrategyType.values.length, 3);
    });
  });

  group('RouteSearchResult', () {
    test('creates with required fields', () {
      final route = RouteInfo(
        geometry: [const LatLng(52.52, 13.41), const LatLng(48.14, 11.58)],
        distanceKm: 584.0,
        durationMinutes: 330.0,
        samplePoints: [const LatLng(52.52, 13.41)],
      );

      final result = RouteSearchResult(
        route: route,
        stations: [],
      );

      expect(result.route.distanceKm, 584.0);
      expect(result.stations, isEmpty);
      expect(result.cheapestId, isNull);
      expect(result.cheapestPerSegment, isNull);
      expect(result.strategyType, RouteSearchStrategyType.uniform);
    });

    test('creates with all fields', () {
      final route = RouteInfo(
        geometry: [const LatLng(52.52, 13.41)],
        distanceKm: 100.0,
        durationMinutes: 60.0,
        samplePoints: [],
      );

      final station = Station(
        id: 'st-1',
        name: 'Test Station',
        brand: 'Shell',
        street: 'Main St',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.52,
        lng: 13.41,
        isOpen: true,
        e10: 1.45,
      );

      final result = RouteSearchResult(
        route: route,
        stations: [FuelStationResult(station)],
        cheapestId: 'st-1',
        cheapestPerSegment: {0: 'st-1'},
        strategyType: RouteSearchStrategyType.cheapest,
      );

      expect(result.cheapestId, 'st-1');
      expect(result.cheapestPerSegment, {0: 'st-1'});
      expect(result.strategyType, RouteSearchStrategyType.cheapest);
      expect(result.stations.length, 1);
      expect(result.stations.first.id, 'st-1');
    });

    test('stations contain correct display info', () {
      final station = Station(
        id: 'st-1',
        name: 'Station Name',
        brand: 'Shell',
        street: 'Hauptstr. 1',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.52,
        lng: 13.41,
        dist: 3.5,
        isOpen: true,
        e10: 1.459,
      );

      final fuelResult = FuelStationResult(station);

      expect(fuelResult.displayName, 'Shell');
      expect(fuelResult.displayAddress, 'Hauptstr. 1');
      expect(fuelResult.lat, 52.52);
      expect(fuelResult.lng, 13.41);
      expect(fuelResult.dist, 3.5);
    });
  });

  group('Multi-country route search', () {
    test('uniform strategy collects stations from per-point query function', () async {
      // Simulate a cross-border route: Berlin (DE) → Paris (FR)
      final route = RouteInfo(
        geometry: [
          const LatLng(52.52, 13.41), // Berlin
          const LatLng(48.86, 2.35),  // Paris
        ],
        distanceKm: 1050.0,
        durationMinutes: 600.0,
        samplePoints: [
          const LatLng(52.52, 13.41), // DE
          const LatLng(50.94, 6.96),  // DE (Cologne)
          const LatLng(49.50, 3.50),  // FR (Picardy)
          const LatLng(48.86, 2.35),  // FR (Paris)
        ],
      );

      // Fake query function that returns different stations based on coordinates
      final queriedPoints = <LatLng>[];
      Future<List<SearchResultItem>> fakeQuery({
        required double lat,
        required double lng,
        required double radiusKm,
        required FuelType fuelType,
      }) async {
        queriedPoints.add(LatLng(lat, lng));
        // Return a station tagged with the queried lat for identification
        return [
          FuelStationResult(Station(
            id: 'st-${lat.toStringAsFixed(2)}',
            name: 'Station at $lat',
            brand: lat > 50 ? 'Shell DE' : 'Total FR',
            street: 'Test',
            postCode: '00000',
            place: 'Test',
            lat: lat,
            lng: lng,
            dist: 1.0,
            isOpen: true,
            e10: 1.50,
          )),
        ];
      }

      final strategy = UniformSearchStrategy();
      final results = await strategy.searchAlongRoute(
        route: route,
        fuelType: FuelType.e10,
        searchRadiusKm: 15.0,
        queryStations: fakeQuery,
      );

      // All 4 sample points should have been queried
      expect(queriedPoints.length, 4);

      // Results should contain stations from both "DE" and "FR" points
      final brands = results
          .whereType<FuelStationResult>()
          .map((r) => r.station.brand)
          .toSet();
      expect(brands, contains('Shell DE'));
      expect(brands, contains('Total FR'));
    });
  });
}
