import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../domain/entities/traffic_signal.dart';
import 'osm_traffic_signal_client.dart';

/// Master toggle for the glide-coach feature (#1125).
/// TODO: migrate to central feature management once that system lands.
const bool kGlideCoachEnabled = false;

/// Default cache TTL for cached Overpass responses (#1125 phase 1).
///
/// Public Overpass infrastructure is shared and the underlying OSM map
/// changes slowly for fixed infrastructure like traffic signals. Seven
/// days is a comfortable upper bound that keeps repeat trips through the
/// same neighbourhood off the public Overpass servers without serving
/// data so stale that newly-installed signals stay invisible for months.
const Duration kTrafficSignalCacheTtl = Duration(days: 7);

/// Repository wrapping [OsmTrafficSignalClient] with a Hive-backed cache
/// (#1125 phase 1).
///
/// The cache key is the bounding box rounded to `0.01°` (~1.1 km on each
/// edge) so two near-identical lookups within a residential area share
/// one Overpass call. Entries persist until the TTL expires; on miss or
/// expiry the repository hits the underlying client and rewrites the
/// entry with a fresh `cachedAt` timestamp.
///
/// One repository instance per app — the box is opened once at startup
/// in `HiveBoxes.init` (and `HiveBoxes.initInIsolate`) and handed in
/// here. Tests can supply an in-memory box via the same constructor.
class TrafficSignalRepository {
  final OsmTrafficSignalClient _client;
  final Box<String> _cacheBox;
  final Duration _ttl;
  final DateTime Function() _now;

  /// Hive box that stores cached Overpass payloads. Registered in
  /// `HiveBoxes.init` so the repository can open one shared instance.
  static const String boxName = 'traffic_signals_cache';

  TrafficSignalRepository({
    required OsmTrafficSignalClient client,
    required Box<String> cacheBox,
    Duration ttl = kTrafficSignalCacheTtl,
    DateTime Function()? now,
  })  : _client = client,
        _cacheBox = cacheBox,
        _ttl = ttl,
        _now = now ?? DateTime.now;

  /// Return every traffic signal inside the bounding box, prefering a
  /// fresh cache entry over a network round-trip.
  ///
  /// On cache miss, expired entry, or unreadable payload, the repository
  /// falls back to [OsmTrafficSignalClient.fetchInBoundingBox] and
  /// persists the result. Network errors propagate as
  /// [OsmTrafficSignalException].
  Future<List<TrafficSignal>> getSignalsForBoundingBox({
    required double south,
    required double west,
    required double north,
    required double east,
  }) async {
    final key = _cacheKey(
      south: south,
      west: west,
      north: north,
      east: east,
    );

    final cached = _readCache(key);
    if (cached != null) return cached;

    final fresh = await _client.fetchInBoundingBox(
      south: south,
      west: west,
      north: north,
      east: east,
    );
    await _writeCache(key, fresh);
    return fresh;
  }

  /// Build a cache key from the bounding box, snapping each corner to
  /// the nearest 0.01°. Visible for testing so the key format can be
  /// asserted directly.
  @visibleForTesting
  static String cacheKeyFor({
    required double south,
    required double west,
    required double north,
    required double east,
  }) =>
      _cacheKey(south: south, west: west, north: north, east: east);

  static String _cacheKey({
    required double south,
    required double west,
    required double north,
    required double east,
  }) {
    String snap(double v) => v.toStringAsFixed(2);
    return 'bbox:${snap(south)}:${snap(west)}:${snap(north)}:${snap(east)}';
  }

  List<TrafficSignal>? _readCache(String key) {
    final raw = _cacheBox.get(key);
    if (raw == null || raw.isEmpty) return null;

    Map<String, dynamic> envelope;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      envelope = decoded.cast<String, dynamic>();
    } catch (e, st) {
      debugPrint('TrafficSignalRepository: corrupt cache entry $key: $e\n$st');
      return null;
    }

    final cachedAtMs = envelope['cachedAt'];
    if (cachedAtMs is! int) return null;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMs);
    if (_now().difference(cachedAt) > _ttl) return null;

    final signalsRaw = envelope['signals'];
    if (signalsRaw is! List) return null;

    try {
      return signalsRaw
          .whereType<Map>()
          .map((e) => TrafficSignal.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    } catch (e, st) {
      debugPrint('TrafficSignalRepository: failed to deserialise $key: '
          '$e\n$st');
      return null;
    }
  }

  Future<void> _writeCache(String key, List<TrafficSignal> signals) async {
    final envelope = <String, dynamic>{
      'cachedAt': _now().millisecondsSinceEpoch,
      'signals': signals.map((s) => s.toJson()).toList(),
    };
    await _cacheBox.put(key, jsonEncode(envelope));
  }
}
