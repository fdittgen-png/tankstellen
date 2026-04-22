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
    test('has entries for all 13 supported countries', () {
      const expectedCountries = [
        'DE', 'FR', 'AT', 'ES', 'IT', 'DK', 'AR', 'PT', 'GB', 'AU', 'MX', 'SI', 'KR',
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

  group('countryCodeFromLatLng (#516 bbox lookup)', () {
    // Cross-currency boundaries — these MUST resolve correctly or the
    // user sees the wrong symbol.
    test('Paris → FR (EUR, not GB)', () {
      expect(countryCodeFromLatLng(48.85, 2.35), 'FR');
    });

    test('Lyon → FR', () {
      expect(countryCodeFromLatLng(45.75, 4.85), 'FR');
    });

    test('London → GB (GBP, not FR)', () {
      expect(countryCodeFromLatLng(51.51, -0.13), 'GB');
    });

    test('Manchester → GB', () {
      expect(countryCodeFromLatLng(53.48, -2.24), 'GB');
    });

    test('Berlin → DE (lng outside FR box)', () {
      expect(countryCodeFromLatLng(52.52, 13.41), 'DE');
    });

    test('Copenhagen → DK (DKK, not DE EUR)', () {
      expect(countryCodeFromLatLng(55.68, 12.57), 'DK');
    });

    test('Lisbon → PT (PT tested before the generous ES box)', () {
      expect(countryCodeFromLatLng(38.72, -9.14), 'PT');
    });

    test('Porto → PT', () {
      expect(countryCodeFromLatLng(41.16, -8.63), 'PT');
    });

    test('Madrid → ES', () {
      expect(countryCodeFromLatLng(40.42, -3.70), 'ES');
    });

    test('Rome → IT (lng outside FR)', () {
      expect(countryCodeFromLatLng(41.90, 12.50), 'IT');
    });

    test('Vienna → AT (lng outside DE and FR)', () {
      expect(countryCodeFromLatLng(48.21, 16.37), 'AT');
    });

    test('Sydney → AU', () {
      expect(countryCodeFromLatLng(-33.87, 151.21), 'AU');
    });

    test('CDMX → MX', () {
      expect(countryCodeFromLatLng(19.43, -99.13), 'MX');
    });

    test('Buenos Aires → AR', () {
      expect(countryCodeFromLatLng(-34.60, -58.38), 'AR');
    });

    test('Seoul → KR (#597)', () {
      expect(countryCodeFromLatLng(37.56, 126.98), 'KR');
    });

    test('Jeju → KR (island, #597)', () {
      expect(countryCodeFromLatLng(33.50, 126.53), 'KR');
    });

    test('KR bounding box rejects German coordinates', () {
      // Berlin sits at (52.52, 13.41) — must not be misattributed to KR.
      expect(countryBoundingBoxes['KR']!.contains(52.52, 13.41), isFalse);
    });

    test('returns null for mid-Atlantic coordinates', () {
      expect(countryCodeFromLatLng(0.0, -30.0), isNull);
    });

    test('returns null for mid-Pacific coordinates', () {
      expect(countryCodeFromLatLng(0.0, -150.0), isNull);
    });

    test('returns null for Antarctica', () {
      expect(countryCodeFromLatLng(-80.0, 0.0), isNull);
    });

    // EU-zone ambiguous points — all that matters is they resolve
    // to SOME EUR country. For currency dispatch the precise country
    // code is irrelevant when both candidates share the currency.
    group('EU-zone ambiguous points resolve to a EUR country', () {
      final eurCountries = {'FR', 'DE', 'AT', 'IT', 'ES', 'PT', 'BE', 'LU', 'NL'};

      test('Munich lands somewhere in the EUR zone', () {
        final code = countryCodeFromLatLng(48.14, 11.58);
        expect(code, isNotNull);
        expect(eurCountries, contains(code));
      });

      test('Nice lands somewhere in the EUR zone', () {
        final code = countryCodeFromLatLng(43.70, 7.27);
        expect(code, isNotNull);
        expect(eurCountries, contains(code));
      });

      test('Salzburg lands somewhere in the EUR zone', () {
        final code = countryCodeFromLatLng(47.80, 13.05);
        expect(code, isNotNull);
        expect(eurCountries, contains(code));
      });
    });
  });
}
