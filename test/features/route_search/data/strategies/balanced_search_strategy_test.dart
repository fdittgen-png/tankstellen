import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/route_search/data/strategies/balanced_search_strategy.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

void main() {
  late BalancedSearchStrategy strategy;

  final testRoute = RouteInfo(
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
    strategy = BalancedSearchStrategy();
  });

  group('searchAlongRoute — itinerary order', () {
    test('sorts by position along route regardless of price or distance', () async {
      // Station near end of route
      final endStation = makeStation(
        id: 'end',
        lat: 48.19,
        lng: 2.19,
        diesel: 1.50, // Cheapest, closest to route — but near end
        dist: 0.5,
      );

      // Station near start of route
      final startStation = makeStation(
        id: 'start',
        lat: 48.01,
        lng: 2.01,
        diesel: 1.95, // Most expensive — but near start
        dist: 3.0,
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
        route: testRoute,
        fuelType: FuelType.diesel,
        searchRadiusKm: 5.0,
        queryStations: mockQuery,
        maxDetourKm: 50.0,
      );

      expect(results.length, 2);
      // Sorted by position along route, not by score
      expect(results[0].id, 'start');
      expect(results[1].id, 'end');
    });

    test('three stations sorted by itinerary position', () async {
      final startStation = makeStation(
        id: 'start',
        lat: 48.01,
        lng: 2.01,
        diesel: 1.90,
        dist: 0.5,
      );

      final midStation = makeStation(
        id: 'mid',
        lat: 48.1,
        lng: 2.1,
        diesel: 1.65,
        dist: 1.5,
      );

      final endStation = makeStation(
        id: 'end',
        lat: 48.19,
        lng: 2.19,
        diesel: 1.75,
        dist: 0.5,
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
            FuelStationResult(midStation),
            FuelStationResult(endStation),
            FuelStationResult(startStation),
          ];
        }
        return [];
      }

      final results = await strategy.searchAlongRoute(
        route: testRoute,
        fuelType: FuelType.diesel,
        searchRadiusKm: 5.0,
        queryStations: mockQuery,
        maxDetourKm: 50.0,
      );

      expect(results.length, 3);
      expect(results[0].id, 'start');
      expect(results[1].id, 'mid');
      expect(results[2].id, 'end');
    });
  });

  group('computeBestStops — balanced scoring', () {
    test('uses balanced score not just price', () {
      // Two stations in same segment:
      // cheapest by price but far from route (~30km off polyline)
      final cheapFar = makeStation(
        id: 'cheap_far',
        lat: 48.0,
        lng: 2.4,
        diesel: 1.60,
        dist: 5.0,
      );
      // Slightly more expensive but on the route
      final affordableNear = makeStation(
        id: 'affordable_near',
        lat: 48.01,
        lng: 2.01,
        diesel: 1.65,
        dist: 0.2,
      );

      final results = [
        FuelStationResult(cheapFar),
        FuelStationResult(affordableNear),
      ];

      final bestStops = strategy.computeBestStops(
        route: testRoute,
        results: results,
        fuelType: FuelType.diesel,
        segmentKm: 50.0, // One big segment, both stations in same segment
      );

      // cheap_far: minDist ≈ 30km, score: 1.60 + (30 * 0.1) = 4.60
      // affordable_near: minDist ≈ 1km, score: 1.65 + (1 * 0.1) = 1.75
      // Balanced scoring should prefer affordable_near
      expect(bestStops, isNotNull);
      expect(bestStops!.values.contains('affordable_near'), isTrue);
    });

    test('returns empty list when no fuel stations', () {
      final bestStops = strategy.computeBestStops(
        route: testRoute,
        results: [],
        fuelType: FuelType.diesel,
        segmentKm: 15.0,
      );

      expect(bestStops, isNotNull);
      expect(bestStops!, isEmpty);
    });

    test('handles stations with no price gracefully', () {
      final noPrice = makeStation(
        id: 'no_price',
        lat: 48.0,
        lng: 2.0,
        dist: 1.0,
      );
      final withPrice = makeStation(
        id: 'with_price',
        lat: 48.01,
        lng: 2.01,
        diesel: 1.70,
        dist: 1.0,
      );

      final results = [
        FuelStationResult(noPrice),
        FuelStationResult(withPrice),
      ];

      final bestStops = strategy.computeBestStops(
        route: testRoute,
        results: results,
        fuelType: FuelType.diesel,
        segmentKm: 50.0,
      );

      // Should prefer the station with a price
      expect(bestStops, isNotNull);
      expect(bestStops!.values.contains('with_price'), isTrue);
    });
  });
}
