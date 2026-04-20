import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/storage_repository.dart';
import '../services/service_result.dart';
import '../storage/storage_providers.dart';

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
class CacheTtl {
  CacheTtl._();
  static const Duration stationSearch = Duration(minutes: 5);
  static const Duration stationDetail = Duration(minutes: 15);
  static const Duration prices = Duration(minutes: 5);
  static const Duration geocode = Duration(hours: 24);
  static const Duration stationData = Duration(minutes: 30);
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
  @override
  Future<void> put(
    String key,
    Map<String, dynamic> data, {
    required Duration ttl,
    required ServiceSource source,
  }) async {
    await _storage.cacheData(key, {
      'payload': data,
      'storedAt': DateTime.now().millisecondsSinceEpoch,
      'source': source.index,
      'ttlMs': ttl.inMilliseconds,
    });
  }

  /// Retrieve cached data. Returns the entry even if expired —
  /// the caller (fallback chain) decides whether stale data is acceptable.
  /// Returns null only if the key was never cached.
  @override
  CacheEntry? get(String key) {
    final raw = _storage.getCachedData(key);
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
}
