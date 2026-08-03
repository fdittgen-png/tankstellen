// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;

import '../persistent_dataset.dart';
import 'cached_dataset_mixin.dart' show datasetStaleServeDeadline;

/// Keyed variant of [CachedDatasetMixin] (#3156).
///
/// Some bulk feeds are not ONE national dataset but a *family* of datasets
/// keyed by a sub-national identifier (ES MITECO: one row set per province).
/// [CachedDatasetMixin] is single-dataset — one freshness clock, one in-flight
/// fetch slot — which forced MITECO to hand-roll the very same TTL /
/// read-through / offline-fallback state machine, a fork where mixin fixes
/// (the #2313 fetch dedupe, the #3154 off-isolate disk deserialize) never
/// reached Spain. This mixin is that state machine with per-[key] clocks and
/// in-flight slots.
mixin KeyedCachedDatasetMixin {
  final Map<String, DateTime> _keyedCachedAt = {};

  /// Per-key in-flight fetch slots — same #2313 dedupe contract as
  /// [CachedDatasetMixin]: concurrent callers for the SAME key share one
  /// download (the first caller's closure, so a later caller's `CancelToken`
  /// only awaits, never cancels); different keys fetch independently.
  final Map<String, Future<dynamic>> _keyedPendingLoads = {};

  /// Whether the in-memory dataset for [key] is still fresh.
  bool isKeyedDatasetFresh(String key, Duration ttl) {
    final cachedAt = _keyedCachedAt[key];
    return cachedAt != null && DateTime.now().difference(cachedAt) < ttl;
  }

  /// Mark [key]'s in-memory dataset as just refreshed.
  void markKeyedDatasetRefreshed(String key) =>
      _keyedCachedAt[key] = DateTime.now();

  /// Stamp [key]'s freshness clock to [age] ago — used when a dataset is
  /// rehydrated from disk so its remaining freshness reflects the persisted
  /// copy's age, not the moment of rehydration (#2264).
  void markKeyedDatasetRefreshedAt(String key, Duration age) =>
      _keyedCachedAt[key] = DateTime.now().subtract(age);

  /// Per-key [CachedDatasetMixin.loadPersistentDataset] — identical
  /// soft/hard-TTL, read-through, dedupe and offline-fallback semantics, with
  /// two host-shaped differences:
  ///
  ///  - [persistent] is nullable, so hosts whose disk cache is optional (the
  ///    pure in-memory parser tests pass no [CacheStrategy]) run the same code
  ///    path minus the disk steps, and
  ///  - when [fetch] fails and no disk copy exists, a stale in-memory [cached]
  ///    copy is served as the last resort before rethrowing (the pre-#3156
  ///    MITECO offline behaviour: hours-stale province rows beat failing the
  ///    whole search).
  Future<T> loadKeyedPersistentDataset<T>({
    required String key,
    required T? cached,
    required Duration softTtl,
    required Duration hardTtl,
    required PersistentDataset<T>? persistent,
    required Future<T> Function() fetch,
    required void Function(T value) store,
  }) async {
    if (cached != null && isKeyedDatasetFresh(key, softTtl)) return cached;

    Future<T> refresh() async {
      final value = await _dedupedKeyedFetch<T>(key, fetch);
      store(value);
      markKeyedDatasetRefreshed(key);
      await persistent?.write(value, hardTtl: hardTtl);
      return value;
    }

    // #3668 — soft-stale (memory or disk) serves immediately with a
    // background refresh; a hard-stale disk copy caps the cold fetch at
    // [datasetStaleServeDeadline]. Same shape as the unkeyed mixin.
    if (cached != null && isKeyedDatasetFresh(key, hardTtl)) {
      _swallowKeyedBackground(refresh());
      return cached;
    }

    // Disk read-through — survives cold start + offline; deserialize runs
    // through compute() inside [PersistentDataset.readAsync] (#3154).
    ({T value, Duration age})? disk;
    if (persistent != null) {
      disk = await persistent.readAsync();
      if (disk != null && disk.age <= hardTtl) {
        store(disk.value);
        markKeyedDatasetRefreshedAt(key, disk.age);
        if (disk.age <= softTtl) return disk.value;
        _swallowKeyedBackground(refresh());
        return disk.value;
      }
    }

    final pending = refresh();
    if (disk != null) {
      try {
        return await pending.timeout(datasetStaleServeDeadline);
      } on TimeoutException {
        _swallowKeyedBackground(pending);
        store(disk.value);
        markKeyedDatasetRefreshedAt(key, disk.age);
        return disk.value;
      } on Object {
        store(disk.value);
        markKeyedDatasetRefreshedAt(key, disk.age);
        return disk.value;
      }
    }
    try {
      return await pending;
    } on Object {
      // Network failed — serve any persisted copy rather than throw.
      if (persistent != null) {
        final lateDisk = await persistent.readAsync(); // #3154 — off-isolate
        if (lateDisk != null) {
          store(lateDisk.value);
          markKeyedDatasetRefreshedAt(key, lateDisk.age);
          return lateDisk.value;
        }
      }
      // Last resort: a stale in-memory copy beats failing the search.
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Keyed twin of the unkeyed mixin's background-swallow (#3668).
  void _swallowKeyedBackground(Future<Object?> pending) {
    unawaited(pending.then<void>((_) {}).catchError((Object e, StackTrace st) {
      debugPrint(
          'KeyedCachedDatasetMixin: background dataset refresh failed: $e');
    }));
  }

  /// Per-key twin of the unkeyed mixin's deduped fetch (#2313): collapses
  /// concurrent calls for the same [key] onto a single in-flight future,
  /// clearing the slot once it settles so a later call refetches.
  Future<T> _dedupedKeyedFetch<T>(String key, Future<T> Function() fetch) {
    final inFlight = _keyedPendingLoads[key];
    if (inFlight != null) return inFlight.then((v) => v as T);
    final started = fetch();
    _keyedPendingLoads[key] = started;
    return started.whenComplete(() {
      // Only clear if it's still our future (a later refetch may have
      // replaced it).
      if (identical(_keyedPendingLoads[key], started)) {
        unawaited(_keyedPendingLoads.remove(key));
      }
    });
  }
}
