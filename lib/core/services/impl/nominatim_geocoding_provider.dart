import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import '../../error/exceptions.dart';
import '../dio_factory.dart';
import '../geocoding_provider.dart';
import '../service_config.dart';
import '../service_result.dart';

/// Geocoding via OpenStreetMap Nominatim API.
/// Available on all platforms. Enforces 1 req/sec rate limit.
/// Country-aware: passes the correct country code to Nominatim.
///
/// For French arrondissement postal codes (Paris 75001–75020,
/// Lyon 69001–69009, Marseille 13001–13016), a city hint is added
/// to prevent Nominatim from returning coordinates outside the
/// target area.
class NominatimGeocodingProvider implements GeocodingProvider {
  final Dio _dio;
  final String _countryCode;
  DateTime? _lastRequest;

  NominatimGeocodingProvider({String countryCode = 'de', @visibleForTesting Dio? dio})
      : _countryCode = countryCode.toLowerCase(),
        _dio = dio ?? DioFactory.create(
          baseUrl: ServiceConfigs.nominatim.baseUrl,
          connectTimeout: ServiceConfigs.nominatim.connectTimeout,
          receiveTimeout: ServiceConfigs.nominatim.receiveTimeout,
        );

  @override
  ServiceSource get source => ServiceSource.nominatimGeocoding;

  @override
  bool get isAvailable => true;

  @override
  Future<({double lat, double lng})> zipCodeToCoordinates(
    String zipCode, {
    CancelToken? cancelToken,
  }) async {
    await _enforceRateLimit();

    try {
      _lastRequest = DateTime.now();
      final queryParams = <String, String>{
        'postalcode': zipCode,
        'country': _countryCode,
        'format': 'json',
        'limit': '1',
      };

      // Add city hint for French arrondissement postal codes to
      // prevent Nominatim from returning wrong centroids.
      final cityHint = _frenchCityHint(zipCode);
      if (cityHint != null) {
        queryParams['city'] = cityHint;
      }

      final response = await _dio.get<List<dynamic>>(
        '/search',
        queryParameters: queryParams,
        cancelToken: cancelToken,
      );

      final results = response.data;
      if (results == null || results.isEmpty) {
        throw LocationException(
          message: 'No coordinates found for postal code $zipCode '
              'in country $_countryCode.',
        );
      }

      final first = results[0] as Map<String, dynamic>;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lng = double.tryParse(first['lon']?.toString() ?? '');

      if (lat == null || lng == null) {
        throw LocationException(
          message: 'Invalid coordinates for postal code $zipCode.',
        );
      }

      return (lat: lat, lng: lng);
    } on DioException catch (e) {
      throw LocationException(
        message: 'Nominatim geocoding failed: ${e.message}',
      );
    }
  }

  @override
  Future<String> coordinatesToAddress(
    double lat, double lng, {
    CancelToken? cancelToken,
  }) async {
    await _enforceRateLimit();

    try {
      _lastRequest = DateTime.now();
      final response = await _dio.get<Map<String, dynamic>>(
        '/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'zoom': '16',
        },
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data == null) return '$lat, $lng';

      final address = data['address'] as Map<String, dynamic>?;
      if (address == null) {
        return data['display_name']?.toString() ?? '$lat, $lng';
      }

      return [address['postcode'], address['city'] ?? address['town'] ?? address['village']]
          .where((s) => s != null && s.toString().isNotEmpty)
          .join(' ');
    } on DioException catch (e) {
      debugPrint('Nominatim reverse geocoding failed: $e');
      return '$lat, $lng';
    }
  }

  @override
  Future<String?> coordinatesToCountryCode(
    double lat, double lng, {
    CancelToken? cancelToken,
  }) async {
    await _enforceRateLimit();
    try {
      _lastRequest = DateTime.now();
      final response = await _dio.get<Map<String, dynamic>>(
        '/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'zoom': '3', // country-level zoom, minimal data
        },
        cancelToken: cancelToken,
      );
      final address = response.data?['address'] as Map<String, dynamic>?;
      final code = address?['country_code'] as String?;
      return code?.toUpperCase();
    } on DioException catch (e) {
      debugPrint('Nominatim country detection failed: $e');
      return null;
    }
  }

  /// Returns a city name hint for French arrondissement postal codes.
  ///
  /// Paris (75001–75020), Lyon (69001–69009), and Marseille (13001–13016)
  /// use per-arrondissement postal codes that Nominatim resolves unreliably
  /// without a city hint. Returns `null` for non-French or non-arrondissement
  /// codes.
  String? _frenchCityHint(String zipCode) {
    if (_countryCode != 'fr') return null;
    if (zipCode.length != 5) return null;

    final code = int.tryParse(zipCode);
    if (code == null) return null;

    if (code >= 75001 && code <= 75020) return 'Paris';
    if (code >= 69001 && code <= 69009) return 'Lyon';
    if (code >= 13001 && code <= 13016) return 'Marseille';

    return null;
  }

  Future<void> _enforceRateLimit() async {
    if (_lastRequest != null) {
      final elapsed = DateTime.now().difference(_lastRequest!);
      if (elapsed < const Duration(seconds: 1)) {
        await Future<void>.delayed(
          Duration(milliseconds: 1000 - elapsed.inMilliseconds),
        );
      }
    }
  }
}
