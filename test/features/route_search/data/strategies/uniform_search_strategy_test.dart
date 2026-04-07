import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/route_search/data/strategies/uniform_search_strategy.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

void main() {
  late UniformSearchStrategy strategy;

  const testRoute = RouteInfo(
    geometry: [LatLng(48.0, 2.0), LatLng(48.1, 2.1), LatLng(48.2, 2.2)],
    distanceKm: 30.0,
    durationMinutes: 25.0,
    samplePoints: [LatLng(48.0, 2.0), LatLng(48.1, 2.1), LatLng(48.2, 2.2)],
  );

  Station makeStation({
    required String id,
    required double lat,
    required double lng,
    double? diesel,
    double? e10,
    double dist = 1.0,
  }) {
    return Station(
      id: id,
      name: 'Station $id',
      brand: 'Brand $id',
      street: 'Street $id',
      postCode: '75000',
      place: 'Paris',
      lat: lat,
      lng: lng,
      dist: dist,
      diesel: diesel,
      e10: e10,
      isOpen: true,
    );
  }

  setUp(() {
    strategy = UniformSearchStrategy();
  });

  group('searchAlongRoute', () {
    test('returns deduplicated stations', () async {
      // Same station returned from multiple sample points
      final duplicateStation = makeStation(
        id: 'dup1',
        lat: 48.05,
        lng: 2.05,
        diesel: 1.75,
      );

      Future<List<SearchResultItem>> mockQuery({
        required double lat,
        required double lng,
        required double radiusKm,
        required FuelType fuelType,
      }) async {
        return [FuelStationResult(duplicateStation)];
      }

      final results = await strategy.searchAlongRoute(
        route: testRoute,
        fuelType: FuelType.diesel,
        searchRadiusKm: 5.0,
        queryStations: mockQuery,
        maxDetourKm: 10.0,
      );

      // Should only contain one instance despite being returned 3 times
      final ids = results.map((r) => r.id).toList();
      expect(ids.where((id) => id == 'dup1').length, 1);
    });

    test('filters stations beyond detour distance', skip: 'Requires real Haversine; test in integration', () async {
      final nearStation = makeStation(
        id: 'near1',
        lat: 48.05,
        lng: 2.05,
        diesel: 1.80,
      );
      final farStation = makeStation(
        id: 'far1',
        lat: 49.5, // Far from the route
        lng: 4.0,
        diesel: 1.60,
      );

      int callCount = 0;
      Future<List<SearchResultItem>> mockQuery({
        required double lat,
        required double lng,
        required double radiusKm,
        required FuelType fuelType,
      }) async {
        callCount++;
        if (callCount == 1) {
          return [
            FuelStationResult(nearStation),
            FuelStationResult(farStation),
          ];
        }
        return [];
      }

      final results = await strategy.searchAlongRoute(
        route: testRoute,
        fuelType: FuelType.diesel,
        searchRadiusKm: 5.0,
        queryStations: mockQuery,
        maxDetourKm: 5.0,
      );

      // Far station should be filtered out
      expect(results.any((r) => r.id == 'near1'), isTrue);
      expect(results.any((r) => r.id == 'far1'), isFalse);
    });

    test('sorts results by itinerary order (position along route)', () async {
      // Station near end of route (lat 48.19 is close to geometry endpoint 48.2)
      final endStation = makeStation(
        id: 'end',
        lat: 48.19,
        lng: 2.19,
        diesel: 1.50, // Cheapest — but should appear last
      );
      // Station near start of route (lat 48.01 is close to geometry start 48.0)
      final startStation = makeStation(
        id: 'start',
        lat: 48.01,
        lng: 2.01,
        diesel: 1.95, // Most expensive — but should appear first
      );
      // Station in the middle of route
      final midStation = makeStation(
        id: 'mid',
        lat: 48.1,
        lng: 2.1,
        diesel: 1.80,
      );

      int callCount = 0;
      Future<List<SearchResultItem>> mockQuery({
        required double lat,
        required double lng,
        required double radiusKm,
        required FuelType fuelType,
      }) async {
        callCount++;
        if (callCount == 1) {
          return [
            FuelStationResult(endStation),
            FuelStationResult(startStation),
            FuelStationResult(midStation),
          ];
        }
        return [];
      }

      final results = await strategy.searchAlongRoute(
        route: testRoute,
        fuelType: FuelType.diesel,
        searchRadiusKm: 5.0,
        queryStations: mockQuery,
        maxDetourKm: 50.0, // Generous to keep all stations
      );

      expect(results.length, 3);
      // Sorted by position along route, not by price
      expect(results[0].id, 'start');
      expect(results[1].id, 'mid');
      expect(results[2].id, 'end');
    });
  });

  group('computeBestStops', () {
    test('returns cheapest station per segment', () {
      final cheapSegment0 = makeStation(
        id: 'seg0_cheap',
        lat: 48.0,
        lng: 2.0,
        diesel: 1.65,
      );
      final expensiveSegment0 = makeStation(
        id: 'seg0_exp',
        lat: 48.02,
        lng: 2.02,
        diesel: 1.90,
      );
      final cheapSegment1 = makeStation(
        id: 'seg1_cheap',
        lat: 48.2,
        lng: 2.2,
        diesel: 1.70,
      );

      final results = [
        FuelStationResult(cheapSegment0),
        FuelStationResult(expensiveSegment0),
        FuelStationResult(cheapSegment1),
      ];

      final bestStops = strategy.computeBestStops(
        route: testRoute,
        results: results,
        fuelType: FuelType.diesel,
        segmentKm: 15.0,
      );

      // Should pick the cheapest per segment
      expect(bestStops, isNotNull);
      expect(bestStops!.values.contains('seg0_cheap'), isTrue);
      expect(bestStops.values.contains('seg0_exp'), isFalse);
    });

    test('returns empty list when no fuel stations in results', () {
      final bestStops = strategy.computeBestStops(
        route: testRoute,
        results: [],
        fuelType: FuelType.diesel,
        segmentKm: 15.0,
      );

      expect(bestStops, isEmpty);
    });
  });
}
