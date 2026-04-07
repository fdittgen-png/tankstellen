import 'package:hive_flutter/hive_flutter.dart';

import '../../data/storage_repository.dart';
import '../hive_boxes.dart';

/// Hive-backed implementation of [CacheStorage] and [ItineraryStorage].
///
/// Manages the API response cache and itinerary storage.
/// The [CacheManager] wraps this for TTL and metadata envelopes.
class CacheHiveStore implements CacheStorage, ItineraryStorage {
  Box get _cache => Hive.box(HiveBoxes.cache);

  // Cache
  @override
  Future<void> cacheData(String key, dynamic data) async {
    await _cache.put(key, {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Map<String, dynamic>? getCachedData(String key, {Duration? maxAge}) {
    final cached = _cache.get(key);
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
  Future<void> clearCache() => _cache.clear();

  @override
  Iterable<dynamic> get cacheKeys => _cache.keys;

  @override
  Future<void> deleteCacheEntry(String key) => _cache.delete(key);

  @override
  int get cacheEntryCount => _cache.length;

  // Itineraries (stored in cache box)
  @override
  List<Map<String, dynamic>> getItineraries() {
    final data = _cache.get('itineraries');
    if (data == null) return [];
    return (data as List)
        .map((e) => HiveBoxes.toStringDynamicMap(e))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  @override
  Future<void> saveItineraries(List<Map<String, dynamic>> itineraries) =>
      _cache.put('itineraries', itineraries);

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
