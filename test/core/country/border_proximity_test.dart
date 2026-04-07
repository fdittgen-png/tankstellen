import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/border_proximity.dart';

void main() {
  group('detectNearbyBorders', () {
    test('returns empty list when position is far from any border', () {
      // Berlin center — far from any border
      final result = detectNearbyBorders(
        lat: 52.52,
        lng: 13.405,
        currentCountryCode: 'DE',
      );

      expect(result, isEmpty);
    });

    test('detects France near Strasbourg (DE side)', () {
      // Kehl, Germany — right at the French border
      final result = detectNearbyBorders(
        lat: 48.57,
        lng: 7.82,
        currentCountryCode: 'DE',
      );

      expect(result, isNotEmpty);
      expect(result.first.neighbor.code, 'FR');
      expect(result.first.distanceKm, lessThan(30));
    });

    test('detects Germany near Strasbourg (FR side)', () {
      // Strasbourg, France — right at the German border
      final result = detectNearbyBorders(
        lat: 48.58,
        lng: 7.75,
        currentCountryCode: 'FR',
      );

      expect(result, isNotEmpty);
      expect(result.any((b) => b.neighbor.code == 'DE'), isTrue);
    });

    test('detects Austria near Salzburg (DE side)', () {
      // Very close to the Salzburg border point (47.55, 13.05)
      final result = detectNearbyBorders(
        lat: 47.60,
        lng: 13.05,
        currentCountryCode: 'DE',
      );

      expect(result, isNotEmpty);
      expect(result.first.neighbor.code, 'AT');
      expect(result.first.distanceKm, lessThan(30));
    });

    test('detects Germany near Salzburg (AT side)', () {
      // Very close to the Salzburg border point (47.55, 13.05)
      final result = detectNearbyBorders(
        lat: 47.55,
        lng: 13.05,
        currentCountryCode: 'AT',
      );

      expect(result, isNotEmpty);
      expect(result.any((b) => b.neighbor.code == 'DE'), isTrue);
    });

    test('detects Denmark near Flensburg', () {
      // Flensburg, Germany — near Danish border
      final result = detectNearbyBorders(
        lat: 54.78,
        lng: 9.43,
        currentCountryCode: 'DE',
      );

      expect(result, isNotEmpty);
      expect(result.first.neighbor.code, 'DK');
    });

    test('detects Spain near Perpignan (FR side)', () {
      // Right at the border point (42.70, 2.88)
      final result = detectNearbyBorders(
        lat: 42.72,
        lng: 2.88,
        currentCountryCode: 'FR',
      );

      expect(result, isNotEmpty);
      expect(result.any((b) => b.neighbor.code == 'ES'), isTrue);
    });

    test('detects Portugal near Badajoz (ES side)', () {
      // Badajoz area, Spain
      final result = detectNearbyBorders(
        lat: 38.87,
        lng: -6.97,
        currentCountryCode: 'ES',
      );

      expect(result, isNotEmpty);
      expect(result.any((b) => b.neighbor.code == 'PT'), isTrue);
    });

    test('returns empty for unsupported country', () {
      final result = detectNearbyBorders(
        lat: 52.52,
        lng: 13.405,
        currentCountryCode: 'XX',
      );

      expect(result, isEmpty);
    });

    test('returns empty for country with no supported neighbors', () {
      // Buenos Aires, Argentina — no supported neighbors
      final result = detectNearbyBorders(
        lat: -34.60,
        lng: -58.38,
        currentCountryCode: 'AR',
      );

      expect(result, isEmpty);
    });

    test('results are sorted by distance', () {
      // Position equidistant from multiple borders (Saarbrücken area
      // near both FR and AT is unrealistic, but we can test sorting
      // with the FR border)
      final result = detectNearbyBorders(
        lat: 49.23,
        lng: 7.00,
        currentCountryCode: 'DE',
      );

      if (result.length > 1) {
        for (int i = 1; i < result.length; i++) {
          expect(
            result[i].distanceKm,
            greaterThanOrEqualTo(result[i - 1].distanceKm),
          );
        }
      }
    });

    test('respects custom threshold', () {
      // Kehl — very close to FR border, should be detected even at 5km
      final close = detectNearbyBorders(
        lat: 48.57,
        lng: 7.82,
        currentCountryCode: 'DE',
        thresholdKm: 5.0,
      );

      // Berlin — should not detect anything even at large threshold
      final far = detectNearbyBorders(
        lat: 52.52,
        lng: 13.405,
        currentCountryCode: 'DE',
        thresholdKm: 5.0,
      );

      expect(close, isNotEmpty);
      expect(far, isEmpty);
    });

    test('detects multiple neighbors when near intersection', () {
      // Nice area — FR borders IT, and nearby
      final result = detectNearbyBorders(
        lat: 43.79,
        lng: 7.50,
        currentCountryCode: 'FR',
        thresholdKm: 50,
      );

      // Should detect IT at minimum
      expect(result.any((b) => b.neighbor.code == 'IT'), isTrue);
    });
  });
}
