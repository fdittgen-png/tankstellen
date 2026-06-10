// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart' show compute;

import '../cache/cache_manager.dart';
import 'service_result.dart';

/// Disk-backed persistence for a whole-country bulk dataset (#2264).
///
/// Bulk-dataset services (ES MITECO, DK aggregate, …) parse a large national
/// dataset and keep it in memory. Without persistence the dataset is gone on
/// the next cold start, so the first search after launch always re-downloads
/// — defeating the dataset's multi-hour TTL and giving zero offline coverage.
///
/// [PersistentDataset] wraps the shared [CacheStrategy] (Hive) with a stable
/// per-country key plus JSON serialize / deserialize, and exposes soft/hard
/// TTL semantics:
///
///  - [readWithin] returns the persisted dataset only when it is younger than
///    the supplied age (used for the *hard* TTL — past it the caller must
///    re-download before serving),
///  - the [CacheEntry.age] of [read] lets the caller decide whether to trigger
///    a background refresh (the *soft* TTL).
///
/// The dataset is stored under its own `dataset:` key prefix so the eviction
/// policy (concern 5) can give it a dedicated budget and never evict it under
/// the same pressure as ephemeral per-search entries.
class PersistentDataset<T> {
  final CacheStrategy _cache;
  final String _key;
  final ServiceSource _source;
  final Map<String, dynamic> Function(T value) _serialize;
  final T? Function(Map<String, dynamic> json) _deserialize;

  /// [countryCode] keys the dataset; [datasetName] disambiguates services that
  /// persist more than one dataset for the same country.
  ///
  /// #3154 — [serialize] and [deserialize] are run in a background isolate by
  /// [write] / [readAsync] (a whole-country dataset is ~11k `Station.fromJson`
  /// calls — far too heavy for the UI isolate). They must therefore be
  /// **isolate-sendable**: top-level / static functions, or closures that
  /// capture nothing non-sendable (every current call site passes a
  /// capture-free closure or a top-level function).
  PersistentDataset({
    required CacheStrategy cache,
    required String countryCode,
    required String datasetName,
    required ServiceSource source,
    required Map<String, dynamic> Function(T value) serialize,
    required T? Function(Map<String, dynamic> json) deserialize,
  })  : _cache = cache,
        _key = datasetKey(countryCode, datasetName),
        _source = source,
        _serialize = serialize,
        _deserialize = deserialize;

  /// Stable cache key for a country's bulk dataset. Public so the eviction
  /// policy and tests can reason about the `dataset:` prefix.
  static String datasetKey(String countryCode, String datasetName) =>
      'dataset:$countryCode:$datasetName';

  /// The `dataset:` key prefix — entries under it are the persisted national
  /// datasets, given a dedicated eviction budget (concern 5).
  static const String keyPrefix = 'dataset:';

  /// Persist [value]. The Hive entry's own TTL is set to [hardTtl] so a
  /// generic expiry sweep never drops a dataset the caller still considers
  /// servable; freshness decisions are made by the caller via soft/hard age.
  ///
  /// #3154 — the serialize closure runs through [compute] so mapping a whole
  /// national dataset to JSON doesn't block the UI isolate.
  Future<void> write(T value, {required Duration hardTtl}) async {
    final json = await compute(_serialize, value);
    await _cache.put(_key, json, ttl: hardTtl, source: _source);
  }

  /// The persisted dataset and the age of the stored copy, or null when
  /// nothing is persisted / it fails to deserialize.
  ///
  /// Synchronous variant — deserializes **on the calling isolate**. Kept for
  /// callers with small per-key payloads (the ES per-province rows); bulk
  /// whole-country readers go through [readAsync] (#3154).
  ({T value, Duration age})? read() {
    final entry = _cache.get(_key);
    if (entry == null) return null;
    final value = _deserialize(entry.payload);
    if (value == null) return null;
    return (value: value, age: entry.age);
  }

  /// [read], with the deserialize closure run through [compute] (#3154) so a
  /// cold-start rehydrate of a whole national dataset (~11k `fromJson`s)
  /// happens off the UI isolate. Same result contract as [read].
  Future<({T value, Duration age})?> readAsync() async {
    final entry = _cache.get(_key);
    if (entry == null) return null;
    final value = await compute(_deserialize, entry.payload);
    if (value == null) return null;
    return (value: value, age: entry.age);
  }

  /// The persisted dataset only when its stored copy is younger than
  /// [maxAge] (the hard TTL); otherwise null.
  T? readWithin(Duration maxAge) {
    final hit = read();
    if (hit == null) return null;
    return hit.age <= maxAge ? hit.value : null;
  }
}
