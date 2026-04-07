import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/utils/geo_utils.dart';

void main() {
  group('distanceKm', () {
    test('Berlin to Munich is approximately 504 km', () {
      // Berlin: 52.5200, 13.4050
      // Munich: 48.1351, 11.5820
      final d = distanceKm(52.5200, 13.4050, 48.1351, 11.5820);
      // Allow 10 km tolerance for Haversine vs actual road distance
      expect(d, closeTo(504, 10));
    });

    test('Paris to London is approximately 344 km', () {
      // Paris: 48.8566, 2.3522
      // London: 51.5074, -0.1278
      final d = distanceKm(48.8566, 2.3522, 51.5074, -0.1278);
      expect(d, closeTo(344, 10));
    });

    test('same point returns 0 km', () {
      final d = distanceKm(48.8566, 2.3522, 48.8566, 2.3522);
      expect(d, 0.0);
    });

    test('very close points return near-zero distance', () {
      // Two points ~100m apart
      final d = distanceKm(48.8566, 2.3522, 48.8567, 2.3523);
      expect(d, lessThan(0.05)); // less than 50m
    });

    test('zero lat/lng for first point returns 0 (null island guard)', () {
      // The implementation returns 0 if either point is (0,0)
      final d = distanceKm(0, 0, 48.1351, 11.5820);
      expect(d, 0.0);
    });

    test('zero lat/lng for second point returns 0 (null island guard)', () {
      final d = distanceKm(48.1351, 11.5820, 0, 0);
      expect(d, 0.0);
    });

    test('antipodal points return approximately 20015 km', () {
      // North pole to south pole
      final d = distanceKm(90, 0, -90, 0);
      // Half Earth circumference ~ 20015 km
      expect(d, closeTo(20015, 50));
    });

    test('cross-hemisphere distance (New York to Sydney)', () {
      // New York: 40.7128, -74.0060
      // Sydney: -33.8688, 151.2093
      final d = distanceKm(40.7128, -74.0060, -33.8688, 151.2093);
      expect(d, closeTo(15989, 50));
    });

    test('symmetry: distance A-B equals distance B-A', () {
      final ab = distanceKm(52.5200, 13.4050, 48.1351, 11.5820);
      final ba = distanceKm(48.1351, 11.5820, 52.5200, 13.4050);
      expect(ab, closeTo(ba, 0.001));
    });
  });

  group('distanceAlongPolyline', () {
    // Simple straight-line polyline: Paris (48.0, 2.0) -> (48.1, 2.1) -> (48.2, 2.2)
    final polyline = [
      const LatLng(48.0, 2.0),
      const LatLng(48.1, 2.1),
      const LatLng(48.2, 2.2),
    ];

    test('point near start returns ~0 km', () {
      final d = distanceAlongPolyline(48.01, 2.01, polyline);
      expect(d, closeTo(0, 1)); // Near the first vertex
    });

    test('point near middle returns roughly half-route distance', () {
      final d = distanceAlongPolyline(48.1, 2.1, polyline);
      // Distance from start to middle vertex
      final expected = distanceKm(48.0, 2.0, 48.1, 2.1);
      expect(d, closeTo(expected, 1));
    });

    test('point near end returns roughly full-route distance', () {
      final d = distanceAlongPolyline(48.19, 2.19, polyline);
      // Should be close to start-to-end cumulative distance
      final seg1 = distanceKm(48.0, 2.0, 48.1, 2.1);
      final seg2 = distanceKm(48.1, 2.1, 48.2, 2.2);
      expect(d, closeTo(seg1 + seg2, 2));
    });

    test('start < middle < end ordering is preserved', () {
      final dStart = distanceAlongPolyline(48.01, 2.01, polyline);
      final dMid = distanceAlongPolyline(48.1, 2.1, polyline);
      final dEnd = distanceAlongPolyline(48.19, 2.19, polyline);
      expect(dStart, lessThan(dMid));
      expect(dMid, lessThan(dEnd));
    });

    test('empty polyline returns infinity', () {
      final d = distanceAlongPolyline(48.0, 2.0, []);
      expect(d, double.infinity);
    });

    test('single-point polyline returns 0', () {
      final d = distanceAlongPolyline(48.0, 2.0, [const LatLng(48.0, 2.0)]);
      expect(d, 0.0);
    });
  });
}
