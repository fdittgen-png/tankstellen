// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/storage_repository.dart';
import '../logging/error_logger.dart';
import '../services/service_result.dart';
import '../storage/storage_providers.dart';
import 'cache_eviction_policy.dart';

export 'cache_eviction_policy.dart' show CacheEvictionPolicy;

part 'cache_manager.g.dart';

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

  static String stationSearch(
    double lat, double lng, double radius, String fuelType, {
    String countryCode = '',
    String? postalCode,
    String? locationName,
  }) {
    final base = 'search:$countryCode:${lat.toStringAsFixed(3)}:${lng.toStringAsFixed(3)}:$radius:$fuelType';
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

/// A cached item with metadata about freshness and origin.
///
/// The [isExpired] getter checks whether the entry's age exceeds its TTL.
/// Note that expired entries are still returned by [CacheManager.get] --
/// the [StationServiceChain] decides whether stale data is acceptable
/// based on whether the API call succeeded.
class CacheEntry {
  final Map<String, dynamic> payload;
  final DateTime storedAt;
  final ServiceSource originalSource;
  final Duration ttl;

  CacheEntry({
    required this.payload,
    required this.storedAt,
    required this.originalSource,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().difference(storedAt) > ttl;
  Duration get age => DateTime.now().difference(storedAt);
}

@Riverpod(keepAlive: true)
CacheManager cacheManager(Ref ref) {
  return CacheManager(ref.watch(storageRepositoryProvider));
}

/// Minimal cache interface used by service chains ([StationServiceChain],
/// [GeocodingChain], [LocationSearchService]) to read and write cache
/// entries without depending on the concrete [CacheManager].
///
/// This enables unit-testing chains with a trivial in-memory fake instead
/// of requiring Hive infrastructure.
abstract interface class CacheStrategy {
  /// Store data with metadata envelope.
  Future<void> put(
    String key,
    Map<String, dynamic> data, {
    required Duration ttl,
    required ServiceSource source,
  });

  /// Retrieve cached data regardless of age. Returns null if never cached.
  CacheEntry? get(String key);

  /// Retrieve cached data only if not expired. Returns null on miss or expiry.
  CacheEntry? getFresh(String key);
}

/// Unified cache layer wrapping [CacheStorage].
///
/// All caching in the app goes through this class. Direct calls to
/// `CacheStorage.cacheData` are forbidden elsewhere in the codebase.
/// This ensures consistent TTL handling, key formatting, metadata
/// envelopes, and staleness semantics.
///
/// Each cached entry is stored as a JSON envelope containing:
/// - `payload` -- the serialized data
/// - `storedAt` -- milliseconds since epoch when data was cached
/// - `source` -- which [ServiceSource] originally provided the data
/// - `ttlMs` -- the TTL in milliseconds that applied at cache time
///
/// The two-tier retrieval strategy:
/// - [getFresh] -- returns data only if not expired (used as primary)
/// - [get] -- returns data regardless of age (used as stale fallback)
class CacheManager implements CacheStrategy {
  final CacheStorage _storage;

  CacheManager(this._storage);

  /// Store data in cache with metadata envelope.
  ///
  /// #2670 — a [FileSystemException] from a box closed mid-flight degrades to
  /// "not cached", never a throw on a routine API success (belt-and-braces;
  /// the store guard already no-ops a closed box).
  @override
  Future<void> put(
    String key,
    Map<String, dynamic> data, {
    required Duration ttl,
    required ServiceSource source,
  }) async {
    try {
      await _storage.cacheData(key, {
        'payload': data,
        'storedAt': DateTime.now().millisecondsSinceEpoch,
        'source': source.index,
        'ttlMs': ttl.inMilliseconds,
      });
    } on FileSystemException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: {'where': 'CacheManager.put (closed box)', 'key': key}));
    }
  }

  /// Retrieve cached data. Returns the entry even if expired —
  /// the caller (fallback chain) decides whether stale data is acceptable.
  /// Returns null only if the key was never cached (or the box is closed —
  /// #2670, a closed box reads as a clean miss so the chain falls through to
  /// the API / stale path instead of throwing).
  @override
  CacheEntry? get(String key) {
    final Map<String, dynamic>? raw;
    try {
      raw = _storage.getCachedData(key);
    } on FileSystemException catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: {'where': 'CacheManager.get (closed box)', 'key': key}));
      return null;
    }
    if (raw == null) return null;

    final payload = raw['payload'];
    if (payload == null) return null;

    return CacheEntry(
      payload: payload is Map ? Map<String, dynamic>.from(payload) : {},
      storedAt: DateTime.fromMillisecondsSinceEpoch(
        raw['storedAt'] as int? ?? 0,
      ),
      originalSource: ServiceSource.values.elementAtOrNull(
            raw['source'] as int? ?? 0,
          ) ??
          ServiceSource.cache,
      ttl: Duration(milliseconds: raw['ttlMs'] as int? ?? 300000),
    );
  }

  /// Get data only if the cache entry is still valid (not expired).
  @override
  CacheEntry? getFresh(String key) {
    final entry = get(key);
    if (entry == null || entry.isExpired) return null;
    return entry;
  }

  /// Remove a specific cache entry.
  Future<void> invalidate(String key) async {
    await _storage.cacheData(key, null);
  }

  /// Clear all cached data.
  Future<void> clearAll() async {
    await _storage.clearCache();
  }

  /// Number of entries currently in cache.
  int get entryCount => _storage.cacheEntryCount;

  /// Evict cache entries that are older than 3x their TTL.
  /// Processes at most [batchLimit] entries per call to avoid blocking.
  /// Returns the number of evicted entries.
  Future<int> evictExpired({int batchLimit = 500}) async {
    final keys = _storage.cacheKeys.take(batchLimit).toList();
    var evicted = 0;
    for (final key in keys) {
      if (key is! String) continue;
      final entry = get(key);
      if (entry == null) continue;
      // Evict if age exceeds 3x TTL
      if (entry.age > entry.ttl * 3) {
        await _storage.deleteCacheEntry(key);
        evicted++;
      }
    }
    return evicted;
  }

  /// #2264 — bounded periodic eviction, replacing the one-shot startup
  /// 500-key cap. Three passes, cheapest first: (1) expiry (> 3x TTL);
  /// (2) per-prefix budget — keep the newest [CacheEvictionPolicy.prefixBudget]
  /// entries per `type:` prefix, so one noisy prefix can't starve the rest;
  /// (3) global LRU byte ceiling — if total payload size still exceeds
  /// [CacheEvictionPolicy.maxBytes], evict oldest-first by `storedAt` until
  /// under it. Persisted `dataset:` entries (the offline backbone) are exempt
  /// from the byte sweep but still obey their prefix budget. Returns the
  /// number of evicted entries; idempotent.
  Future<int> evictBounded({CacheEvictionPolicy policy = const CacheEvictionPolicy()}) async {
    var evicted = 0;

    // Snapshot the entries once: (key, entry).
    final entries = <MapEntry<String, CacheEntry>>[];
    for (final raw in _storage.cacheKeys.toList()) {
      if (raw is! String) continue;
      final entry = get(raw);
      if (entry == null) continue;
      entries.add(MapEntry(raw, entry));
    }

    // Pass 1 — expiry (> 3x TTL).
    final survivors = <MapEntry<String, CacheEntry>>[];
    for (final e in entries) {
      if (e.value.age > e.value.ttl * 3) {
        await _storage.deleteCacheEntry(e.key);
        evicted++;
      } else {
        survivors.add(e);
      }
    }

    // Pass 2 — per-prefix budget (keep newest, evict oldest beyond budget).
    final byPrefix = <String, List<MapEntry<String, CacheEntry>>>{};
    for (final e in survivors) {
      byPrefix.putIfAbsent(_prefixOf(e.key), () => []).add(e);
    }
    final budgeted = <MapEntry<String, CacheEntry>>[];
    for (final group in byPrefix.values) {
      group.sort((a, b) => b.value.storedAt.compareTo(a.value.storedAt));
      for (var i = 0; i < group.length; i++) {
        if (i < policy.prefixBudget) {
          budgeted.add(group[i]);
        } else {
          await _storage.deleteCacheEntry(group[i].key);
          evicted++;
        }
      }
    }

    // Pass 3 — global LRU byte ceiling (dataset: entries are protected).
    var totalBytes = budgeted.fold<int>(0, (sum, e) => sum + _approxBytes(e.value));
    if (totalBytes > policy.maxBytes) {
      final evictable = budgeted
          .where((e) => !e.key.startsWith('dataset:'))
          .toList()
        ..sort((a, b) => a.value.storedAt.compareTo(b.value.storedAt));
      for (final e in evictable) {
        if (totalBytes <= policy.maxBytes) break;
        await _storage.deleteCacheEntry(e.key);
        totalBytes -= _approxBytes(e.value);
        evicted++;
      }
    }

    return evicted;
  }

  /// The `type:` prefix of a cache key (everything up to and including the
  /// first colon), or the whole key when it carries no colon.
  static String _prefixOf(String key) {
    final i = key.indexOf(':');
    return i < 0 ? key : key.substring(0, i + 1);
  }

  /// Cheap byte estimate for an entry — the length of its JSON-encoded
  /// payload. Avoids re-encoding the Hive envelope; good enough to drive the
  /// LRU ceiling.
  static int _approxBytes(CacheEntry entry) {
    try {
      return jsonEncode(entry.payload).length;
    } on Object {
      return 0;
    }
  }
}
