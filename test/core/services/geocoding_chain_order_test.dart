import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/services/geocoding_chain.dart';
import 'package:tankstellen/core/services/geocoding_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';

class _MockCacheManager extends Mock implements CacheManager {}

class _MockGeocodingProvider extends Mock implements GeocodingProvider {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 1));
    registerFallbackValue(ServiceSource.cache);
  });

  group('GeocodingChain — Nominatim-first fallback (#690)', () {
    late _MockCacheManager cache;
    late _MockGeocodingProvider nominatim;
    late _MockGeocodingProvider native;
    late GeocodingChain chain;

    setUp(() {
      cache = _MockCacheManager();
      nominatim = _MockGeocodingProvider();
      native = _MockGeocodingProvider();
      when(() => nominatim.isAvailable).thenReturn(true);
      when(() => native.isAvailable).thenReturn(true);
      when(() => nominatim.source).thenReturn(ServiceSource.nominatimGeocoding);
      when(() => native.source).thenReturn(ServiceSource.nativeGeocoding);

      // Nominatim first, native second — matches the prod order after #690.
      chain = GeocodingChain([nominatim, native], cache, countryCode: 'FR');
      when(() => cache.getFresh(any())).thenReturn(null);
      when(() => cache.get(any())).thenReturn(null);
      when(() => cache.put(
            any(),
            any(),
            ttl: any(named: 'ttl'),
            source: any(named: 'source'),
          )).thenAnswer((_) async {});
    });

    test(
      'Paris query: Nominatim is tried FIRST and its result wins — '
      'native geocoder never consulted',
      () async {
        when(() => nominatim.zipCodeToCoordinates('Paris'))
            .thenAnswer((_) async => (lat: 48.8566, lng: 2.3522));

        final result = await chain.zipCodeToCoordinates('Paris');

        expect(result.data.lat, closeTo(48.85, 0.01));
        expect(result.data.lng, closeTo(2.35, 0.01));
        expect(result.source, ServiceSource.nominatimGeocoding);
        verify(() => nominatim.zipCodeToCoordinates('Paris')).called(1);
        verifyNever(() => native.zipCodeToCoordinates(any()));
      },
    );

    test(
      'ZIP 75001 query: Nominatim is tried FIRST — even if native would '
      'also succeed, Nominatim wins because the city-hint logic lives there',
      () async {
        when(() => nominatim.zipCodeToCoordinates('75001'))
            .thenAnswer((_) async => (lat: 48.8606, lng: 2.3376));
        when(() => native.zipCodeToCoordinates('75001'))
            .thenAnswer((_) async => (lat: 43.4672, lng: 3.4242)); // wrong: local

        final result = await chain.zipCodeToCoordinates('75001');

        // Must be Paris (48.86) not local (43.47) — Nominatim's
        // arrondissement-aware result wins over any native quirk.
        expect(result.data.lat, closeTo(48.86, 0.02));
        expect(result.source, ServiceSource.nominatimGeocoding);
        verify(() => nominatim.zipCodeToCoordinates('75001')).called(1);
        verifyNever(() => native.zipCodeToCoordinates(any()));
      },
    );

    test(
      'native is tried only when Nominatim throws',
      () async {
        // Use a FR ZIP here so the bbox check accepts the native coord.
        when(() => nominatim.zipCodeToCoordinates('75001'))
            .thenThrow(Exception('Nominatim unavailable'));
        when(() => native.zipCodeToCoordinates('75001'))
            .thenAnswer((_) async => (lat: 48.8606, lng: 2.3376));

        final result = await chain.zipCodeToCoordinates('75001');

        expect(result.data.lat, closeTo(48.86, 0.02));
        expect(result.source, ServiceSource.nativeGeocoding);
      },
    );
  });
}
