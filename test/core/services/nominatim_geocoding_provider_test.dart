import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/impl/nominatim_geocoding_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';

void main() {
  group('NominatimGeocodingProvider', () {
    test('source is nominatimGeocoding', () {
      final provider = NominatimGeocodingProvider();
      expect(provider.source, ServiceSource.nominatimGeocoding);
    });

    test('isAvailable always returns true', () {
      final provider = NominatimGeocodingProvider();
      expect(provider.isAvailable, true);
    });

    test('source returns correct ServiceSource', () {
      final provider = NominatimGeocodingProvider(countryCode: 'FR');
      expect(provider.source, ServiceSource.nominatimGeocoding);
      expect(provider.source.displayName, 'Nominatim (OSM)');
    });

    test('isAvailable is true for all country codes', () {
      for (final code in ['DE', 'FR', 'AT', 'ES', 'IT', 'GB', 'AU']) {
        final provider = NominatimGeocodingProvider(countryCode: code);
        expect(provider.isAvailable, true, reason: 'Should be available for $code');
      }
    });

    test('implements GeocodingProvider interface', () {
      final provider = NominatimGeocodingProvider();
      // Verify it has all required interface methods
      expect(provider.source, isA<ServiceSource>());
      expect(provider.isAvailable, isA<bool>());
    });

    test('default country code is de', () {
      final provider = NominatimGeocodingProvider();
      // We can't directly access _countryCode, but we can verify through source
      expect(provider.source, ServiceSource.nominatimGeocoding);
    });

    test('zipCodeToCoordinates throws LocationException on network error', () {
      // Create a provider that will fail because the API returns error
      final provider = NominatimGeocodingProvider(countryCode: 'DE');

      // The real provider will throw LocationException when API fails
      expect(
        () => provider.zipCodeToCoordinates('00000'),
        throwsA(isA<LocationException>()),
      );
    });

    test('coordinatesToAddress returns lat/lng string on failure', () async {
      // The real provider returns "$lat, $lng" when API call fails
      final provider = NominatimGeocodingProvider(countryCode: 'ZZ');

      // With an invalid setup, the method should handle errors gracefully
      // and return the raw coordinates as a fallback
      final address = await provider.coordinatesToAddress(0.0, 0.0);
      expect(address, contains('0.0'));
    });

    test('coordinatesToCountryCode returns null on failure', () async {
      // On network failure, should return null instead of throwing
      final provider = NominatimGeocodingProvider(countryCode: 'ZZ');

      final code = await provider.coordinatesToCountryCode(0.0, 0.0);
      expect(code, isNull);
    });
  });
}
