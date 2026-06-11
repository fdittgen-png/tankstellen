// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Standard TTLs for each data type, defined centrally.
///
/// All cache durations are declared here so they can be reviewed and
/// adjusted in one place. Individual features must not define their own
/// TTLs -- use these constants via [CacheManager.put].
///
/// | Constant       | Duration   | Rationale                           |
/// |----------------|------------|-------------------------------------|
/// | stationSearch  | 5 min      | Prices change frequently            |
/// | stationDetail  | 15 min     | Opening hours change rarely         |
/// | prices         | 5 min      | Matches Tankerkoenig rate limit     |
/// | geocode        | 24 hours   | ZIP code coordinates are stable     |
/// | stationData    | 30 min     | Favorites offline view              |
/// | citySearch     | 30 min     | City name lookups are stable        |
///
/// ### Policy: these TTLs are intentionally compile-time
///
/// Every value below is a `const` baked in at build time. There is
/// deliberately **no** runtime or remote-config override: the durations are
/// tuned against the Tankerkoenig data contract (a 5-minute price update
/// cadence and rate limit) rather than against per-user preference, so a
/// tunable knob would mostly invite values that desync from upstream and
/// either over-fetch (hammering the rate limit) or serve stale prices.
/// Keeping them fixed also keeps the cache behaviour reproducible in tests.
///
/// This is a deliberate trade-off, not an oversight. If a future need arises
/// to A/B-test freshness or to react to upstream changes without an app
/// release, route these through a `RuntimeConfig` / remote-config layer that
/// supplies overrides while falling back to the constants below as defaults.
class CacheTtl {
  CacheTtl._();

  /// TTL for nearby-station search results (price + position list).
  ///
  /// 5 minutes because the underlying fuel prices change frequently and a
  /// search list is dominated by those prices; longer would surface stale
  /// figures, shorter would defeat the cache between back-to-back queries.
  /// Matches [prices] and the Tankerkoenig update cadence on purpose.
  static const Duration stationSearch = Duration(minutes: 5);

  /// TTL for a single station's detail payload (address, hours, brand).
  ///
  /// 15 minutes because detail data is mostly slow-changing metadata
  /// (opening hours, address) rather than live prices, so it tolerates a
  /// longer cache than a search list while still refreshing within a visit.
  static const Duration stationDetail = Duration(minutes: 15);

  /// TTL for a bulk price lookup keyed by station ids.
  ///
  /// 5 minutes to match the Tankerkoenig price-update cadence and rate
  /// limit: refreshing faster cannot yield newer data and risks tripping
  /// the upstream limit, refreshing slower serves stale prices.
  static const Duration prices = Duration(minutes: 5);

  /// TTL for forward/reverse geocode results (ZIP <-> coordinates).
  ///
  /// 24 hours because ZIP-code centroids and place coordinates are
  /// effectively static; caching for a day avoids repeated geocoder calls
  /// for the same query with no meaningful staleness risk.
  static const Duration geocode = Duration(hours: 24);

  /// TTL for a favourited station's cached snapshot (offline view).
  ///
  /// 30 minutes as a middle ground: long enough that opening the favourites
  /// list offline shows a recent snapshot, short enough that a returning
  /// online user re-fetches reasonably fresh prices.
  static const Duration stationData = Duration(minutes: 30);

  /// TTL for city-name autocomplete / lookup results.
  ///
  /// 30 minutes because city-name -> location mappings are stable; caching
  /// avoids re-querying the lookup service for the same typed prefix within
  /// a session without risking stale results.
  static const Duration citySearch = Duration(minutes: 30);
}

/// Generate consistent cache keys across all services.
///
/// All cache key construction goes through these static methods.
/// This prevents key collisions between services and enables
/// prefix-based invalidation if needed in the future.
///
/// Keys use a `type:param1:param2` format. Coordinates are rounded
/// to 3-4 decimal places to allow nearby queries to share cache entries
/// (3 decimals ~ 110m precision, 4 decimals ~ 11m precision).
class CacheKey {
  CacheKey._();

  /// Search-key coordinate rounding: 3 decimals ≈ 110 m, so two nearby
  /// queries share one cache entry. Public (#3157) so the widget
  /// foreground heartbeat can apply the SAME "has the user actually moved
  /// beyond the cache-key cell?" notion to its refresh gate.
  static String roundedSearchCoord(double v) => v.toStringAsFixed(3);

  static String stationSearch(
    double lat, double lng, double radius, String fuelType, {
    String countryCode = '',
    String? postalCode,
    String? locationName,
  }) {
    final base = 'search:$countryCode:${roundedSearchCoord(lat)}:${roundedSearchCoord(lng)}:$radius:$fuelType';
    // Include postal code / location name so different search inputs
    // always bypass cache even when coordinates round to the same key.
    if (postalCode != null && postalCode.isNotEmpty) return '$base:$postalCode';
    if (locationName != null && locationName.isNotEmpty) return '$base:$locationName';
    return base;
  }

  static String stationDetail(String id) => 'detail:$id';

  static String prices(List<String> ids) {
    final sorted = List<String>.from(ids)..sort();
    return 'prices:${sorted.join(',')}';
  }

  static String geocodeZip(String zip) => 'geo:zip:$zip';

  static String reverseGeocode(double lat, double lng) =>
      'geo:rev:${lat.toStringAsFixed(4)}:${lng.toStringAsFixed(4)}';

  static String stationData(String id) => 'station:$id';

  static String citySearch(String query, String countryCodes) =>
      'city:${query.toLowerCase().trim()}:$countryCodes';
}
