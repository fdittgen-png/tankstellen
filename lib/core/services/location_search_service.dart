// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'package:dio/dio.dart';
import '../cache/cache_manager.dart';
import '../country/country_config.dart';
import '../utils/geo_utils.dart';
import 'dio_factory.dart';
import 'service_config.dart';
import '../services/service_result.dart';

/// A resolved location from user input (GPS, ZIP, or city search).
class ResolvedLocation {
  final String name;
  final double lat;
  final double lng;
  final String? postcode;

  /// Raw Nominatim discriminator fields, used to deduplicate the multiple
  /// admin-level entities Nominatim returns for one place (e.g. the
  /// "Barcelona" city node vs. its province boundary). All nullable so
  /// non-Nominatim / legacy-cached entries stay valid (#2639).
  final int? osmId;
  final double? importance;
  final int? placeRank;
  final String? addressType;

  /// Country of the place, captured from the raw entry's `address.country`
  /// (or the full display_name's last segment) before [name] is truncated to
  /// three segments — so the dedup country guard never compares a truncated
  /// label (#2639).
  final String? country;

  const ResolvedLocation({
    required this.name,
    required this.lat,
    required this.lng,
    this.postcode,
    this.osmId,
    this.importance,
    this.placeRank,
    this.addressType,
    this.country,
  });
}

/// What kind of input the user typed.
enum LocationInputType { gps, zip, city }

/// Detects input type, searches cities via Nominatim with caching.
///
/// Rate-limiting (1 req/sec per Nominatim policy) is handled by
/// [DioFactory.create]'s built-in [RateLimitInterceptor]. The former manual
/// `_lastRequest` / delay block has been removed to avoid double-gating (#2315).
class LocationSearchService {
  final CacheStrategy _cache;
  final Dio _dio;

  LocationSearchService(this._cache, {Dio? dio})
      : _dio = dio ?? DioFactory.create(
          baseUrl: ServiceConfigs.nominatim.baseUrl,
          connectTimeout: ServiceConfigs.nominatim.connectTimeout,
          receiveTimeout: ServiceConfigs.nominatim.receiveTimeout,
        );

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
    CancelToken? cancelToken,
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

