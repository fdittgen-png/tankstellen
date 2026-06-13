// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../domain/station.dart';

/// One direct in-radius station search — the caller supplies this, routed
/// through the per-service rate-limited chain. Returns the search rows (already
/// fuel-filtered + distance-sorted by the chain); `const []` on any failure.
typedef InRadiusFetch = Future<List<Station>> Function(
  double lat,
  double lng,
  double radiusKm,
);

/// Movement + time gate for the radar's **direct in-radius merge** (#3254).
///
/// ## Why this exists
///
/// The corridor cache (tier-1) is built from a polled-source search that is
/// row-capped with no distance ordering, so in a dense area the genuinely-
/// nearest forecourt can be truncated out. Both the on-search radar (#2806)
/// and the swipe page-set (#2965) therefore merge a DIRECT in-radius
/// `searchStations` to guarantee the result is a superset of the regular
/// search. But that direct search bypasses the corridor/JIT tiers and hits the
/// chain on **every** call. The radar re-evaluates on every GPS fix
/// (`ApproachPolling` emits a fresh object per poll, 5.6–30 s while driving;
/// the live on-search radar re-ranks on every fix too), and the chain's cache
/// key rounds to ≈111 m cells — so a moving car produces a new key almost every
/// fix → a real network call every fix. The rate limiter QUEUES rather than
/// drops (DE 60 s, AT/PT/SI/CL 1 h minInterval), so arrivals at 2–10/min behind
/// a 1/min drain build an unbounded backlog: corridor refreshes, the imminent
/// JIT price and the user's own searches all stall behind it, and the backlog
/// keeps burning quota after the trip ends.
///
/// ## The gate
///
/// Cache the last in-radius result and re-issue the search ONLY when the fix
/// has moved into a new ≈111 m cell **and** the provider's `minInterval` has
/// elapsed since the last fetch. So a standstill never re-fetches, and a moving
/// car issues at most one in-radius search per `minInterval` — a bounded queue.
/// Inside the gate the cached merge is returned with zero network. A failed
/// fetch degrades to the last good merge (or empty), never breaking the
/// surface. The radius is part of the cache cell so a radius change re-fetches.
///
/// Mirrors [JitPriceCache]'s injection seams (`fetch`, `now`) so it is unit-
/// testable without a Riverpod container or a real clock.
class RadarInRadiusCache {
  /// Decimal places the cell key rounds the fix to. 3 ⇒ ≈111 m — matches the
  /// chain's own search cache-key rounding, so a fix that wouldn't change the
  /// upstream cache key never forces a fresh search here either.
  static const int cellDecimals = 3;

  final InRadiusFetch _fetch;
  final Duration Function() _minInterval;
  final DateTime Function() _now;

  String? _cellKey;
  DateTime? _fetchedAt;
  List<Station> _cached = const [];

  RadarInRadiusCache({
    required InRadiusFetch fetch,
    required Duration Function() minInterval,
    DateTime Function()? now,
  })  : _fetch = fetch,
        _minInterval = minInterval,
        _now = now ?? DateTime.now;

  /// The in-radius rows around ([lat], [lng]) at [radiusKm] — freshly fetched
  /// only when the movement+time gate opens, otherwise the cached merge.
  Future<List<Station>> stationsNear(
    double lat,
    double lng,
    double radiusKm,
  ) async {
    final cell = _cell(lat, lng, radiusKm);
    final fetchedAt = _fetchedAt;
    // After the first fetch, re-fetch ONLY when we've moved into a new cell AND
    // the provider's minInterval has elapsed (#3254). Otherwise reuse — a
    // standstill, a sub-cell jitter, or a too-soon move all return the cached
    // merge with zero network.
    if (fetchedAt != null) {
      if (cell == _cellKey) return _cached;
      Duration interval;
      try {
        interval = _minInterval();
      } on Object {
        // Can't resolve the cadence (e.g. no active-country graph in a
        // harness) — be conservative and reuse rather than risk hammering.
        return _cached;
      }
      if (_now().difference(fetchedAt) < interval) return _cached;
    }
    try {
      final data = await _fetch(lat, lng, radiusKm);
      _cached = data;
      _cellKey = cell;
      _fetchedAt = _now();
      return _cached;
    } on Object {
      // Degrade to the last good merge — a transient fetch failure must never
      // collapse the surface to "no stations".
      return _cached;
    }
  }

  String _cell(double lat, double lng, double radiusKm) =>
      '$radiusKm:${lat.toStringAsFixed(cellDecimals)},'
      '${lng.toStringAsFixed(cellDecimals)}';
}
