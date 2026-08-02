**06 · Data**

# Caching

> The cache is not an optimisation. In a local-first app it is the offline story, the rate-limit story and the resilience story at once — which is why the interesting design decision is not "how long do we keep things" but "who decides that stale is acceptable".

**Chunk prefix** cache **Updated** 2026-08-01 **Depends on** 01 Foundations

#### On this page

1. [Three tiers, and who chooses](#tiers)
1. [The cache seam](#seam)
1. [TTLs as named constants](#ttl)
1. [Cache-key design](#keys)
1. [Schema-versioned invalidation](#schema)
1. [Eviction that preserves stale fallback](#eviction)
1. [Request coalescing and rate limiting](#coalescing)
1. [Invalidation on mutation](#invalidation)
1. [Testing a cache](#testing)

<!-- chunk: cache.tiers | tags: caching,architecture,staleness -->

## Three tiers, and who chooses

A cache entry is in one of three states — fresh, stale, or absent — and **the caller decides whether stale is acceptable**, not the cache.

| Tier | Condition | Served when |
| --- | --- | --- |
| **Fresh** | `age ≤ ttl` | Always. No network call. |
| **Stale** | `age > ttl`, entry still present | The network attempt failed. Served with `isStale: true`. |
| **Miss** | Never cached, or evicted | Nothing to serve — the chain exhausts and throws. |

The consequence of putting the decision in the caller: `get()` returns the entry *regardless of age*, and exposes `isExpired` as a property. A cache API whose `get()` returns null for an expired entry has thrown away the offline fallback before the caller could ask for it.

```dart
class CacheEntry {
  const CacheEntry({required this.payload, required this.storedAt, required this.ttl});

  /// JSON-safe RAW data — server rows or row bundles, never parsed
  /// domain objects. See the schema-version section for why.
  final Object? payload;
  final DateTime storedAt;
  final Duration ttl;

  Duration get age => DateTime.now().difference(storedAt);
  bool get isExpired => age > ttl;
}
```

> **[RULE]**

> **Cache raw payloads, not parsed domain objects.** Store the server rows. Parsing on read costs microseconds and buys two things: the cache format does not change when a model gains a field, and a parser change cannot corrupt stored data — it can only fail to read it, which is detectable. Caching parsed objects makes every model refactor a data migration.

<!-- chunk: cache.seam | tags: caching,testing,abstraction -->

## The cache seam

Repositories read and write through an abstract store, so a widget test injects an in-memory implementation without touching the disk.

```dart
abstract class CacheStore {
  /// The entry regardless of age — null only when never cached or
  /// unreadable. Staleness is the CALLER's decision.
  Future<CacheEntry?> get(String key);

  Future<void> put(String key, Object? payload, {required Duration ttl});

  /// Drops every entry whose key starts with [prefix] — the mutation
  /// invalidation primitive.
  Future<void> evictPrefix(String prefix);

  Future<void> evictExpired();
}
```

> **[RULE]**

> **Never write API responses to the raw key-value store directly.** Everything goes through the cache manager. A direct `storage.put('some_response', json)` bypasses TTLs, bypasses schema versioning, bypasses eviction, and will be forgotten during the next invalidation change. Both source projects ban this explicitly; one enforces it with a scanning test.

The seam also gives you the one thing a filesystem-backed cache otherwise makes painful: deterministic tests. An in-memory fake with an injectable clock lets you assert fresh-hit, stale-hit and miss behaviour without `Future.delayed` anywhere.

<!-- chunk: cache.ttl | tags: caching,ttl,configuration -->

## TTLs as named constants

Every TTL is a named constant in one place, chosen from the data's real update cadence — never invented inline at a call site.

```dart
abstract final class CacheTtl {
  /// Prices refresh upstream roughly every 5 minutes.
  static const prices = Duration(minutes: 5);

  /// Station locations. Forecourts do not move; an hour is conservative.
  static const stationLocations = Duration(hours: 1);

  /// Geocoding results for a typed query.
  static const geocode = Duration(days: 7);

  /// Route geometry between two fixed points.
  static const route = Duration(hours: 6);

  /// Reference data shipped by the backend (plans, categories, tariffs).
  static const referenceData = Duration(hours: 12);
}
```

> **[WHY]**

> An inline `Duration(minutes: 5)` at a call site is invisible. When the upstream cadence changes, or when you need to reason about total network volume, you cannot find the values — and you will find *different* values for the same data reached through two paths. A named constant makes the policy reviewable in one screen.

Derive the TTL from the source, and write the derivation in the comment. A source that publishes a daily bulk file should not be polled every five minutes; a source that updates every five minutes should not be cached for an hour. Both projects annotate each country or source with its observed cadence for exactly this reason.

> **[RULE]**

> **Separate the cadence of *identity* data from *value* data.** Station locations change essentially never; their prices change hourly. Caching them together at the shorter TTL multiplies network volume for no benefit. One project's radar feature caches a wide-area location corridor for an hour and fetches prices just-in-time only for the handful of imminent candidates — which is what makes a continuous background scan affordable.

<!-- chunk: cache.keys | tags: caching,keys,design -->

## Cache-key design

A key must contain every input that changes the answer, and nothing that does not — and continuous inputs must be quantised or the hit rate collapses.

```text
<type>:<scope>:<rounded-coords>:<radius>:<variant>:<extra>

search:fr:43.611,3.877:10:e10:—
geocode:fr:—:—:—:34000+montpellier
route:—:43.6110,3.8770|43.2965,5.3698:—:—:—
```

| Component | Rule |
| --- | --- |
| **Coordinates** | Round. 3 decimals ≈ 110 m for a search radius; 4 decimals ≈ 11 m for geocoding. Unrounded coordinates give a 0% hit rate because no two GPS fixes are identical. |
| **Scope** | Country, workspace, tenant — whatever partitions the data. It is also the prefix you will evict on. |
| **Variant** | Anything that changes the response: fuel grade, language, unit system, filter set. |
| **Order** | Most-general to most-specific, so prefix eviction works at every level. |
| **Never include** | A timestamp, a request id, a session token, or a user id that does not change the payload. Each makes every key unique. |

> **[TRAP]**

> **Symptom: the cache appears to work in tests and never hits in production.** The usual cause is an unrounded continuous value in the key — a raw GPS coordinate, a millisecond timestamp, a floating-point radius. Tests pass because they use fixed inputs. Instrument the hit rate in a debug build and look at it once; a cache with a near-zero hit rate is worse than no cache, because it pays the write cost too.

> **[CHECK]**

> Write a test that builds the same logical request twice from two slightly-different inputs (GPS fixes 3 m apart) and asserts the keys are equal. Then one that builds two logically-different requests (different fuel grade) and asserts they differ. Those two tests catch nearly every key bug.

<!-- chunk: cache.schema | tags: caching,invalidation,versioning -->

## Schema-versioned invalidation

A manually-bumped schema version turns every cached entry written under the old shape into a miss.

```dart
/// Entries written under a different schema version are treated as misses:
/// cached payloads are RAW server rows, so a build that changed a row
/// parser's expectations must re-fetch rather than feed old-shaped rows to
/// new code. Bump this when a cached row shape changes.
const int cacheSchemaVersion = 1;
```

Store the version with the entry and compare on read; a mismatch is a miss.

> **[WHY]**

> Keying on the build number invalidates the entire cache on every release, which throws away the offline story for anyone who updates while on a train. Row shapes only break on *deliberate* changes, so a manual bump is both sufficient and far cheaper. The cost is remembering to bump it — mitigate that by putting the constant directly above the parser it protects, and mentioning it in the pull-request checklist for any change to a cached model.

> **[TRAP]**

> **Symptom: after an update, a subset of users see crashes or empty screens that nobody can reproduce on a fresh install.** Old-shaped rows being fed to a new parser. It is invisible in testing because test devices are usually freshly installed or have their storage cleared. Whenever you change a parsed shape, ask: is this shape cached? If yes, bump. If you cannot tell, bump anyway — the cost is one refetch.

<!-- chunk: cache.eviction | tags: caching,eviction,memory -->

## Eviction that preserves stale fallback

Do not evict at the TTL. Evict at a multiple of it, or you destroy the stale tier the moment it becomes useful.

The reasoning is direct: the stale tier exists to serve a request when the network fails. An eviction sweep that removes everything older than its TTL guarantees that nothing is ever available to the stale tier — the entry is deleted at exactly the moment it stops being fresh.

```dart
/// Runs on a 30-minute periodic timer. Only removes entries older than
/// 3 × their own TTL, so a recently-expired entry remains available as
/// the stale fallback when the network is down.
Future<void> evictExpired() async {
  final now = DateTime.now();
  for (final key in await _keys()) {
    final e = await get(key);
    if (e == null) continue;
    if (now.difference(e.storedAt) > e.ttl * 3) {
      await _remove(key);
    }
  }
}
```

| Parameter | Typical | Trade-off |
| --- | --- | --- |
| Sweep interval | 30 minutes | Shorter wastes CPU; longer lets a burst of writes accumulate before the first cleanup |
| Retention multiple | 3 × ttl | Lower shortens the offline window; higher grows the store. Tune per entry class if one dominates size. |
| Size ceiling | Optional | If a payload class can be large (map tiles, images), add a byte budget with least-recently-used eviction on top of the age rule |

> **[CHECK]**

> The test that matters: write an entry, advance the injected clock past its TTL but under the retention multiple, simulate a network failure, and assert the stale entry is still served with `isStale: true`. If that test passes, the eviction policy is correct.

<!-- chunk: cache.coalescing | tags: caching,concurrency,rate-limiting -->

## Request coalescing and rate limiting

Two identical in-flight requests must become one, and every client must respect a per-source minimum interval.

### Coalescing

```dart
final _inFlight = <String, Future<ServiceResult<T>>>{};

Future<ServiceResult<T>> fetch(String key) {
  final existing = _inFlight[key];
  if (existing != null) return existing;          // join the in-flight call
  final future = _doFetch(key).whenComplete(() => _inFlight.remove(key));
  _inFlight[key] = future;
  return future;
}
```

Without this, a screen with three widgets watching the same provider issues three identical requests on first build, and a scroll that rebuilds the list issues more. Coalescing is a few lines and typically removes the majority of redundant traffic.

### Rate limiting

> **[RULE]**

> **Rate limiting belongs on the HTTP client, per source, not on a global singleton.** Build every client through a factory that takes the source's own minimum interval:

> ```dart
> final dio = DioFactory.create(
>   baseUrl: source.baseUrl,
>   rateLimit: RateLimitConfig(minInterval: source.minInterval),
> );
> ```

> A global limiter makes a slow source throttle a fast one. A per-call-site limiter gets forgotten at the next call site. The factory is the only place that cannot be bypassed by accident — which is why `Dio()` constructed directly is banned.

### Conditional requests

Where a source supports it, an `ETag`/`If-None-Match` or `Last-Modified`/`If-Modified-Since` interceptor turns a refresh into a 304 with no body. That is strictly better than a TTL for large payloads, because it refreshes freshness without transferring anything. Add it as an interceptor on the shared factory so every source benefits where the server cooperates.

<!-- chunk: cache.invalidation | tags: caching,invalidation,mutations -->

## Invalidation on mutation

A local write must invalidate every cached read that could contain the written entity — which is why keys are ordered general-to-specific.

```dart
Future<void> createReservation(Reservation r) async {
  await _remote.insert(r);
  // Every cached view that could contain this reservation.
  await _cache.evictPrefix('reservations:${r.workspaceId}:');
  await _cache.evictPrefix('availability:${r.workspaceId}:${r.dateKey}:');
}
```

| Strategy | When | Risk |
| --- | --- | --- |
| **Evict by prefix** | Default. Simple and correct. | Over-evicts; costs a refetch. |
| **Write-through** | Single-entity reads where you know the new value exactly. | The local value can diverge from what the server computed (defaults, triggers, generated columns). |
| **Optimistic update + reconcile** | Latency-sensitive UI. | Needs a rollback path and a test for it. Do not adopt casually. |

> **[TRAP]**

> **Symptom: a change saves correctly but a different screen keeps showing the old value until the app restarts.** An invalidated read path was missed — typically an aggregate, a count, or a summary view that derives from the same rows under a different key prefix. When adding a mutation, enumerate *every* key prefix whose payload could include the mutated entity, and write that list in a comment next to the eviction calls. Prefer over-eviction: a needless refetch is invisible, a stale screen is a bug report.

<!-- chunk: cache.testing | tags: caching,testing -->

## Testing a cache

Three tests per cached path, always the same three, plus one for the eviction policy.

```dart
group('station search cache', () {
  late FakeClock clock;
  late InMemoryCacheStore cache;
  late _FakeService service;

  setUp(() {
    clock = FakeClock(DateTime.utc(2026, 3, 1, 12));
    cache = InMemoryCacheStore(clock: clock);
    service = _FakeService();
  });

  test('fresh hit does not call the service', () async {
    await cache.put(key, rows, ttl: CacheTtl.prices);
    clock.advance(const Duration(minutes: 2));
    final r = await chain.fetch(query);
    expect(service.callCount, 0);
    expect(r.isStale, isFalse);
  });

  test('stale hit is served when the service fails', () async {
    await cache.put(key, rows, ttl: CacheTtl.prices);
    clock.advance(const Duration(minutes: 20));      // expired, not evicted
    service.throws = SocketException('offline');
    final r = await chain.fetch(query);
    expect(r.isStale, isTrue);
    expect(r.source, ServiceSource.cache);
  });

  test('total failure throws with a chain snapshot', () async {
    service.throws = SocketException('offline');
    expect(() => chain.fetch(query),
        throwsA(isA<ServiceChainExhaustedException>()));
  });
});
```

> **[RULE]**

> **Never use a real clock in a cache test.** Inject one. A test that calls `Future.delayed` to age an entry is slow, flaky, and cannot test a seven-day TTL at all. This is the same fixed-clock injection that [page 03](03-tdd-and-testing.html#goldens) requires for date-dependent tests, and it should come from the same shared override helper.

#### Sources for this page

- One project's `CacheManager` — the fresh/stale/miss tiers, the `CacheTtl` constant class, the coordinate-rounding key convention, and the 30-minute sweep with a 3× retention multiple.
- The other project's `CacheStore`/`CacheEntry` port, including its `cacheSchemaVersion` constant and the raw-rows-not-parsed-objects rule, whose comment explicitly cites the earlier project's incident as the reason.
- The radar feature's split between hour-cached station locations and just-in-time price fetches.

The coalescing snippet and the invalidation-strategy table are generalised patterns, not verbatim source.
