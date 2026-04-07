import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/route_search/domain/entities/route_info.dart';

void main() {
  group('RouteInfo', () {
    test('stores geometry, distanceKm, durationMinutes, samplePoints', () {
      final geometry = [
        const LatLng(48.8566, 2.3522),
        const LatLng(50.1109, 8.6821),
      ];
      final samplePoints = [
        const LatLng(48.8566, 2.3522),
        const LatLng(49.5, 5.5),
        const LatLng(50.1109, 8.6821),
      ];

      final route = RouteInfo(
        geometry: geometry,
        distanceKm: 478.5,
        durationMinutes: 285.0,
        samplePoints: samplePoints,
      );

      expect(route.geometry.length, 2);
      expect(route.geometry.first.latitude, 48.8566);
      expect(route.geometry.first.longitude, 2.3522);
      expect(route.distanceKm, 478.5);
      expect(route.durationMinutes, 285.0);
      expect(route.samplePoints.length, 3);
    });

    test('equality works for identical data', () {
      const a = RouteInfo(
        geometry: [LatLng(48.0, 2.0), LatLng(50.0, 8.0)],
        distanceKm: 100.0,
        durationMinutes: 60.0,
        samplePoints: [LatLng(48.0, 2.0), LatLng(50.0, 8.0)],
      );
      const b = RouteInfo(
        geometry: [LatLng(48.0, 2.0), LatLng(50.0, 8.0)],
        distanceKm: 100.0,
        durationMinutes: 60.0,
        samplePoints: [LatLng(48.0, 2.0), LatLng(50.0, 8.0)],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when data differs', () {
      const a = RouteInfo(
        geometry: [LatLng(48.0, 2.0)],
        distanceKm: 100.0,
        durationMinutes: 60.0,
        samplePoints: [],
      );
      const b = RouteInfo(
        geometry: [LatLng(48.0, 2.0)],
        distanceKm: 200.0,
        durationMinutes: 60.0,
        samplePoints: [],
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('RouteWaypoint', () {
    test('stores lat, lng, label', () {
      const wp = RouteWaypoint(lat: 48.8566, lng: 2.3522, label: 'Paris');

      expect(wp.lat, 48.8566);
      expect(wp.lng, 2.3522);
      expect(wp.label, 'Paris');
    });

    test('equality works', () {
      const a = RouteWaypoint(lat: 48.8, lng: 2.3, label: 'Paris');
      const b = RouteWaypoint(lat: 48.8, lng: 2.3, label: 'Paris');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when data differs', () {
      const a = RouteWaypoint(lat: 48.8, lng: 2.3, label: 'Paris');
      const b = RouteWaypoint(lat: 50.1, lng: 8.7, label: 'Frankfurt');

      expect(a, isNot(equals(b)));
    });
  });
}
