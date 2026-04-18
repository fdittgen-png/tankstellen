import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/impl/nominatim_geocoding_provider.dart';

/// Tests that Nominatim supports both numeric ZIP queries (with French
/// arrondissement hints) AND free-text city queries like "Paris" (#690).
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
    capturedQueryParams = options.uri.queryParameters;
    final body = '[{"lat":"$lat","lon":"$lon","display_name":"Test"}]';
    return ResponseBody.fromString(body, 200, headers: {
      'content-type': ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('NominatimGeocodingProvider — free-text city queries', () {
    late Dio dio;
    late _CapturingAdapter adapter;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: 'https://nominatim.openstreetmap.org'));
      adapter = _CapturingAdapter();
      dio.httpClientAdapter = adapter;
    });

    test('"Paris" uses q= (free text), not postalcode=', () async {
      // Before #690 the provider sent postalcode=Paris which Nominatim
      // would reject as a non-postcode, leaving the user with no results
      // and the chain falling back to native / stale cache.
      final provider = NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
      await provider.zipCodeToCoordinates('Paris');

      expect(adapter.capturedQueryParams?['q'], 'Paris');
      expect(adapter.capturedQueryParams?['postalcode'], isNull);
      expect(adapter.capturedQueryParams?['country'], 'fr');
    });

    test('"Lyon" uses q= (free text)', () async {
      final provider = NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
      await provider.zipCodeToCoordinates('Lyon');

      expect(adapter.capturedQueryParams?['q'], 'Lyon');
      expect(adapter.capturedQueryParams?['postalcode'], isNull);
    });

    test('"Berlin Mitte" (multi-word) uses q=', () async {
      final provider = NominatimGeocodingProvider(countryCode: 'DE', dio: dio);
      await provider.zipCodeToCoordinates('Berlin Mitte');

      expect(adapter.capturedQueryParams?['q'], 'Berlin Mitte');
    });

    test('numeric ZIP "10115" still uses postalcode= (not q=)', () async {
      // Regression guard — the structured postcode endpoint is more
      // reliable than free text for numeric inputs.
      final provider = NominatimGeocodingProvider(countryCode: 'DE', dio: dio);
      await provider.zipCodeToCoordinates('10115');

      expect(adapter.capturedQueryParams?['postalcode'], '10115');
      expect(adapter.capturedQueryParams?['q'], isNull);
    });

    test('numeric ZIP "75001" still adds Paris city hint', () async {
      final provider = NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
      await provider.zipCodeToCoordinates('75001');

      expect(adapter.capturedQueryParams?['postalcode'], '75001');
      expect(adapter.capturedQueryParams?['city'], 'Paris');
      expect(adapter.capturedQueryParams?['q'], isNull);
    });

    test('trims whitespace from both numeric and text queries', () async {
      final provider = NominatimGeocodingProvider(countryCode: 'FR', dio: dio);
      await provider.zipCodeToCoordinates('  75012  ');
      expect(adapter.capturedQueryParams?['postalcode'], '75012');

      await provider.zipCodeToCoordinates('  Paris  ');
      expect(adapter.capturedQueryParams?['q'], 'Paris');
    });
  });
}
