import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'dio_factory.dart';

/// Enriches station brand data from OpenStreetMap via the Overpass API.
///
/// Queries for fuel stations within 50m of given coordinates and returns
/// the OSM `brand` tag if found. Uses an in-memory cache to avoid
/// redundant API calls (brands rarely change).
class OsmBrandEnricher {
  final Dio _dio;

  /// In-memory cache: coordinate key → brand name.
  final Map<String, String?> _cache = {};

  /// Overpass API endpoint (public, no auth required).
  static const _overpassUrl = 'https://overpass-api.de/api/interpreter';

  /// Search radius in meters.
  static const _radiusMeters = 50;

  OsmBrandEnricher({Dio? dio})
      : _dio = dio ??
            DioFactory.create(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            );

  /// Get the brand name for a fuel station at the given coordinates.
  ///
  /// Returns null if no fuel station is found within [_radiusMeters]
  /// or if the station has no brand tag.
  Future<String?> getBrand(double lat, double lng) async {
    final cacheKey = '${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}';

    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    try {
      final query = '[out:json][timeout:5];'
          'node["amenity"="fuel"](around:$_radiusMeters,$lat,$lng);'
          'out tags;';

      final response = await _dio.get(
        _overpassUrl,
        queryParameters: {'data': query},
      );

      if (response.statusCode != 200) {
        _cache[cacheKey] = null;
        return null;
      }

      final data = response.data;
      if (data is! Map) {
        _cache[cacheKey] = null;
        return null;
      }

      final elements = data['elements'] as List?;
      if (elements == null || elements.isEmpty) {
        _cache[cacheKey] = null;
        return null;
      }

      for (final element in elements) {
        if (element is Map) {
          final tags = element['tags'] as Map?;
          if (tags != null) {
            final brand = tags['brand']?.toString();
            if (brand != null && brand.isNotEmpty) {
              _cache[cacheKey] = brand;
              return brand;
            }
          }
        }
      }

      _cache[cacheKey] = null;
      return null;
    } catch (e, st) {
      debugPrint('OSM brand enrichment failed: $e\n$st');
      _cache[cacheKey] = null;
      return null;
    }
  }
}
