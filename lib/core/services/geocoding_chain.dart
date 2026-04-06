import 'package:dio/dio.dart';

import '../cache/cache_manager.dart';
import '../error/exceptions.dart';
import 'geocoding_provider.dart';
import 'service_result.dart';

/// Orchestrates geocoding with fallback chain:
///
///   1. Fresh cache (< TTL) → return immediately
///   2. Native geocoding (Android/iOS) → cache, return
///   3. Nominatim geocoding (all platforms) → cache, return
///   4. Stale cache (any age) → return with isStale=true
///   5. All failed → throw ServiceChainExhaustedException
///
/// Providers are tried in insertion order. Only [isAvailable] providers
/// are attempted. Errors from each step accumulate in the result.
class GeocodingChain {
  final List<GeocodingProvider> _providers;
  final CacheManager _cache;

  GeocodingChain(this._providers, this._cache);

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
        return ServiceResult(
          data: coords,
          source: fresh.originalSource,
          fetchedAt: fresh.storedAt,
        );
      }
    }

    // Step 2-3: Try each provider in order
    for (final provider in _providers) {
      if (!provider.isAvailable) continue;

      try {
        final coords = await provider.zipCodeToCoordinates(zipCode, cancelToken: cancelToken);
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
      if (coords != null) {
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

  ({double lat, double lng})? _deserializeCoords(Map<String, dynamic> data) {
    final lat = data['lat'];
    final lng = data['lng'];
    if (lat is num && lng is num) {
      return (lat: lat.toDouble(), lng: lng.toDouble());
    }
    return null;
  }
}
