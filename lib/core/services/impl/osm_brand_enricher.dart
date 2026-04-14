import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/storage_repository.dart';
import '../../storage/storage_providers.dart';
import '../dio_factory.dart';
import '../../../features/search/domain/entities/brand_registry.dart';
import '../../../features/search/domain/entities/station.dart';

part 'osm_brand_enricher.g.dart';

@Riverpod(keepAlive: true)
OsmBrandEnricher osmBrandEnricher(Ref ref) {
  return OsmBrandEnricher(ref.watch(storageRepositoryProvider));
}

/// Enriches fuel stations with brand names using Nominatim search.
/// Brands are cached persistently for instant lookup.
class OsmBrandEnricher {
  final SettingsStorage _storage;
  final Map<String, String> _sessionCache = {};

  OsmBrandEnricher(this._storage);

  static final _dio = DioFactory.create(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
  );

  static DateTime? _lastRequest;

  Future<List<Station>> enrich(
    List<Station> stations, {
    CancelToken? cancelToken,
  }) async {
    if (stations.isEmpty) return stations;

    var result = _applyCachedBrands(stations);

    final uncached = result.where(_needsBrand).toList();
    if (uncached.isEmpty) return result;

    await _fetchBrandsFromNominatim(stations, cancelToken: cancelToken);
    result = _applyCachedBrands(result);

    return result;
  }

  bool _needsBrand(Station s) =>
      s.brand.isEmpty ||
      s.brand == 'Station' || // legacy value from before #482
      s.brand == BrandRegistry.independentLabel ||
      s.brand == 'Autoroute';

  Future<void> _fetchBrandsFromNominatim(
    List<Station> stations, {
    CancelToken? cancelToken,
  }) async {
    if (_lastRequest != null) {
      final elapsed = DateTime.now().difference(_lastRequest!);
      if (elapsed < const Duration(seconds: 2)) {
        await Future<void>.delayed(
          Duration(milliseconds: 2000 - elapsed.inMilliseconds),
        );
      }
    }

    try {
      double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
      for (final s in stations) {
        if (s.lat < minLat) minLat = s.lat;
        if (s.lat > maxLat) maxLat = s.lat;
        if (s.lng < minLng) minLng = s.lng;
        if (s.lng > maxLng) maxLng = s.lng;
      }
      minLat -= 0.01; maxLat += 0.01;
      minLng -= 0.01; maxLng += 0.01;

      _lastRequest = DateTime.now();

      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'format': 'json',
          'limit': 50,
          'amenity': 'fuel',
          'viewbox': '$minLng,$minLat,$maxLng,$maxLat',
          'bounded': '1',
        },
        cancelToken: cancelToken,
      );

      final results = response.data;
      if (results is! List) return;

      final pois = <_Poi>[];
      for (final r in results) {
        if (r is! Map) continue;
        final name = r['name']?.toString();
        final lat = double.tryParse(r['lat']?.toString() ?? '');
        final lng = double.tryParse(r['lon']?.toString() ?? '');
        if (name != null && name.isNotEmpty && lat != null && lng != null) {
          pois.add(_Poi(name, lat, lng));
        }
      }

      for (final s in stations) {
        if (!_needsBrand(s)) continue;
        _Poi? nearest;
        double nearestDist = 0.2;
        for (final poi in pois) {
          final d = _distKm(s.lat, s.lng, poi.lat, poi.lng);
          if (d < nearestDist) {
            nearestDist = d;
            nearest = poi;
          }
        }
        if (nearest != null) {
          final sanitized = sanitizeOsmBrand(nearest.name);
          if (sanitized != null) {
            _sessionCache[s.id] = sanitized;
            await _storage.putSetting('brand_${s.id}', sanitized);
          }
        }
      }
    } on DioException catch (e) { debugPrint('OSM brand enrichment failed: $e'); }
  }

  List<Station> _applyCachedBrands(List<Station> stations) {
    return stations.map((s) {
      if (!_needsBrand(s)) return s;
      final cached = _sessionCache[s.id];
      if (cached != null) return s.copyWith(brand: cached);
      final persisted = _storage.getSetting('brand_${s.id}');
      if (persisted is String) {
        // Validate on read — anything that fails sanitisation (empty,
        // too short, "ff", phone-number-looking, etc.) is treated as
        // a cache miss and the station will be re-enriched. This
        // evicts any historically-poisoned entries that predate the
        // #481 fix without needing a full-cache migration pass.
        final sanitized = sanitizeOsmBrand(persisted);
        if (sanitized != null) {
          _sessionCache[s.id] = sanitized;
          return s.copyWith(brand: sanitized);
        }
      }
      return s;
    }).toList();
  }

  /// Validates an OSM `name` field before it is cached as a station
  /// brand. Rejects implausible / garbage values that would otherwise
  /// leak into the brand filter chip strip as mystery labels (#481).
  ///
  /// A brand string is accepted if it:
  ///   * trims to at least 3 characters
  ///   * contains at least one letter
  ///   * is not obviously non-brand noise (lat/lng, phone number,
  ///     opening-hours string)
  ///   * OR is already a known canonical brand or alias in
  ///     `BrandRegistry.brandAliases`
  ///
  /// Returns the trimmed brand if it passes, `null` otherwise. Exposed
  /// as a static helper so the regression tests can exercise the
  /// validator directly without spinning up a full enricher.
  static String? sanitizeOsmBrand(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length < 3) return null;

    // Fast path: already a known canonical or alias. No further
    // sanity checks — we already trust the registry.
    for (final entry in BrandRegistry.brandAliases.entries) {
      if (entry.key.toLowerCase() == trimmed.toLowerCase()) return trimmed;
      for (final alias in entry.value) {
        if (alias.toLowerCase() == trimmed.toLowerCase()) return trimmed;
      }
    }

    // Must contain at least one letter. "1234" / "+33 4 67 ..." → reject.
    if (!RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿ]').hasMatch(trimmed)) return null;

    // Must not look like a phone number or coordinate string.
    if (RegExp(r'^\+?\d[\d\s().-]{6,}$').hasMatch(trimmed)) return null;

    // Must not look like a time range ("08:00-20:00", "Mo-Fr 08:00 ...").
    if (RegExp(r'\d{1,2}:\d{2}').hasMatch(trimmed)) return null;

    // Reject runs of only punctuation / whitespace / very repetitive
    // short tokens — "ff", "xx", "??", "...".
    final letters = trimmed.replaceAll(RegExp(r'[^A-Za-zÀ-ÖØ-öø-ÿ]'), '');
    if (letters.length < 3) return null;

    return trimmed;
  }

  static double _distKm(double lat1, double lng1, double lat2, double lng2) {
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLng / 2) * sin(dLng / 2);
    return 6371 * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}

class _Poi {
  final String name;
  final double lat;
  final double lng;
  _Poi(this.name, this.lat, this.lng);
}
