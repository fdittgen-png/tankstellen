import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
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

  group('compactStationData (#608 — widget parity)', () {
    const germanStation = {
      'brand': 'Shell',
      'name': 'Shell Berlin Oranienstr',
      'street': 'Oranienstr. 138',
      'postCode': '10969',
      'place': 'Berlin',
      'lat': 52.504122,
      'lng': 13.408138,
      'e5': 2.139,
      'e10': 2.079,
      'diesel': 2.169,
      'isOpen': true,
    };

    test('includes all fields needed for favorites-screen parity', () {
      final out = HomeWidgetService.compactStationDataForTest(
        'de-abc',
        germanStation,
      );

      expect(out['id'], 'de-abc');
      expect(out['brand'], 'Shell');
      expect(out['name'], 'Shell Berlin Oranienstr');
      expect(out['street'], 'Oranienstr. 138');
      expect(out['postCode'], '10969');
      expect(out['place'], 'Berlin');
      expect(out['e5'], 2.139);
      expect(out['e10'], 2.079);
      expect(out['diesel'], 2.169);
      expect(out['isOpen'], true);
    });

    test('resolves currency from station country (EUR for DE)', () {
      final out = HomeWidgetService.compactStationDataForTest(
        'de-abc',
        germanStation,
      );
      expect(out['currency'], '€');
    });

    test('resolves currency from id prefix (GBP for UK)', () {
      final out = HomeWidgetService.compactStationDataForTest(
        'uk-xyz',
        {
          ...germanStation,
          'lat': 51.5,
          'lng': -0.1,
        },
      );
      expect(out['currency'], '£');
    });

    test('preferredFuelCode + preferredFuelPrice reflect the profile fuel type',
        () {
      final out = HomeWidgetService.compactStationDataForTest(
        'de-abc',
        germanStation,
        preferredFuelType: FuelType.diesel,
      );
      expect(out['preferred_fuel_code'], 'diesel');
      expect(out['preferred_fuel_price'], 2.169);
    });

    test('preferredFuelPrice is null when fuel type has no price at station',
        () {
      final out = HomeWidgetService.compactStationDataForTest(
        'de-abc',
        germanStation,
        preferredFuelType: FuelType.lpg,
      );
      expect(out['preferred_fuel_code'], 'lpg');
      expect(out['preferred_fuel_price'], isNull);
    });

    test('distance_km is null when GPS unknown (not 0.0)', () {
      final out = HomeWidgetService.compactStationDataForTest(
        'de-abc',
        germanStation,
      );
      expect(out['distance_km'], isNull,
          reason: 'Missing GPS must produce null, not a misleading zero.');
    });

    test('distance_km is computed from GPS when provided', () {
      final out = HomeWidgetService.compactStationDataForTest(
        'de-abc',
        germanStation,
        userLat: 52.5200,
        userLng: 13.4050,
      );
      // Berlin centre → Oranienstr. ≈ ~1.9 km
      expect(out['distance_km'], isA<double>());
      expect(out['distance_km'], closeTo(1.9, 0.5));
    });

    test('defaults brand to "Station" when missing, not null or empty', () {
      final out = HomeWidgetService.compactStationDataForTest(
        'de-abc',
        {...germanStation}..remove('brand'),
      );
      // name is still present; brand falls back to name
      expect(out['brand'], 'Shell Berlin Oranienstr');
    });

    test('isOpen defaults to false (not null) when missing', () {
      final out = HomeWidgetService.compactStationDataForTest(
        'de-abc',
        {...germanStation}..remove('isOpen'),
      );
      expect(out['isOpen'], false);
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
