import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/api_constants.dart';

void main() {
  group('ApiConstants — endpoints', () {
    test('baseUrl points at the creative-commons Tankerkoenig host', () {
      // Pin the host: switching to api.tankerkoenig.de requires a paid key.
      // A PR that silently flipped the host would break every anonymous
      // install in prod.
      expect(ApiConstants.baseUrl, 'https://creativecommons.tankerkoenig.de/json');
      expect(ApiConstants.baseUrl, startsWith('https://'));
    });

    test('endpoints use the .php extension with a leading slash', () {
      // Tankerkoenig's router is exact-match; the leading slash and the
      // .php extension both matter.
      const endpoints = [
        ApiConstants.listEndpoint,
        ApiConstants.detailEndpoint,
        ApiConstants.pricesEndpoint,
        ApiConstants.complaintEndpoint,
      ];
      for (final endpoint in endpoints) {
        expect(endpoint, startsWith('/'));
        expect(endpoint, endsWith('.php'));
      }
    });

    test('all endpoints are pairwise distinct', () {
      final endpoints = {
        ApiConstants.listEndpoint,
        ApiConstants.detailEndpoint,
        ApiConstants.pricesEndpoint,
        ApiConstants.complaintEndpoint,
      };
      expect(endpoints.length, 4,
          reason: 'Two endpoints share the same path');
    });
  });

  group('ApiConstants — search limits', () {
    test('defaultRadiusKm ≤ maxRadiusKm (sanity)', () {
      // Default must sit within the allowed range — otherwise every
      // fresh install would reject its own initial query.
      expect(ApiConstants.defaultRadiusKm,
          lessThanOrEqualTo(ApiConstants.maxRadiusKm));
    });

    test('Tankerkoenig upstream caps (25 km, 10 ids, 5 min)', () {
      // These mirror the upstream API contract; do not bump without
      // confirming the upstream has lifted its limits first.
      expect(ApiConstants.maxRadiusKm, 25);
      expect(ApiConstants.maxPriceQueryIds, 10);
      expect(ApiConstants.minRefreshInterval, const Duration(minutes: 5));
    });

    test('defaultRadiusKm is 10 km', () {
      expect(ApiConstants.defaultRadiusKm, 10);
    });
  });

  group('ApiConstants — test coordinates', () {
    test('testLatitude/testLongitude resolve to central Berlin', () {
      // Used by the API-key validation probe — pin the location so a
      // silent drift doesn't end up testing against an offshore region
      // with no stations (false negative on a valid key).
      expect(ApiConstants.testLatitude, closeTo(52.52, 0.01));
      expect(ApiConstants.testLongitude, closeTo(13.44, 0.01));
    });
  });
}
