import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../cache/cache_manager.dart';
import '../country/country_bounding_box.dart';
import '../error/exceptions.dart';
import 'geocoding_provider.dart';
import 'service_result.dart';

/// Orchestrates geocoding with fallback chain:
///
///   1. Fresh cache (< TTL) → validate against country bbox → return
///   2. Native geocoding (Android/iOS) → validate → cache, return
///   3. Nominatim geocoding (all platforms) → validate → cache, return
///   4. Stale cache (any age) → validate → return with isStale=true
///   5. All failed → throw ServiceChainExhaustedException
///
/// Providers are tried in insertion order. Only [isAvailable] providers
/// are attempted. Errors from each step accumulate in the result.
///
/// When [countryCode] is provided, coordinates are validated against the
/// country's bounding box. Results outside the expected country are
/// rejected and the next provider is tried.
class GeocodingChain {
  final List<GeocodingProvider> _providers;
  final CacheManager _cache;
  final String? _countryCode;

  GeocodingChain(this._providers, this._cache, {String? countryCode})
      : _countryCode = countryCode?.toUpperCase();

  Future<ServiceResult<({double lat, double lng})>> zipCodeToCoordinates(
    String zipCode, {
    CancelToken? cancelToken,
  }) async {
    final cacheKey = CacheKey.geocodeZip(zipCode);
    final errors = <ServiceError>[];

    // Step 1: Fresh cache
    final fresh = _cache.getFresh(cacheKey);
    if (fresh != null) {
      final coords = _deserializeCoords(fresh.payload);
      if (coords != null) {
        if (_isWithinCountryBounds(coords.lat, coords.lng)) {
          return ServiceResult(
            data: coords,
            source: fresh.originalSource,
            fetchedAt: fresh.storedAt,
          );
        }
        // Cached coords are outside expected country — skip cache, re-geocode
        debugPrint(
          'GeocodingChain: cached coords (${coords.lat}, ${coords.lng}) '
          'outside $_countryCode bounds, re-geocoding $zipCode',
        );
      }
    }

    // Step 2-3: Try each provider in order
    for (final provider in _providers) {
      if (!provider.isAvailable) continue;

      try {
        final coords = await provider.zipCodeToCoordinates(zipCode, cancelToken: cancelToken);

        // Validate coordinates against country bounding box
        if (!_isWithinCountryBounds(coords.lat, coords.lng)) {
          final bbox = _countryCode != null
              ? countryBoundingBoxes[_countryCode]
              : null;
          final errorMsg =
              'Geocoded coordinates (${coords.lat}, ${coords.lng}) for '
              'postal code $zipCode are outside $_countryCode bounds '
              '($bbox). Trying next provider.';
          debugPrint('GeocodingChain: $errorMsg');
          errors.add(ServiceError(
            source: provider.source,
            message: errorMsg,
            occurredAt: DateTime.now(),
          ));
          continue;
        }

        final result = ServiceResult(
          data: coords,
          source: provider.source,
          fetchedAt: DateTime.now(),
          errors: errors,
        );

        // Cache on success
        await _cache.put(
          cacheKey,
          {'lat': coords.lat, 'lng': coords.lng},
          ttl: CacheTtl.geocode,
          source: provider.source,
        );

        return result;
      } catch (e) {
        errors.add(ServiceError(
          source: provider.source,
          message: e.toString(),
          occurredAt: DateTime.now(),
        ));
      }
    }

    // Step 4: Stale cache
    final stale = _cache.get(cacheKey);
    if (stale != null) {
      final coords = _deserializeCoords(stale.payload);
      if (coords != null && _isWithinCountryBounds(coords.lat, coords.lng)) {
        return ServiceResult(
          data: coords,
          source: ServiceSource.cache,
          fetchedAt: stale.storedAt,
          isStale: true,
          errors: errors,
        );
      }
    }

    // Step 5: Everything failed
    throw ServiceChainExhaustedException(errors: errors);
  }

  Future<ServiceResult<String>> coordinatesToAddress(
    double lat, double lng, {
    CancelToken? cancelToken,
  }) async {
    final cacheKey = CacheKey.reverseGeocode(lat, lng);
    final errors = <ServiceError>[];

    // Fresh cache
    final fresh = _cache.getFresh(cacheKey);
    if (fresh != null && fresh.payload['address'] is String) {
      return ServiceResult(
        data: fresh.payload['address'] as String,
        source: fresh.originalSource,
        fetchedAt: fresh.storedAt,
      );
    }

    // Try providers
    for (final provider in _providers) {
      if (!provider.isAvailable) continue;

      try {
        final address = await provider.coordinatesToAddress(lat, lng, cancelToken: cancelToken);
        await _cache.put(
          cacheKey,
          {'address': address},
          ttl: CacheTtl.geocode,
          source: provider.source,
        );
        return ServiceResult(
          data: address,
          source: provider.source,
          fetchedAt: DateTime.now(),
          errors: errors,
        );
      } catch (e) {
        errors.add(ServiceError(
          source: provider.source,
          message: e.toString(),
          occurredAt: DateTime.now(),
        ));
      }
    }

    // Stale cache
    final stale = _cache.get(cacheKey);
    if (stale != null && stale.payload['address'] is String) {
      return ServiceResult(
        data: stale.payload['address'] as String,
        source: ServiceSource.cache,
        fetchedAt: stale.storedAt,
        isStale: true,
        errors: errors,
      );
    }

    // Fallback: return raw coordinates as string
    return ServiceResult(
      data: '$lat, $lng',
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
      isStale: true,
      errors: errors,
    );
  }

  /// Reverse-geocode coordinates to an ISO country code.
  /// Tries providers in order, returns first non-null result.
  Future<String?> coordinatesToCountryCode(
    double lat, double lng, {
    CancelToken? cancelToken,
  }) async {
    // Check cache first
    final cacheKey = 'country:${lat.toStringAsFixed(2)}:${lng.toStringAsFixed(2)}';
    final fresh = _cache.getFresh(cacheKey);
    if (fresh != null && fresh.payload['countryCode'] is String) {
      return fresh.payload['countryCode'] as String;
    }

    for (final provider in _providers) {
      if (!provider.isAvailable) continue;
      final code = await provider.coordinatesToCountryCode(lat, lng, cancelToken: cancelToken);
      if (code != null) {
        await _cache.put(
          cacheKey,
          {'countryCode': code},
          ttl: CacheTtl.geocode,
          source: provider.source,
        );
        return code;
      }
    }
    return null;
  }

  /// Check if coordinates are within the expected country's bounding box.
  /// Returns true if no country code is set (validation disabled).
  bool _isWithinCountryBounds(double lat, double lng) {
    if (_countryCode == null) return true;
    final bbox = countryBoundingBoxes[_countryCode];
    if (bbox == null) return true; // Unknown country — skip validation
    return bbox.contains(lat, lng);
  }

  ({double lat, double lng})? _deserializeCoords(Map<String, dynamic> data) {
    final lat = data['lat'];
    final lng = data['lng'];
    if (lat is num && lng is num) {
      return (lat: lat.toDouble(), lng: lng.toDouble());
    }
    return null;
  }
}
