// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../persistent_dataset.dart';

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

  /// Stamp the in-memory freshness clock to [age] ago — used when a dataset
  /// is rehydrated from disk so its remaining freshness reflects the persisted
  /// copy's age, not the moment of rehydration (#2264).
  void markDatasetRefreshedAt(Duration age) =>
      _datasetCachedAt = DateTime.now().subtract(age);

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

  /// Persistence-aware variant of [loadDataset] (#2264). Adds a disk
  /// read-through so a bulk dataset survives a cold start and works offline:
  ///
  ///  1. In-memory fresh (< [softTtl]) → return [cached] (no I/O).
  ///  2. Else read the persisted copy via [persistent]:
  ///       - younger than [hardTtl] → rehydrate [store] it, stamp the
  ///         in-memory clock to the persisted age, and return it. (Past the
  ///         soft TTL the caller may still trigger a background refresh, but
  ///         the user sees data immediately + offline.)
  ///  3. Else [fetch] from the network, [store] + persist with [hardTtl],
  ///     mark fresh, and return.
  ///  4. If [fetch] throws but a persisted copy of *any* age exists, serve it
  ///     (stale-but-offline) rather than failing the whole search.
  Future<T> loadPersistentDataset<T>({
    required T? cached,
    required Duration softTtl,
    required Duration hardTtl,
    required PersistentDataset<T> persistent,
    required Future<T> Function() fetch,
    required void Function(T value) store,
  }) async {
    if (cached != null && isDatasetFresh(softTtl)) return cached;

    // Disk read-through — survives cold start + offline.
    if (cached == null || !isDatasetFresh(hardTtl)) {
      final disk = persistent.read();
      if (disk != null && disk.age <= hardTtl) {
        store(disk.value);
        markDatasetRefreshedAt(disk.age);
        if (disk.age <= softTtl) return disk.value;
        // Soft-stale: fall through to refresh, but keep the disk copy as a
        // fallback if the network is unavailable.
      }
    }

    try {
      final value = await fetch();
      store(value);
      markDatasetRefreshed();
      await persistent.write(value, hardTtl: hardTtl);
      return value;
    } on Object {
      // Network failed — serve any persisted copy rather than throw.
      final disk = persistent.read();
      if (disk != null) {
        store(disk.value);
        markDatasetRefreshedAt(disk.age);
        return disk.value;
      }
      rethrow;
    }
  }
}
