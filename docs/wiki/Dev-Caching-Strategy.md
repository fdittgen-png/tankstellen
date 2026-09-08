# Caching Strategy

Every API call in the app goes through `CacheManager`. Direct `HiveStorage.cacheData()` calls are banned — they skip TTL management and source tagging.

## `CacheManager` API

`lib/core/cache/cache_manager.dart:142–226`

```dart
Future<void> put(String key, dynamic data, {required Duration ttl, ServiceSource source});
CacheEntry? get(String key);          // returns even expired entries
CacheEntry? getFresh(String key);     // returns only if !expired
Future<void> invalidate(String key);
Future<void> clearAll();
Future<void> evictExpired({int batchLimit = 200});
```

`CacheEntry` envelope:

```dart
class CacheEntry {
  final dynamic payload;
  final DateTime storedAt;
  final ServiceSource source;
  final Duration ttl;
  bool get isExpired => DateTime.now().difference(storedAt) > ttl;
}
```

## TTLs

Defined centrally in `CacheTtl` (`cache_manager.dart:22–30`):

| Namespace | TTL | Reason |
|---|---|---|
| `stationSearch` | 5 min | Tankerkoenig terms of use min 5 min |
| `stationDetail` | 15 min | Detail rarely changes within a session |
| `prices` | 5 min | Same as search |
| `geocode` | 24 h | Coords are stable |
| `stationData` | 30 min | Amenities, brand, address — very stable |
| `citySearch` | 30 min | Suggestions cache |

## Cache key strategy

`CacheKey` factory (`cache_manager.dart:41–74`) builds `type:param1:param2:…` strings.

Coordinates are **rounded** before keying to prevent key explosion:

- Search: **3 decimals** (~110 m) — good enough for "nearby" quality
- Reverse geocode: **4 decimals** (~11 m) — finer because addresses differ within 110 m

Postal code / city name is included in the key so that searches that happen to round to the same coord still cache separately:

```dart
// e.g. a Nominatim lookup of "Paris" vs a GPS fix of 48.857,2.352 both
// produce search keys in the same area, but the logical intent is distinct
'search:FR:48.857:2.352:10:diesel:paris'
'search:FR:48.857:2.352:10:diesel:-'     // GPS (no city)
```

## Eviction

Lazy: `evictExpired()` is called by a background `Timer.periodic(30 min)` started at app init. It walks up to `batchLimit` entries older than `3 × ttl` and deletes them. The 3× factor keeps stale fallbacks available after the chain's primary TTL has expired but before they are purged.

## Storage backend

`CacheManager` delegates to a `CacheStrategy` interface (line 110). The real implementation is Hive (`HiveStorage` box `cache`, encrypted, AES from FlutterSecureStorage).

Each entry is JSON: `{ payload, storedAt, source, ttlMs }`. Payload serialisation is the caller's responsibility — for freezed DTOs use `.toJson()` before `put` and `.fromJson(map)` after `get`.

## Shapes that live in the cache

| Type | TTL | Comment |
|---|---|---|
| `List<Station>` (search results) | 5 min | Per-country, per-fuel, per-radius |
| `Station` (detail) | 15 min | Stand-alone by ID |
| `Map<fuelType, double>` (prices) | 5 min | Only when separately re-fetched |
| `Coordinate` (geocode) | 24 h | Postcode → coord |
| `String` (reverse geocode) | 24 h | Coord → city name |

## Request coalescing vs caching

They are complementary but different:

- **Cache** answers "I fetched this recently, reuse the answer".
- **Coalescing** answers "I'm fetching this right now, don't start again".

The `StationServiceChain` combines both: cache-first, then coalesced in-flight de-dup, then API call.

## Conventions

- Always use `CacheManager` — never raw Hive for cached API data.
- Always tag `source` (used for debug surfacing and staleness badges).
- Never invent a new TTL — add it to `CacheTtl` constants.
- Key design: lower-case, colon-separated, rounded coordinates, always include country code first.
- After a country switch, the shell listener calls `cache.clearAll()` for the station/search/geocode namespaces. Profile-unrelated caches (assets, OSM tiles) are untouched.

## Related

- [Service Layer & Fallback](Dev-Service-Layer-Fallback) — how the cache integrates with the chain
- [Storage & Sync](Dev-Storage-Hive-Sync) — the Hive box map
