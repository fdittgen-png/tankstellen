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

  group('searchAlongRoute — balanced scoring', () {
    test('prefers nearby affordable station over distant cheapest', () async {
      // Station A: price=1.75, close to route (dist=0.5)
      // Score = 1.75 + (0.5 * 0.1) = 1.80
      final nearAffordable = makeStation(
        id: 'near_affordable',
        lat: 48.05,
        lng: 2.05,
        diesel: 1.75,
        dist: 0.5,
      );

      // Station B: price=1.73, far from route (dist=3.0)
      // Score = 1.73 + (3.0 * 0.1) = 2.03
      final farCheap = makeStation(
        id: 'far_cheap',
        lat: 48.12,
        lng: 2.12,
        diesel: 1.73,
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
            FuelStationResult(nearAffordable),
            FuelStationResult(farCheap),
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
      // With balanced scoring: near_affordable scores better (1.80 < 2.03)
      expect(results[0].id, 'near_affordable');
      expect(results[1].id, 'far_cheap');
    });

    test('still prefers much cheaper station even if slightly farther', () async {
      // Station A: price=1.90, close (dist=0.5)
      // Score = 1.90 + (0.5 * 0.1) = 1.95
      final nearExpensive = makeStation(
        id: 'near_exp',
        lat: 48.05,
        lng: 2.05,
        diesel: 1.90,
        dist: 0.5,
      );

      // Station B: price=1.65, moderate distance (dist=1.5)
      // Score = 1.65 + (1.5 * 0.1) = 1.80
      final moderateCheap = makeStation(
        id: 'mod_cheap',
        lat: 48.1,
        lng: 2.1,
        diesel: 1.65,
        dist: 1.5,
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
            FuelStationResult(nearExpensive),
            FuelStationResult(moderateCheap),
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
      // mod_cheap scores 1.80, near_exp scores 1.95
      expect(results[0].id, 'mod_cheap');
      expect(results[1].id, 'near_exp');
    });
  });

  group('computeBestStops — balanced scoring', () {
    test('uses balanced score not just price', () {
      // Two stations in same segment:
      // cheapest by price but far from route
      final cheapFar = makeStation(
        id: 'cheap_far',
        lat: 48.0,
        lng: 2.0,
        diesel: 1.60,
        dist: 5.0,
      );
      // Slightly more expensive but very close to route
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

      // cheap_far score: 1.60 + (5.0 * 0.1) = 2.10
      // affordable_near score: 1.65 + (0.2 * 0.1) = 1.67
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
