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

  /// #2313 — the single in-flight network fetch, shared by all concurrent
  /// callers. Without it, two searches that arrive while the cache is cold
  /// (or soft-stale) each `await fetch()` independently and both download the
  /// full national dataset — wasted bandwidth on a large CSV. We dedupe by
  /// storing the running future and handing it to every concurrent caller,
  /// clearing the slot on completion so the next (later) call refetches.
  ///
  /// The shared future closes over the *first* caller's `CancelToken` (the
  /// fetch closure is built by that caller). A second caller's token therefore
  /// does not cancel the shared future — it only ever awaits it. Stored as
  /// `Future<dynamic>` because one mixin host has a single dataset type `T`
  /// per call site; the public wrappers cast it back.
  Future<dynamic>? _pendingLoad;

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
    // #2313 — dedupe concurrent downloads so two simultaneous cold searches
    // issue one fetch, not two.
    final value = await _dedupedFetch<T>(fetch);
    store(value);
    markDatasetRefreshed();
    return value;
  }

  /// Runs [fetch], collapsing concurrent calls onto a single in-flight future
  /// (#2313). The first caller starts the fetch; later callers that arrive
  /// while it is still running await the same future. The slot is cleared once
  /// the fetch settles (success or failure) so a subsequent call refetches.
  Future<T> _dedupedFetch<T>(Future<T> Function() fetch) {
    final inFlight = _pendingLoad;
    if (inFlight != null) return inFlight.then((v) => v as T);
    final started = fetch();
    _pendingLoad = started;
    return started.whenComplete(() {
      // Only clear if it's still our future (a later refetch may have
      // replaced it).
      if (identical(_pendingLoad, started)) _pendingLoad = null;
    });
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
      // #2313 — dedupe concurrent downloads (one fetch for N simultaneous
      // cold/soft-stale searches). The disk write below runs only for the
      // caller that actually performed the fetch; piggy-backing callers skip
      // it (they get the same value back), which is harmless — the dataset is
      // identical and already persisted by the leader.
      final value = await _dedupedFetch<T>(fetch);
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
