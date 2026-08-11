// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:meta/meta.dart';

import '../../data/storage_repository.dart';
import '../../logging/error_logger.dart';
import '../hive_boxes.dart';
import '../hive_cache_recovery.dart';

/// Hive-backed implementation of [CacheStorage] and [ItineraryStorage].
///
/// Manages the API response cache and itinerary storage.
/// The [CacheManager] wraps this for TTL and metadata envelopes.
///
/// #2670 — every box access goes through [_boxOrNull], which returns null
/// when the `cache` box isn't open instead of throwing. A background scan
/// running in the foreground isolate can close the shared `cache` handle
/// mid-flight (`closeIsolateBoxes`); without this guard the next routine
/// `StationServiceChain` cache read threw `FileSystemException: File closed`
/// (43× in field). A closed box now degrades to a clean cache miss / no-op,
/// matching the other Hive stores (`RadiusAlertStore`, `PriceSnapshotStore`,
/// `VelocityAlertCooldown`). The root close-site is fixed in
/// [HiveBoxes.closeIsolateBoxes]; this is the belt-and-braces reader guard.
class CacheHiveStore implements CacheStorage, ItineraryStorage {
  /// Recovery hook — [HiveCacheRecovery.recover] in production, a fake in
  /// tests (the dead-handle state can't be produced via Hive's public API).
  CacheHiveStore({@visibleForTesting Future<bool> Function()? recover})
      : _recover = recover ?? HiveCacheRecovery.recover;

  final Future<bool> Function() _recover;

  /// #3689 — write-path self-heal. A box whose FILE handle died (foreign
  /// compaction, #3689) still passes [_boxOrNull] (`isBoxOpen` is registry
  /// state) but throws `FileSystemException: File closed` on every write.
  /// Recover the box once and retry; on a second failure rethrow so the
  /// caller's storage-layer logging ([CacheManager.put]'s catch) records it.
  /// Public-for-testing: the dead-handle throw can't be produced through
  /// Hive's public API, so tests drive [op] directly with a throwing fake.
  @visibleForTesting
  Future<void> writeWithRecovery(
      Future<void> Function(Box<dynamic> box) op) async {
    final box = _boxOrNull();
    if (box == null) return;
    try {
      await op(box);
    } on FileSystemException {
      if (!await _recover()) rethrow;
      final reopened = _boxOrNull();
      if (reopened == null) return;
      await op(reopened);
    }
  }

  Box<dynamic>? _boxOrNull() {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.cache)) return null;
      return Hive.box(HiveBoxes.cache);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'CacheHiveStore: cache box unavailable'}));
      return null;
    }
  }

  // Cache
  @override
  Future<void> cacheData(String key, dynamic data) =>
      writeWithRecovery((box) => box.put(key, {
            'data': data,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }));

  @override
  Map<String, dynamic>? getCachedData(String key, {Duration? maxAge}) {
    final box = _boxOrNull();
    if (box == null) return null;
    final cached = box.get(key);
    if (cached == null) return null;

    final map = HiveBoxes.toStringDynamicMap(cached);
    if (map == null) return null;

    if (maxAge != null) {
      final timestamp = map['timestamp'] as int?;
      if (timestamp != null) {
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        if (age > maxAge.inMilliseconds) return null;
      }
    }
    final data = map['data'];
    if (data is Map) return HiveBoxes.toStringDynamicMap(data);
    return null;
  }

  @override
  Future<void> clearCache() => writeWithRecovery((box) => box.clear());

  @override
  Iterable<dynamic> get cacheKeys => _boxOrNull()?.keys ?? const [];

  @override
  Future<void> deleteCacheEntry(String key) =>
      writeWithRecovery((box) => box.delete(key));

  @override
  int get cacheEntryCount => _boxOrNull()?.length ?? 0;

  // Itineraries (stored in cache box)
  @override
  List<Map<String, dynamic>> getItineraries() {
    final box = _boxOrNull();
    if (box == null) return [];
    final data = box.get('itineraries');
    if (data == null) return [];
    return (data as List)
        .map((e) => HiveBoxes.toStringDynamicMap(e))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  @override
  Future<void> saveItineraries(List<Map<String, dynamic>> itineraries) =>
      writeWithRecovery((box) => box.put('itineraries', itineraries));

  @override
  Future<void> addItinerary(Map<String, dynamic> itinerary) async {
    final list = getItineraries();
    final idx = list.indexWhere((i) => i['id'] == itinerary['id']);
    if (idx >= 0) {
      list[idx] = itinerary;
    } else {
      list.insert(0, itinerary);
    }
    await saveItineraries(list);
  }

  @override
  Future<void> deleteItinerary(String id) async {
    final list = getItineraries();
    list.removeWhere((i) => i['id'] == id);
    await saveItineraries(list);
  }
}
