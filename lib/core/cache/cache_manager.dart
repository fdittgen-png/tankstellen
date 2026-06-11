// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../constants/app_constants.dart';
import '../data/storage_repository.dart';
import '../logging/error_logger.dart';
import '../services/service_result.dart';
import '../storage/storage_providers.dart';
import 'cache_eviction_policy.dart';

export 'cache_eviction_policy.dart' show CacheEvictionPolicy;
// CacheTtl / CacheKey moved out under the 400-line cap (#3155); the
// re-export keeps every existing `cache_manager.dart` import working.
export 'cache_keys.dart';

part 'cache_manager.g.dart';

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

  /// The app build that wrote this entry (`AppConstants.appVersion` at
  /// `put()` time), or `null` for an entry persisted by a build that
  /// predates the stamp (#3219 follow-up). Cached payloads are PARSED
  /// output, so an entry written by a different build may embed the very
  /// parser bug an update just fixed — [CacheManager.getFresh] therefore
  /// refuses to serve a cross-build entry as fresh (it stays available to
  /// the stale/offline fallback via [CacheManager.get]).
  final String? appBuild;

  CacheEntry({
    required this.payload,
    required this.storedAt,
    required this.originalSource,
    required this.ttl,
    this.appBuild,
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
        // #3150 — the enum NAME, not the reorder-fragile index.
        'source': source.name,
        'ttlMs': ttl.inMilliseconds,
        // #3219 follow-up — stamp the writing build so [getFresh] can
        // refuse to serve another build's PARSED payload as fresh.
        'appBuild': AppConstants.appVersion,
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
      originalSource: _sourceFrom(raw['source']),
      ttl: Duration(milliseconds: raw['ttlMs'] as int? ?? 300000),
      appBuild: raw['appBuild'] as String?,
    );
  }

  /// Resolves the persisted `source` — enum name (new) or index (legacy);
  /// unknown values fall back to [ServiceSource.cache] (pre-#3150 behaviour).
  static ServiceSource _sourceFrom(dynamic raw) {
    if (raw is String) {
      return ServiceSource.values.asNameMap()[raw] ?? ServiceSource.cache;
    }
    if (raw is int) {
      return ServiceSource.values.elementAtOrNull(raw) ?? ServiceSource.cache;
    }
    return ServiceSource.cache;
  }

  /// Get data only if the cache entry is still valid (not expired) AND was
  /// written by THIS app build.
  ///
  /// #3219 follow-up — cached payloads are PARSED output (e.g. the
  /// `serializeStationList` Station JSON), so an entry persisted by an older
  /// build embeds that build's parser bugs. With FR's 6-hour
  /// `searchResultTtl`, the #3224 hours fix was invisible after updating:
  /// the freshly installed build kept serving the PRE-fix build's hour-less
  /// stations for the same search key until the TTL lapsed — "the fix
  /// shipped but the phone still shows the bug". A cross-build (or
  /// unstamped pre-stamp) entry is therefore treated as a fresh-miss —
  /// forcing one re-fetch + re-parse with the current code — while [get]
  /// still serves it to the chain's stale/offline fallback, so an update
  /// never costs the offline backbone.
  @override
  CacheEntry? getFresh(String key) {
    final entry = get(key);
    if (entry == null || entry.isExpired) return null;
    if (entry.appBuild != AppConstants.appVersion) return null;
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
    //
    // #3155 — `dataset:` entries are exempt from this sweep (they can never
    // be evicted by it), so jsonEncode-ing their multi-MB national payloads
    // into the byte estimate on EVERY pass was pure main-isolate waste — and
    // counting unevictable bytes against the ceiling could only force out
    // small per-search entries the budget was meant for. Only the evictable
    // (non-`dataset:`) entries are sized and folded.
    final evictable = budgeted
        .where((e) => !e.key.startsWith('dataset:'))
        .toList();
    var totalBytes =
        evictable.fold<int>(0, (sum, e) => sum + _approxBytes(e.value));
    if (totalBytes > policy.maxBytes) {
      evictable
          .sort((a, b) => a.value.storedAt.compareTo(b.value.storedAt));
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
