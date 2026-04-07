import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_bounding_box.dart';

void main() {
  group('CountryBoundingBox', () {
    test('contains returns true for point inside box', () {
      const box = CountryBoundingBox(
        minLat: 47.0,
        maxLat: 55.5,
        minLng: 5.5,
        maxLng: 15.5,
      );
      expect(box.contains(52.52, 13.41), isTrue); // Berlin
    });

    test('contains returns false for point outside box', () {
      const box = CountryBoundingBox(
        minLat: 47.0,
        maxLat: 55.5,
        minLng: 5.5,
        maxLng: 15.5,
      );
      expect(box.contains(48.86, 2.35), isFalse); // Paris — outside DE box
    });

    test('contains returns true for point on boundary', () {
      const box = CountryBoundingBox(
        minLat: 47.0,
        maxLat: 55.5,
        minLng: 5.5,
        maxLng: 15.5,
      );
      expect(box.contains(47.0, 5.5), isTrue); // Exact corner
    });

    test('toString returns readable format', () {
      const box = CountryBoundingBox(
        minLat: 47.0,
        maxLat: 55.5,
        minLng: 5.5,
        maxLng: 15.5,
      );
      expect(box.toString(), contains('47.0'));
      expect(box.toString(), contains('55.5'));
    });
  });

  group('countryBoundingBoxes', () {
    test('has entries for all 11 supported countries', () {
      const expectedCountries = [
        'DE', 'FR', 'AT', 'ES', 'IT', 'DK', 'AR', 'PT', 'GB', 'AU', 'MX',
      ];
      for (final code in expectedCountries) {
        expect(countryBoundingBoxes.containsKey(code), isTrue,
            reason: 'Missing bounding box for $code');
      }
    });

    test('Germany box contains Berlin', () {
      expect(countryBoundingBoxes['DE']!.contains(52.52, 13.41), isTrue);
    });

    test('Germany box contains Munich', () {
      expect(countryBoundingBoxes['DE']!.contains(48.14, 11.58), isTrue);
    });

    test('Germany box does not contain Paris', () {
      expect(countryBoundingBoxes['DE']!.contains(48.86, 2.35), isFalse);
    });

    test('France box contains Paris', () {
      expect(countryBoundingBoxes['FR']!.contains(48.86, 2.35), isTrue);
    });

    test('France box contains Marseille', () {
      expect(countryBoundingBoxes['FR']!.contains(43.30, 5.37), isTrue);
    });

    test('France box does not contain Berlin', () {
      expect(countryBoundingBoxes['FR']!.contains(52.52, 13.41), isFalse);
    });

    test('Austria box contains Vienna', () {
      expect(countryBoundingBoxes['AT']!.contains(48.21, 16.37), isTrue);
    });

    test('Austria box does not contain Rome', () {
      expect(countryBoundingBoxes['AT']!.contains(41.90, 12.50), isFalse);
    });

    test('Spain box contains Madrid', () {
      expect(countryBoundingBoxes['ES']!.contains(40.42, -3.70), isTrue);
    });

    test('Spain box contains Canary Islands (Tenerife)', () {
      expect(countryBoundingBoxes['ES']!.contains(28.47, -16.25), isTrue);
    });

    test('Italy box contains Rome', () {
      expect(countryBoundingBoxes['IT']!.contains(41.90, 12.50), isTrue);
    });

    test('Italy box contains Sicily (Palermo)', () {
      expect(countryBoundingBoxes['IT']!.contains(38.12, 13.36), isTrue);
    });

    test('Denmark box contains Copenhagen', () {
      expect(countryBoundingBoxes['DK']!.contains(55.68, 12.57), isTrue);
    });

    test('Argentina box contains Buenos Aires', () {
      expect(countryBoundingBoxes['AR']!.contains(-34.60, -58.38), isTrue);
    });

    test('Portugal box contains Lisbon', () {
      expect(countryBoundingBoxes['PT']!.contains(38.72, -9.14), isTrue);
    });

    test('Portugal box contains Azores (Ponta Delgada)', () {
      expect(countryBoundingBoxes['PT']!.contains(37.75, -25.67), isTrue);
    });

    test('UK box contains London', () {
      expect(countryBoundingBoxes['GB']!.contains(51.51, -0.13), isTrue);
    });

    test('UK box contains Edinburgh', () {
      expect(countryBoundingBoxes['GB']!.contains(55.95, -3.19), isTrue);
    });

    test('Australia box contains Sydney', () {
      expect(countryBoundingBoxes['AU']!.contains(-33.87, 151.21), isTrue);
    });

    test('Mexico box contains Mexico City', () {
      expect(countryBoundingBoxes['MX']!.contains(19.43, -99.13), isTrue);
    });

    // Cross-country rejection tests
    test('Germany box rejects coordinates from ocean', () {
      expect(countryBoundingBoxes['DE']!.contains(0.0, 0.0), isFalse);
    });

    test('UK box rejects coordinates from Australia', () {
      expect(countryBoundingBoxes['GB']!.contains(-33.87, 151.21), isFalse);
    });

    test('France box rejects coordinates from Argentina', () {
      expect(countryBoundingBoxes['FR']!.contains(-34.60, -58.38), isFalse);
    });
  });
}
