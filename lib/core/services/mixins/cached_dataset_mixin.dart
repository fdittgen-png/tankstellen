// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Mixin for services that download a full national dataset and cache it
/// in memory (MITECO, MISE, Argentina, Denmark).
///
/// Provides a standardized TTL-based cache validation pattern, eliminating
/// 4 duplicated cache-check blocks.
mixin CachedDatasetMixin {
  DateTime? _datasetCachedAt;

  /// Whether the in-memory dataset is still fresh.
  bool isDatasetFresh(Duration ttl) =>
      _datasetCachedAt != null &&
      DateTime.now().difference(_datasetCachedAt!) < ttl;

  /// Mark the in-memory dataset as just refreshed.
  void markDatasetRefreshed() => _datasetCachedAt = DateTime.now();

  /// Generic guard→fetch→store→mark idiom shared by the dataset services.
  ///
  /// Returns [cached] verbatim when it is non-null and still within [ttl].
  /// Otherwise awaits [fetch], hands the result to [store], stamps the cache
  /// as fresh via [markDatasetRefreshed], and returns the freshly fetched
  /// value. Services that cache more than one field can pass a record (or any
  /// composite) as `T` and unpack it inside [store].
  Future<T> loadDataset<T>({
    required T? cached,
    required Duration ttl,
    required Future<T> Function() fetch,
    required void Function(T value) store,
  }) async {
    if (cached != null && isDatasetFresh(ttl)) return cached;
    final value = await fetch();
    store(value);
    markDatasetRefreshed();
    return value;
  }
}