    // Rate-limiting is handled by DioFactory's RateLimitInterceptor (#2315).
    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {
          'q': query,
          'countrycodes': codes,
          'format': 'json',
          'limit': '8',
          'addressdetails': '1',
          // Nominatim's own dedupe does NOT merge a city node with its
          // province boundary; the client-side _dedupe is the real fix
          // (#2639). Kept explicit for clarity.
          'dedupe': '1',
        },
        cancelToken: cancelToken,
      );

      if (response.data is! List) return [];

      final mapped = (response.data as List).map((r) {
        final addr = r['address'] as Map<String, dynamic>? ?? {};
        final name = r['display_name']?.toString() ?? '';
        final short = name.split(',').take(3).join(',').trim();
        // Capture the country from the FULL display_name before truncation —
        // the city node's truncated [name] drops it (#2639).
        final country = addr['country']?.toString() ??
            (name.contains(',') ? name.split(',').last.trim() : null);
        return ResolvedLocation(
          name: short,
          lat: double.tryParse(r['lat']?.toString() ?? '') ?? 0,
          lng: double.tryParse(r['lon']?.toString() ?? '') ?? 0,
          postcode: addr['postcode']?.toString(),
          osmId: (r['osm_id'] as num?)?.toInt(),
          importance: (r['importance'] as num?)?.toDouble(),
          placeRank: (r['place_rank'] as num?)?.toInt(),
          addressType: r['addresstype']?.toString(),
          country: country,
        );
      }).toList();

      final results = _dedupe(mapped);

      // Cache the deduped results so cached reads dedup-stably too.
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
                  'osmId': l.osmId,
                  'importance': l.importance,
                  'placeRank': l.placeRank,
                  'addressType': l.addressType,
                  'country': l.country,
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
        osmId: (m['osmId'] as num?)?.toInt(),
        importance: (m['importance'] as num?)?.toDouble(),
        placeRank: (m['placeRank'] as num?)?.toInt(),
        addressType: m['addressType'] as String?,
        country: m['country'] as String?,
      );
    }).toList();
  }

  /// Address types that represent an actual settlement a user means when they
  /// type a place name — these win over administrative/boundary entities.
  static const _settlementTypes = {'city', 'town', 'village', 'hamlet'};

  /// Radius within which a same-name, same-country entry is treated as a
  /// duplicate of the kept one. Wide enough to bind a city node to its
  /// province boundary (Barcelona: ~44 km) yet far below the separation of
  /// genuinely distinct same-country same-name places (Springfield IL↔MO:
  /// ~427 km), so those stay separate (#2639).
  static const _nearDuplicateKm = 50.0;

  /// Collapse the multiple admin-level entities Nominatim returns for one
  /// place into a single best entry (#2639).
  ///
  /// Two grouping rules:
  /// - **A — same `osmId`**: exact OSM identity, always one place.
  /// - **B — near-duplicate**: equal normalized first display-name token AND
  ///   equal country AND coordinates within [_nearDuplicateKm] of the kept
  ///   entry. This binds a city node to its province boundary (different
  ///   osmIds — Barcelona's are ~44 km apart, the boundary's representative
  ///   point sitting well outside the city centroid) while the distance +
  ///   country guards keep genuinely distinct same-name places apart
  ///   (Barcelona ES vs VE; same-country "Springfield"s are 100s of km apart).
  ///
  /// Within each group the *best* entry is kept (see [_isBetter]): a
  /// settlement type beats an administrative one, then higher importance,
  /// then lower placeRank.
  List<ResolvedLocation> _dedupe(List<ResolvedLocation> locs) {
    final kept = <ResolvedLocation>[];
    for (final loc in locs) {
      final idx = kept.indexWhere((k) => _sameGroup(k, loc));
      if (idx == -1) {
        kept.add(loc);
      } else if (_isBetter(loc, kept[idx])) {
        kept[idx] = loc;
      }
    }
    return kept;
  }

  bool _sameGroup(ResolvedLocation a, ResolvedLocation b) {
    // Group A — exact OSM identity.
    if (a.osmId != null && b.osmId != null && a.osmId == b.osmId) return true;
    // Group B — same first token + same country + within _nearDuplicateKm.
    if (_normToken(a.name) != _normToken(b.name)) return false;
    if (_country(a) != _country(b)) return false;
    return distanceKm(a.lat, a.lng, b.lat, b.lng) <= _nearDuplicateKm;
  }

  /// True if [a] should be preferred over [b] within a dedup group.
  bool _isBetter(ResolvedLocation a, ResolvedLocation b) {
    final aSettle = _settlementTypes.contains(a.addressType);
    final bSettle = _settlementTypes.contains(b.addressType);
    if (aSettle != bSettle) return aSettle;
    final ai = a.importance ?? 0;
    final bi = b.importance ?? 0;
    if (ai != bi) return ai > bi;
    final ar = a.placeRank ?? 1 << 30;
    final br = b.placeRank ?? 1 << 30;
    return ar < br;
  }

  /// First display-name segment, trimmed, lowercased, diacritics + punctuation
  /// stripped, so "Barcelonès" and "barcelones" compare equal.
  String _normToken(String name) {
    final first = name.split(',').first;
    final lower = first.trim().toLowerCase();
    final folded = _foldDiacritics(lower);
    return folded.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Normalized country of the place (#2639). Uses the captured [country]
  /// field; falls back to the (possibly truncated) name's last segment for
  /// legacy-cached entries that predate the field.
  String _country(ResolvedLocation l) {
    final raw = l.country ?? l.name.split(',').last;
    return _foldDiacritics(raw.trim().toLowerCase());
  }

  static const _diacriticsSrc = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
  static const _diacriticsDst = 'aaaaaaceeeeiiiinooooouuuuyy';

  String _foldDiacritics(String input) {
    final buf = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final i = _diacriticsSrc.indexOf(ch);
      buf.write(i == -1 ? ch : _diacriticsDst[i]);
    }
    return buf.toString();
  }

}
