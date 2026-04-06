import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/services/geocoding_chain.dart';
import 'package:tankstellen/core/services/geocoding_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';

class MockCacheManager extends Mock implements CacheManager {}

/// A fake geocoding provider that records whether a CancelToken was received.
class _TrackingGeocodingProvider implements GeocodingProvider {
  CancelToken? lastZipCancelToken;
  CancelToken? lastAddressCancelToken;
  CancelToken? lastCountryCodeCancelToken;

  @override
  ServiceSource get source => ServiceSource.nominatimGeocoding;

  @override
  bool get isAvailable => true;

  @override
  Future<({double lat, double lng})> zipCodeToCoordinates(
    String zipCode, {
    CancelToken? cancelToken,
  }) async {
    lastZipCancelToken = cancelToken;
    return (lat: 52.52, lng: 13.41);
  }

  @override
  Future<String> coordinatesToAddress(
    double lat, double lng, {
    CancelToken? cancelToken,
  }) async {
    lastAddressCancelToken = cancelToken;
    return '10115 Berlin';
  }

  @override
  Future<String?> coordinatesToCountryCode(
    double lat, double lng, {
    CancelToken? cancelToken,
  }) async {
    lastCountryCodeCancelToken = cancelToken;
    return 'DE';
  }
}

void main() {
  late MockCacheManager mockCache;
  late _TrackingGeocodingProvider trackingProvider;
  late GeocodingChain chain;

  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 1));
    registerFallbackValue(ServiceSource.cache);
  });

  setUp(() {
    mockCache = MockCacheManager();
    trackingProvider = _TrackingGeocodingProvider();
    chain = GeocodingChain([trackingProvider], mockCache);

    // Default: cache miss so provider is always called
    when(() => mockCache.getFresh(any())).thenReturn(null);
    when(() => mockCache.put(
          any(),
          any(),
          ttl: any(named: 'ttl'),
          source: any(named: 'source'),
        )).thenAnswer((_) async {});
  });

  group('CancelToken propagation through GeocodingChain', () {
    test('zipCodeToCoordinates passes cancelToken to provider', () async {
      final token = CancelToken();
      await chain.zipCodeToCoordinates('10115', cancelToken: token);
      expect(trackingProvider.lastZipCancelToken, same(token));
    });

    test('zipCodeToCoordinates passes null cancelToken by default', () async {
      await chain.zipCodeToCoordinates('10115');
      expect(trackingProvider.lastZipCancelToken, isNull);
    });

    test('coordinatesToAddress passes cancelToken to provider', () async {
      final token = CancelToken();
      await chain.coordinatesToAddress(52.52, 13.41, cancelToken: token);
      expect(trackingProvider.lastAddressCancelToken, same(token));
    });

    test('coordinatesToAddress passes null cancelToken by default', () async {
      await chain.coordinatesToAddress(52.52, 13.41);
      expect(trackingProvider.lastAddressCancelToken, isNull);
    });

    test('coordinatesToCountryCode passes cancelToken to provider', () async {
      final token = CancelToken();
      await chain.coordinatesToCountryCode(52.52, 13.41, cancelToken: token);
      expect(trackingProvider.lastCountryCodeCancelToken, same(token));
    });

    test('coordinatesToCountryCode passes null cancelToken by default',
        () async {
      await chain.coordinatesToCountryCode(52.52, 13.41);
      expect(trackingProvider.lastCountryCodeCancelToken, isNull);
    });

    test('cancelToken is not passed when fresh cache hit', () async {
      final token = CancelToken();
      when(() => mockCache.getFresh('geo:zip:10115')).thenReturn(CacheEntry(
        payload: {'lat': 52.52, 'lng': 13.41},
        storedAt: DateTime.now(),
        originalSource: ServiceSource.nominatimGeocoding,
        ttl: CacheTtl.geocode,
      ));

      await chain.zipCodeToCoordinates('10115', cancelToken: token);

      // Provider should not have been called at all
      expect(trackingProvider.lastZipCancelToken, isNull);
    });
  });

  group('GeocodingProvider interface CancelToken support', () {
    test('all methods accept optional CancelToken parameter', () {
      // This test verifies the interface compiles with CancelToken parameters.
      // If the interface were missing the parameter, this file would not compile.
      final GeocodingProvider provider = trackingProvider;
      expect(provider.source, ServiceSource.nominatimGeocoding);
      expect(provider.isAvailable, isTrue);
    });
  });
}
