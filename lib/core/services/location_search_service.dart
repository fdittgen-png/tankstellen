import 'dart:async';
import 'package:dio/dio.dart';
import '../cache/cache_manager.dart';
import '../constants/app_constants.dart';
import '../country/country_config.dart';
import '../services/service_result.dart';

/// A resolved location from user input (GPS, ZIP, or city search).
class ResolvedLocation {
  final String name;
  final double lat;
  final double lng;
  final String? postcode;

  const ResolvedLocation({
    required this.name,
    required this.lat,
    required this.lng,
    this.postcode,
  });
}

/// What kind of input the user typed.
enum LocationInputType { gps, zip, city }

/// Detects input type, searches cities via Nominatim with caching
/// and rate-limiting (1 req/sec per Nominatim policy).
class LocationSearchService {
  final CacheManager _cache;
  final Dio _dio;

  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  LocationSearchService(this._cache)
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'User-Agent': AppConstants.userAgent},
        ));

  /// Detect what the user entered: GPS (empty), ZIP (digits/postal pattern), or city (text).
  ///
  /// Uses the first characters to decide:
  /// - Empty → GPS
  /// - Starts with digit → ZIP (even partial, e.g. "750" while typing "75020")
  /// - Starts with letter → city name search
  /// - Matches country postal code regex → definitely ZIP
  LocationInputType detectInputType(String input, CountryConfig country) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return LocationInputType.gps;
    // If it matches the country's postal code regex exactly → ZIP
    if (RegExp(country.postalCodeRegex).hasMatch(trimmed)) {
      return LocationInputType.zip;
    }
    // If it starts with a digit → assume ZIP (user still typing)
    if (trimmed.codeUnitAt(0) >= 48 && trimmed.codeUnitAt(0) <= 57) {
      return LocationInputType.zip;
    }
    return LocationInputType.city;
  }

  /// Search cities via Nominatim. Results are cached for 30 minutes.
  /// Respects Nominatim 1 req/sec rate limit.
  Future<List<ResolvedLocation>> searchCities(
    String query, {
    List<String> countryCodes = const [],
  }) async {
    if (query.trim().length < 2) return [];

    final codes = countryCodes.isNotEmpty
        ? countryCodes.join(',')
        : Countries.all.map((c) => c.code.toLowerCase()).join(',');
    final cacheKey = CacheKey.citySearch(query, codes);

    // Check cache first
    final cached = _cache.getFresh(cacheKey);
    if (cached != null) {
      return _deserializeLocations(cached.payload);
    }

    // Rate limit: wait if <1s since last request
    final elapsed = DateTime.now().difference(_lastRequest);
    if (elapsed < const Duration(seconds: 1)) {
      await Future<void>.delayed(const Duration(seconds: 1) - elapsed);
    }
    _lastRequest = DateTime.now();

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'countrycodes': codes,
          'format': 'json',
          'limit': '8',
          'addressdetails': '1',
        },
      );

      if (response.data is! List) return [];

      final results = (response.data as List).map((r) {
        final addr = r['address'] as Map<String, dynamic>? ?? {};
        final name = r['display_name']?.toString() ?? '';
        final short = name.split(',').take(3).join(',').trim();
        return ResolvedLocation(
          name: short,
          lat: double.tryParse(r['lat']?.toString() ?? '') ?? 0,
          lng: double.tryParse(r['lon']?.toString() ?? '') ?? 0,
          postcode: addr['postcode']?.toString(),
        );
      }).toList();

      // Cache the results
      await _cache.put(
        cacheKey,
        _serializeLocations(results),
        ttl: CacheTtl.citySearch,
        source: ServiceSource.nominatimGeocoding,
      );

      return results;
    } on Exception {
      return [];
    }
  }

  Map<String, dynamic> _serializeLocations(List<ResolvedLocation> locs) => {
        'locations': locs
            .map((l) => {
                  'name': l.name,
                  'lat': l.lat,
                  'lng': l.lng,
                  'postcode': l.postcode,
                })
            .toList(),
      };

  List<ResolvedLocation> _deserializeLocations(Map<String, dynamic> data) {
    final list = data['locations'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((j) {
      final m = Map<String, dynamic>.from(j as Map);
      return ResolvedLocation(
        name: m['name'] as String? ?? '',
        lat: (m['lat'] as num?)?.toDouble() ?? 0,
        lng: (m['lng'] as num?)?.toDouble() ?? 0,
        postcode: m['postcode'] as String?,
      );
    }).toList();
  }
}
