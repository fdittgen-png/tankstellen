// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io' show HttpDate;

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../domain/entities/traffic_signal.dart';
import 'osm_traffic_signal_client.dart';

/// Read a `Retry-After` header in either of its two legal forms: delta
/// seconds, or an HTTP date. Returns null for anything else, including a
/// date already in the past — a negative hold is not a hold.
Duration? parseRetryAfter(String? raw, {required DateTime now}) {
  if (raw == null) return null;
  final text = raw.trim();
  if (text.isEmpty) return null;
  final seconds = int.tryParse(text);
  if (seconds != null) return seconds > 0 ? Duration(seconds: seconds) : null;
  // `HttpDate.parse` throws on a malformed date rather than answering
  // null, and a header we cannot read must never take the caller down.
  final DateTime at;
  try {
    at = HttpDate.parse(text);
  } on Exception {
    return null;
  }
  final delta = at.difference(now);
  return delta > Duration.zero ? delta : null;
}

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
    required this._client,
    required this._cacheBox,
    this._ttl = kTrafficSignalCacheTtl,
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now;

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
    // #3890 — circuit breaker: after a failed Overpass call the endpoint
    // is not dialled again for [breakerHold] (5 min, doubling to 1 h on
    // consecutive failures); a stale cache entry is served meanwhile,
    // else an empty list. The field log had 50/50 error traces from one
    // unreachable Overpass — now one probe per hold window, one trace.
    final until = _breakerUntil;
    if (until != null && _now().isBefore(until)) {
      return _staleOrEmpty(key);
    }
    // #4109 — SINGLE FLIGHT. The breaker was consulted before the call
    // and tripped after it, so a GPS stream firing the evaluator every
    // few seconds got several probes past the gate before the first one
    // returned: every hold window expired into a burst of concurrent
    // requests, two of them inside the same second in the field log, and
    // the breaker then counted one bad window as three failures and
    // over-escalated. One socket at a time; everyone else gets the stale
    // answer NOW rather than joining a 15-second wait, because the
    // caller is a per-GPS-tick evaluator that must not stall.
    if (_probeInFlight) return _staleOrEmpty(key);
    _probeInFlight = true;
    final List<TrafficSignal> fresh;
    try {
      fresh = await _client.fetchInBoundingBox(
        south: south,
        west: west,
        north: north,
        east: east,
      );
    } on OsmTrafficSignalException catch (e, st) {
      // The typed path: the exception carries the status and the raw
      // Retry-After, which is what picks the hold.
      _tripBreaker(e);
      Error.throwWithStackTrace(e, st);
    } catch (e, st) {
      // Defence in depth: the client's contract is that everything
      // surfaces as OsmTrafficSignalException, but a breaker that only
      // trips on the expected type would dial a broken endpoint forever
      // if that contract ever slipped. The original stack is carried
      // through explicitly rather than rethrown across the async gap.
      _tripBreaker(null);
      Error.throwWithStackTrace(e, st);
    } finally {
      _probeInFlight = false;
    }
    _breakerFailures = 0;
    _breakerUntil = null;
    await _writeCache(key, fresh);
    return fresh;
  }

  /// The best answer available without a network call: an entry past its
  /// TTL beats nothing, because traffic signals do not move.
  List<TrafficSignal> _staleOrEmpty(String key) =>
      _readCache(key, ignoreTtl: true) ?? const <TrafficSignal>[];

  /// True while a probe is on the wire. See the single-flight note above.
  bool _probeInFlight = false;

  /// Visible so a test can assert the guard rather than infer it from
  /// call counts.
  @visibleForTesting
  bool get probeInFlight => _probeInFlight;

  int _breakerFailures = 0;
  DateTime? _breakerUntil;

  /// When the breaker re-allows a network probe, or null when closed.
  @visibleForTesting
  DateTime? get breakerUntil => _breakerUntil;

  /// The current hold: 5 min after the first failure, doubling per
  /// consecutive failure, capped at 1 h.
  Duration get breakerHold {
    if (_breakerFailures <= 0) return Duration.zero;
    final minutes = (5 << (_breakerFailures - 1)).clamp(5, 60);
    return Duration(minutes: minutes);
  }

  /// #4109 — the floor for a 429. Overpass is donated infrastructure and
  /// a 429 is it asking to be left alone; the generic 5-minute hold is
  /// far too eager, and retrying into a rate limit is how an IP earns a
  /// longer one. Well below the 1 h cap so a transient limit still
  /// clears within a single drive.
  static const Duration rateLimitedHold = Duration(minutes: 20);

  void _tripBreaker(OsmTrafficSignalException? failure) {
    _breakerFailures++;
    // The server's own Retry-After wins: nobody knows better than it how
    // long it wants to be left alone. Then the rate-limited floor. Then
    // the generic escalation.
    final serverAsked =
        parseRetryAfter(failure?.retryAfterHeader, now: _now());
    final hold = serverAsked ??
        ((failure?.isRateLimited ?? false)
            ? _longer(breakerHold, rateLimitedHold)
            : breakerHold);
    _breakerUntil = _now().add(hold);
  }

  static Duration _longer(Duration a, Duration b) => a > b ? a : b;

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

  List<TrafficSignal>? _readCache(String key, {bool ignoreTtl = false}) {
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
    if (!ignoreTtl && _now().difference(cachedAt) > _ttl) return null;

    final signalsRaw = envelope['signals'];
    if (signalsRaw is! List) return null;

    try {
      return signalsRaw
          .whereType<Map<dynamic, dynamic>>()
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
