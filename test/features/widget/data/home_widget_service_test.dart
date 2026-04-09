import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/widget/data/home_widget_service.dart';

void main() {
  group('HomeWidgetService', () {
    test('updateWidget static method is accessible', () {
      // HomeWidgetService.updateWidget requires platform channels (home_widget)
      // which are not available in unit tests. Verify the service class exists
      // and the static methods are callable.
      expect(HomeWidgetService.updateWidget, isNotNull);
      expect(HomeWidgetService.updateNearestWidget, isNotNull);
      expect(HomeWidgetService.init, isNotNull);
    });
  });

  group('haversineDistanceKm', () {
    test('returns 0 for identical coordinates', () {
      final distance = HomeWidgetService.haversineDistanceKm(
        48.8566, 2.3522, // Paris
        48.8566, 2.3522, // Paris
      );
      expect(distance, 0.0);
    });

    test('calculates correct distance between Paris and Berlin', () {
      // Paris (48.8566, 2.3522) to Berlin (52.5200, 13.4050) ~ 878 km
      final distance = HomeWidgetService.haversineDistanceKm(
        48.8566, 2.3522,
        52.5200, 13.4050,
      );
      // Allow 5% tolerance for the Haversine approximation
      expect(distance, closeTo(878, 44));
    });

    test('calculates correct distance between nearby points', () {
      // Two points ~1.5 km apart in a city
      final distance = HomeWidgetService.haversineDistanceKm(
        48.8566, 2.3522,
        48.8580, 2.3700,
      );
      // Should be around 1.3 km
      expect(distance, closeTo(1.3, 0.3));
    });

    test('handles antipodal points', () {
      // North pole to south pole ~ 20,015 km
      final distance = HomeWidgetService.haversineDistanceKm(
        90.0, 0.0,
        -90.0, 0.0,
      );
      expect(distance, closeTo(20015, 100));
    });

    test('handles negative longitudes correctly', () {
      // London (51.5074, -0.1278) to New York (40.7128, -74.0060) ~ 5570 km
      final distance = HomeWidgetService.haversineDistanceKm(
        51.5074, -0.1278,
        40.7128, -74.0060,
      );
      expect(distance, closeTo(5570, 100));
    });

    test('is symmetric - distance A to B equals B to A', () {
      final ab = HomeWidgetService.haversineDistanceKm(
        48.8566, 2.3522,
        52.5200, 13.4050,
      );
      final ba = HomeWidgetService.haversineDistanceKm(
        52.5200, 13.4050,
        48.8566, 2.3522,
      );
      expect(ab, ba);
    });

    test('calculates short distances accurately', () {
      // Two points ~100m apart
      final distance = HomeWidgetService.haversineDistanceKm(
        48.85660, 2.35220,
        48.85670, 2.35230,
      );
      // Should be very small, under 0.02 km
      expect(distance, lessThan(0.02));
      expect(distance, greaterThan(0.0));
    });
  });
}
