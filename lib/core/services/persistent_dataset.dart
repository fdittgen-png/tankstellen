// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
  Future<void> write(T value, {required Duration hardTtl}) =>
      _cache.put(_key, _serialize(value), ttl: hardTtl, source: _source);

  /// The persisted dataset and the age of the stored copy, or null when
  /// nothing is persisted / it fails to deserialize.
  ({T value, Duration age})? read() {
    final entry = _cache.get(_key);
    if (entry == null) return null;
    final value = _deserialize(entry.payload);
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
