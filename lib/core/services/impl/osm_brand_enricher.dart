// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/storage_repository.dart';
import '../../storage/storage_providers.dart';
import '../../utils/geo_utils.dart' as geo;
import '../dio_factory.dart';
import '../../../features/search/domain/entities/brand_registry.dart';
import '../../domain/station.dart';
import '../../../core/logging/error_logger.dart';

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

  // Rate-limiting is handled by DioFactory's RateLimitInterceptor (#2315).
  static final _dio = DioFactory.create(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 10),
  );

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

      final response = await _dio.get<dynamic>(
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

      final pois = <OsmPoi>[];
      for (final r in results) {
        if (r is! Map) continue;
        final name = r['name']?.toString();
        final lat = double.tryParse(r['lat']?.toString() ?? '');
        final lng = double.tryParse(r['lon']?.toString() ?? '');
        if (name != null && name.isNotEmpty && lat != null && lng != null) {
          pois.add(OsmPoi(name, lat, lng));
        }
      }

      // Collect all writes first, then flush in one batched Future.wait
      // instead of N sequential awaits (#2315).
      final writes = <Future<void>>[];
      for (final s in stations) {
        // #2922 — defence-in-depth: never attribute a POI brand to a station
        // that already carries a real upstream brand (the loop is already
        // gated by _needsBrand, but a future caller must not be able to
        // overwrite a real brand from a neighbouring POI).
        if (!_needsBrand(s)) continue;
        final nearest = attributeBrandPoi(s.lat, s.lng, pois);
        if (nearest != null) {
          final sanitized = sanitizeOsmBrand(nearest.name);
          if (sanitized != null) {
            _sessionCache[s.id] = sanitized;
            writes.add(_storage.putSetting('brand_${s.id}', sanitized));
          }
        }
      }
      if (writes.isNotEmpty) await Future.wait(writes);
    } on DioException catch (e, st) { unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'OSM brand enrichment failed'})); }
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
    if (trimmed.isEmpty) return null;

    // Fast path: already a known canonical or alias. Runs BEFORE the
    // length floor below so legitimate 2-character brands like BP, IP,
    // OK, Q8 survive the validator. Previously this check came after
    // the length floor and rejected those as garbage (#481 follow-up).
    for (final entry in BrandRegistry.brandAliases.entries) {
      if (entry.key.toLowerCase() == trimmed.toLowerCase()) return trimmed;
      for (final alias in entry.value) {
        if (alias.toLowerCase() == trimmed.toLowerCase()) return trimmed;
      }
    }

    if (trimmed.length < 3) return null;

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

  /// Maximum distance (km) a fuel POI may sit from a station to be accepted as
  /// that station's brand source (#2922). Tightened from the historical 0.2 km
  /// to 0.08 km (~80 m): a real co-located fuel POI for a given station is
  /// within tens of metres, whereas 0.2 km routinely reached a *different*
  /// nearby station's POI (e.g. the adjacent "Super U" supermarket fuel point),
  /// stamping a phantom brand that then persisted in the cache.
  @visibleForTesting
  static const double maxAttributionKm = 0.08;

  /// Minimum separation (km) the nearest POI must have over the second-nearest
  /// for the attribution to be unambiguous (#2922). If two fuel POIs are within
  /// this margin of each other (both close to the station), there is no
  /// confident winner — attributing either risks the wrong brand, so the
  /// station is left for a later, clearer signal rather than guessed.
  @visibleForTesting
  static const double ambiguityMarginKm = 0.03;

  /// Picks the fuel [pois] entry that confidently belongs to the station at
  /// ([lat], [lng]), or null when no POI is close + unambiguous enough (#2922).
  ///
  /// A POI is accepted only when it is within [maxAttributionKm] AND the
  /// next-closest POI is at least [ambiguityMarginKm] farther away. This
  /// prevents a neighbouring supermarket's fuel POI from being stamped onto a
  /// different station — the regression that produced the phantom "Super U"
  /// brand. Pure + static so the regression test can drive it directly.
  @visibleForTesting
  static OsmPoi? attributeBrandPoi(double lat, double lng, List<OsmPoi> pois) {
    OsmPoi? nearest;
    var nearestDist = double.infinity;
    var secondDist = double.infinity;
    for (final poi in pois) {
      final d = _distKm(lat, lng, poi.lat, poi.lng);
      if (d < nearestDist) {
        secondDist = nearestDist;
        nearestDist = d;
        nearest = poi;
      } else if (d < secondDist) {
        secondDist = d;
      }
    }
    if (nearest == null || nearestDist > maxAttributionKm) return null;
    // Ambiguous: a second fuel POI sits within the margin → don't guess.
    if (secondDist - nearestDist < ambiguityMarginKm) return null;
    return nearest;
  }

  // #2169 — delegate to the canonical geo_utils.distanceKm rather than a
  // hand-rolled haversine. Real POI/station coords only, so the (0,0)
  // null-island short-circuit never triggers here.
  static double _distKm(double lat1, double lng1, double lat2, double lng2) =>
      geo.distanceKm(lat1, lng1, lat2, lng2);
}

/// A Nominatim fuel POI (name + coords) used to attribute a brand to a
/// station. Public so the #2922 attribution regression test can construct
/// fixtures and drive [OsmBrandEnricher.attributeBrandPoi] directly.
class OsmPoi {
  final String name;
  final double lat;
  final double lng;
  OsmPoi(this.name, this.lat, this.lng);
}
