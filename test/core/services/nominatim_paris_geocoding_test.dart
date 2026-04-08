import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/impl/nominatim_geocoding_provider.dart';

/// Fake Dio adapter that captures query parameters for assertions.
class _CapturingAdapter implements HttpClientAdapter {
  Map<String, dynamic>? capturedQueryParams;
  final double lat;
  final double lon;

  _CapturingAdapter({this.lat = 48.8566, this.lon = 2.3522});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Extract query parameters from the URI
    capturedQueryParams = options.uri.queryParameters;

    // Return a valid Nominatim-style response
    final body =
        '[{"lat":"$lat","lon":"$lon","display_name":"Test"}]';
    return ResponseBody.fromString(body, 200, headers: {
      'content-type': ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('NominatimGeocodingProvider French city hint', () {
    late Dio dio;
    late _CapturingAdapter adapter;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://nominatim.openstreetmap.org'));
      adapter = _CapturingAdapter();
      dio.httpClientAdapter = adapter;
    });

    test('adds city=Paris for Paris arrondissement 75001', () async {
      final provider = NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
      await provider.zipCodeToCoordinates('75001');

      expect(adapter.capturedQueryParams?['city'], 'Paris');
      expect(adapter.capturedQueryParams?['postalcode'], '75001');
      expect(adapter.capturedQueryParams?['country'], 'fr');
    });

    test('adds city=Paris for Paris arrondissement 75012', () async {
      final provider = NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
      await provider.zipCodeToCoordinates('75012');

      expect(adapter.capturedQueryParams?['city'], 'Paris');
    });

    test('adds city=Paris for Paris arrondissement 75020', () async {
      final provider = NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
      await provider.zipCodeToCoordinates('75020');

      expect(adapter.capturedQueryParams?['city'], 'Paris');
    });

    test('adds city=Lyon for Lyon arrondissement 69001', () async {
      final provider = NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
      await provider.zipCodeToCoordinates('69001');

      expect(adapter.capturedQueryParams?['city'], 'Lyon');
    });

    test('adds city=Lyon for Lyon arrondissement 69009', () async {
      final provider = NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
      await provider.zipCodeToCoordinates('69009');

      expect(adapter.capturedQueryParams?['city'], 'Lyon');
    });

    test('adds city=Marseille for Marseille arrondissement 13001', () async {
      final provider = NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
      await provider.zipCodeToCoordinates('13001');

      expect(adapter.capturedQueryParams?['city'], 'Marseille');
    });

    test('adds city=Marseille for Marseille arrondissement 13016', () async {
      final provider = NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
      await provider.zipCodeToCoordinates('13016');

      expect(adapter.capturedQueryParams?['city'], 'Marseille');
    });

    test('no city hint for regular French postal code 33000', () async {
      final provider = NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
      await provider.zipCodeToCoordinates('33000');

      expect(adapter.capturedQueryParams?['city'], isNull);
      expect(adapter.capturedQueryParams?['postalcode'], '33000');
    });

    test('no city hint for 75021 (outside Paris range)', () async {
      final provider = NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
      await provider.zipCodeToCoordinates('75021');

      expect(adapter.capturedQueryParams?['city'], isNull);
    });

    test('no city hint for 69010 (outside Lyon range)', () async {
      final provider = NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
      await provider.zipCodeToCoordinates('69010');

      expect(adapter.capturedQueryParams?['city'], isNull);
    });

    test('no city hint for 13017 (outside Marseille range)', () async {
      final provider = NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
      await provider.zipCodeToCoordinates('13017');

      expect(adapter.capturedQueryParams?['city'], isNull);
    });

    test('no city hint for German postal code 75001', () async {
      final provider = NominatimGeocodingProvider(countryCode: 'DE', dio: dio);
      await provider.zipCodeToCoordinates('75001');

      expect(adapter.capturedQueryParams?['city'], isNull);
      expect(adapter.capturedQueryParams?['country'], 'de');
    });

    test('no city hint for short postal code', () async {
      final provider = NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
      await provider.zipCodeToCoordinates('7501');

      expect(adapter.capturedQueryParams?['city'], isNull);
    });

    test('returns correct coordinates from response', () async {
      dio.httpClientAdapter = _CapturingAdapter(lat: 48.8412, lon: 2.3876);
      final provider = NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
      final result = await provider.zipCodeToCoordinates('75012');

      expect(result.lat, closeTo(48.8412, 0.0001));
      expect(result.lng, closeTo(2.3876, 0.0001));
    });
  });
}
