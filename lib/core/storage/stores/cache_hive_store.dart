// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../../data/storage_repository.dart';
import '../../logging/error_logger.dart';
import '../hive_boxes.dart';

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
  Box? _boxOrNull() {
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
  Future<void> cacheData(String key, dynamic data) async {
    final box = _boxOrNull();
    if (box == null) return;
    await box.put(key, {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

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
  Future<void> clearCache() async {
    final box = _boxOrNull();
    if (box != null) await box.clear();
  }

  @override
  Iterable<dynamic> get cacheKeys => _boxOrNull()?.keys ?? const [];

  @override
  Future<void> deleteCacheEntry(String key) async {
    final box = _boxOrNull();
    if (box != null) await box.delete(key);
  }

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
  Future<void> saveItineraries(List<Map<String, dynamic>> itineraries) async {
    final box = _boxOrNull();
    if (box != null) await box.put('itineraries', itineraries);
  }

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
