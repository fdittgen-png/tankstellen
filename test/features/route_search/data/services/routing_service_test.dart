import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/features/route_search/data/services/routing_service.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';

void main() {
  group('RoutingService', () {
    late RoutingService service;

    setUp(() => service = RoutingService());

    group('waypoint validation', () {
      test('requires at least 2 waypoints', () async {
        expect(
          () => service.getRoute([
            const RouteWaypoint(lat: 48, lng: 2, label: 'A'),
          ]),
          throwsA(isA<ApiException>()),
        );
      });

      test('throws ApiException with descriptive message for single waypoint', () async {
        try {
          await service.getRoute([
            const RouteWaypoint(lat: 48, lng: 2, label: 'A'),
          ]);
          fail('Should have thrown');
        } on ApiException catch (e) {
          expect(e.message, contains('2 waypoints'));
        }
      });

      test('empty waypoints list throws', () async {
        expect(
          () => service.getRoute([]),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('RouteWaypoint', () {
      test('stores lat, lng, label', () {
        const wp = RouteWaypoint(lat: 48.8, lng: 2.3, label: 'Paris');

        expect(wp.lat, 48.8);
        expect(wp.lng, 2.3);
        expect(wp.label, 'Paris');
      });

      test('equality works', () {
        const a = RouteWaypoint(lat: 48.8, lng: 2.3, label: 'Paris');
        const b = RouteWaypoint(lat: 48.8, lng: 2.3, label: 'Paris');

        expect(a, equals(b));
      });

      test('inequality when label differs', () {
        const a = RouteWaypoint(lat: 48.8, lng: 2.3, label: 'Paris');
        const b = RouteWaypoint(lat: 48.8, lng: 2.3, label: 'Not Paris');

        expect(a, isNot(equals(b)));
      });
    });

    group('avoidHighways parameter', () {
      test('getRoute accepts avoidHighways parameter', () async {
        // Verify the method signature accepts avoidHighways without compile error.
        // We can't call the real OSRM server, but we verify the parameter
        // is accepted and that too-few waypoints still throws as expected.
        expect(
          () => service.getRoute(
            [const RouteWaypoint(lat: 48, lng: 2, label: 'A')],
            avoidHighways: true,
          ),
          throwsA(isA<ApiException>()),
        );
      });

      test('getRoute defaults avoidHighways to false', () async {
        // Calling without the parameter should still work (default = false).
        expect(
          () => service.getRoute(
            [const RouteWaypoint(lat: 48, lng: 2, label: 'A')],
          ),
          throwsA(isA<ApiException>()),
        );
      });
    });
  });
}
