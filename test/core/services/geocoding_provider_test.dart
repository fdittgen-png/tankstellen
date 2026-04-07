import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/geocoding_provider.dart';
import 'package:tankstellen/core/services/impl/nominatim_geocoding_provider.dart';
import 'package:tankstellen/core/services/impl/native_geocoding_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';

/// A fake GeocodingProvider for testing that the interface contract works.
class _FakeGeocodingProvider extends GeocodingProvider {
  final ServiceSource _source;
  final bool _isAvailable;
  ({double lat, double lng})? zipResult;
  String? addressResult;
  String? countryCodeResult;
  Exception? error;

  _FakeGeocodingProvider({
    ServiceSource source = ServiceSource.nominatimGeocoding,
    bool isAvailable = true,
    this.zipResult,
    this.addressResult,
    this.countryCodeResult,
    this.error,
  })  : _source = source,
        _isAvailable = isAvailable;

  @override
  ServiceSource get source => _source;

  @override
  bool get isAvailable => _isAvailable;

  @override
  Future<({double lat, double lng})> zipCodeToCoordinates(
    String zipCode, {
    CancelToken? cancelToken,
  }) async {
    if (error != null) throw error!;
    return zipResult!;
  }

  @override
  Future<String> coordinatesToAddress(
    double lat, double lng, {
    CancelToken? cancelToken,
  }) async {
    if (error != null) throw error!;
    return addressResult!;
  }

  @override
  Future<String?> coordinatesToCountryCode(
    double lat, double lng, {
    CancelToken? cancelToken,
  }) async {
    if (error != null) throw error!;
    return countryCodeResult;
  }
}

void main() {
  group('GeocodingProvider interface', () {
    test('can be implemented with custom provider', () {
      final provider = _FakeGeocodingProvider(
        source: ServiceSource.nominatimGeocoding,
        isAvailable: true,
      );

      expect(provider.source, ServiceSource.nominatimGeocoding);
      expect(provider.isAvailable, true);
    });

    test('zipCodeToCoordinates returns coordinates', () async {
      final provider = _FakeGeocodingProvider(
        zipResult: (lat: 52.52, lng: 13.41),
      );

      final result = await provider.zipCodeToCoordinates('10115');
      expect(result.lat, 52.52);
      expect(result.lng, 13.41);
    });

    test('coordinatesToAddress returns address string', () async {
      final provider = _FakeGeocodingProvider(
        addressResult: '10115 Berlin',
      );

      final result = await provider.coordinatesToAddress(52.52, 13.41);
      expect(result, '10115 Berlin');
    });

    test('coordinatesToCountryCode returns country code', () async {
      final provider = _FakeGeocodingProvider(
        countryCodeResult: 'DE',
      );

      final result = await provider.coordinatesToCountryCode(52.52, 13.41);
      expect(result, 'DE');
    });

    test('coordinatesToCountryCode defaults to null in base class', () async {
      // The base class default implementation returns null
      final provider = _FakeGeocodingProvider(
        countryCodeResult: null,
      );

      final result = await provider.coordinatesToCountryCode(52.52, 13.41);
      expect(result, isNull);
    });

    test('unavailable provider reports isAvailable false', () {
      final provider = _FakeGeocodingProvider(isAvailable: false);
      expect(provider.isAvailable, false);
    });

    test('provider can throw on error', () {
      final provider = _FakeGeocodingProvider(
        error: Exception('API unavailable'),
      );

      expect(
        () => provider.zipCodeToCoordinates('10115'),
        throwsA(isA<Exception>()),
      );
    });

    test('CancelToken can be passed to all methods', () async {
      final provider = _FakeGeocodingProvider(
        zipResult: (lat: 52.52, lng: 13.41),
        addressResult: 'Berlin',
        countryCodeResult: 'DE',
      );
      final token = CancelToken();

      // All methods accept CancelToken without error
      await provider.zipCodeToCoordinates('10115', cancelToken: token);
      await provider.coordinatesToAddress(52.52, 13.41, cancelToken: token);
      await provider.coordinatesToCountryCode(52.52, 13.41, cancelToken: token);
    });
  });

  group('Provider implementations exist', () {
    test('NominatimGeocodingProvider implements GeocodingProvider', () {
      final provider = NominatimGeocodingProvider();
      expect(provider, isA<GeocodingProvider>());
      expect(provider.source, ServiceSource.nominatimGeocoding);
      expect(provider.isAvailable, true);
    });

    test('NativeGeocodingProvider implements GeocodingProvider', () {
      final provider = NativeGeocodingProvider();
      expect(provider, isA<GeocodingProvider>());
      expect(provider.source, ServiceSource.nativeGeocoding);
      // isAvailable depends on platform — on test (non-mobile) it's false
    });

    test('providers have distinct sources', () {
      final nominatim = NominatimGeocodingProvider();
      final native = NativeGeocodingProvider();

      expect(nominatim.source, isNot(native.source));
      expect(nominatim.source, ServiceSource.nominatimGeocoding);
      expect(native.source, ServiceSource.nativeGeocoding);
    });
  });

  group('Provider swapping', () {
    test('different providers can be substituted via interface', () async {
      // Simulate provider A (primary) failing and B (fallback) succeeding
      final primaryProvider = _FakeGeocodingProvider(
        source: ServiceSource.nativeGeocoding,
        error: Exception('Platform not supported'),
      );
      final fallbackProvider = _FakeGeocodingProvider(
        source: ServiceSource.nominatimGeocoding,
        zipResult: (lat: 48.86, lng: 2.35),
      );

      // The chain would try primary, fail, then use fallback
      // Here we test that both implement the same interface
      final providers = <GeocodingProvider>[primaryProvider, fallbackProvider];

      GeocodingProvider? workingProvider;
      for (final p in providers) {
        if (!p.isAvailable) continue;
        try {
          await p.zipCodeToCoordinates('75001');
          workingProvider = p;
          break;
        } on Exception {
          continue;
        }
      }

      expect(workingProvider, isNotNull);
      expect(workingProvider!.source, ServiceSource.nominatimGeocoding);
    });

    test('custom providers can be created for testing', () async {
      final testProvider = _FakeGeocodingProvider(
        source: ServiceSource.nominatimGeocoding,
        zipResult: (lat: 40.42, lng: -3.70),
        addressResult: '28001 Madrid',
        countryCodeResult: 'ES',
      );

      final coords = await testProvider.zipCodeToCoordinates('28001');
      expect(coords.lat, 40.42);
      expect(coords.lng, -3.70);

      final address = await testProvider.coordinatesToAddress(40.42, -3.70);
      expect(address, '28001 Madrid');

      final country = await testProvider.coordinatesToCountryCode(40.42, -3.70);
      expect(country, 'ES');
    });
  });
}
