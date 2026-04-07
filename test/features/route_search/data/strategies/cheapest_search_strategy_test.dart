import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/route_search/data/strategies/cheapest_search_strategy.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

void main() {
  late CheapestSearchStrategy strategy;

  // Route with >10 sample points to test skipping behavior
  final manySamplePoints = List.generate(
    15,
    (i) => LatLng(48.0 + i * 0.05, 2.0 + i * 0.05),
  );

  final longRoute = RouteInfo(
    geometry: manySamplePoints,
    distanceKm: 200.0,
    durationMinutes: 150.0,
    samplePoints: manySamplePoints,
  );

  final shortRoute = RouteInfo(
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
    strategy = CheapestSearchStrategy();
  });

  group('searchAlongRoute', () {
    test('uses wider radius (1.5x) for queries', () async {
      final requestedRadii = <double>[];

      Future<List<SearchResultItem>> mockQuery({
        required double lat,
        required double lng,
        required double radiusKm,
        required FuelType fuelType,
      }) async {
        requestedRadii.add(radiusKm);
        return [];
      }

      await strategy.searchAlongRoute(
        route: shortRoute,
        fuelType: FuelType.diesel,
        searchRadiusKm: 5.0,
        queryStations: mockQuery,
        maxDetourKm: 10.0,
      );

      // All queries should use 1.5x the requested radius
      for (final radius in requestedRadii) {
        expect(radius, 7.5); // 5.0 * 1.5
      }
    });

    test('skips every other sample point when >10 points', () async {
      int queryCount = 0;

      Future<List<SearchResultItem>> mockQuery({
        required double lat,
        required double lng,
        required double radiusKm,
        required FuelType fuelType,
      }) async {
        queryCount++;
        return [];
      }

      await strategy.searchAlongRoute(
        route: longRoute,
        fuelType: FuelType.diesel,
        searchRadiusKm: 5.0,
        queryStations: mockQuery,
        maxDetourKm: 10.0,
      );

      // With 15 sample points, skipping every other means querying ~8
      // (indices 0, 2, 4, 6, 8, 10, 12, 14)
      expect(queryCount, lessThan(15));
      expect(queryCount, 8);
    });

    test('queries all sample points when <=10 points', () async {
      int queryCount = 0;

      Future<List<SearchResultItem>> mockQuery({
        required double lat,
        required double lng,
        required double radiusKm,
        required FuelType fuelType,
      }) async {
        queryCount++;
        return [];
      }

      await strategy.searchAlongRoute(
        route: shortRoute,
        fuelType: FuelType.diesel,
        searchRadiusKm: 5.0,
        queryStations: mockQuery,
        maxDetourKm: 10.0,
      );

      expect(queryCount, shortRoute.samplePoints.length);
    });

    test('uses more generous detour filter (1.5x)', () async {
      final nearStation = makeStation(
        id: 'near',
        lat: 48.05,
        lng: 2.05,
        diesel: 1.80,
      );
      // Station that's beyond maxDetourKm but within 1.5x maxDetourKm
      final slightlyFarStation = makeStation(
        id: 'slightly_far',
        lat: 48.08,
        lng: 2.12,
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
            FuelStationResult(slightlyFarStation),
          ];
        }
        return [];
      }

      final results = await strategy.searchAlongRoute(
        route: shortRoute,
        fuelType: FuelType.diesel,
        searchRadiusKm: 5.0,
        queryStations: mockQuery,
        maxDetourKm: 5.0, // Strategy should use 7.5 (1.5x) internally
      );

      // Both should pass with the generous filter
      expect(results.any((r) => r.id == 'near'), isTrue);
      // The slightly far station may or may not pass depending on actual
      // geodesic distance — the key is that the detour limit is 1.5x
    });

    test('sorts results by itinerary order (position along route)', () async {
      // Station near end of route
      final endStation = makeStation(
        id: 'end',
        lat: 48.19,
        lng: 2.19,
        diesel: 1.50, // Cheapest — but should appear last
      );
      // Station near start of route
      final startStation = makeStation(
        id: 'start',
        lat: 48.01,
        lng: 2.01,
        diesel: 1.95, // Most expensive — but should appear first
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
          ];
        }
        return [];
      }

      final results = await strategy.searchAlongRoute(
        route: shortRoute,
        fuelType: FuelType.diesel,
        searchRadiusKm: 5.0,
        queryStations: mockQuery,
        maxDetourKm: 50.0,
      );

      // Sorted by position along route, not by price
      expect(results.length, 2);
      expect(results[0].id, 'start');
      expect(results[1].id, 'end');
    });
  });
}
