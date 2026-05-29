// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../../features/search/domain/entities/station.dart';

/// One just-in-time price fetch for a single imminent station — the caller
/// supplies this, routed through the per-service rate limiter
/// ([FuelServicePolicy.minInterval]) by the chain. Returns the station with
/// fresh prices, or null when the price could not be fetched.
typedef PriceFetch = Future<Station?> Function(Station station);

/// Tier-3 of the Fuel Station Radar (#2283): a short-TTL, dedup cache for the
/// volatile bit — the *price* of the station the driver is approaching.
///
/// Station locations come from the long-TTL corridor cache (tier-1) and feed
/// an entirely local geofence (tier-2). Only when the geofence fires
/// "approaching X" do we need a price, and only for that one station. This
/// cache makes that fetch:
///
///  - **just-in-time** — a price is fetched only on approach, never speculatively
///    for the whole corridor;
///  - **deduped** — within [ttl] a repeat approach to the same station returns
///    the cached priced station with no second network call (a re-entry after
///    the exit grace, or a slow drive-by that re-crosses the radius, must not
///    re-hit the rate-limited upstream);
///  - **coalesced** — concurrent approaches to the same station (e.g. two GPS
///    samples back-to-back) share one in-flight fetch.
///
/// The cache stores the fully-priced [Station] so the radar/approach overlay
/// can read `station.priceFor(fuel)` directly with no extra plumbing.
class JitPriceCache {
  /// Default short TTL for a fetched price. Matches the tightest polled-source
  /// `searchResultTtl` (DE/KR 5 min) — long enough to dedup a re-entry within
  /// one approach, short enough that a price shown on a later approach is still
  /// current.
  static const Duration defaultTtl = Duration(minutes: 5);

  final PriceFetch _fetchPrice;
  final Duration _ttl;
  final DateTime Function() _now;

  final Map<String, _PricedEntry> _entries = {};
  final Map<String, Future<Station?>> _inFlight = {};

  JitPriceCache({
    required PriceFetch fetchPrice,
    Duration ttl = defaultTtl,
    DateTime Function()? now,
  })  : _fetchPrice = fetchPrice,
        _ttl = ttl,
        _now = now ?? DateTime.now;

  /// `true` when [stationId] has a fresh (within [ttl]) cached price.
  bool isFresh(String stationId) {
    final e = _entries[stationId];
    if (e == null) return false;
    return _now().difference(e.fetchedAt) <= _ttl;
  }

  /// Return [station] with a fresh price for display in the approach overlay.
  ///
  ///  - If a fresh price is cached, returns the cached priced station with no
  ///    network call (dedup).
  ///  - If a fetch for the same station is already in flight, awaits it
  ///    (coalesce).
  ///  - Otherwise issues one JIT price fetch (rate-limited upstream), caches
  ///    the result, and returns it. On a failed/empty fetch returns the
  ///    location-only [station] unchanged so the overlay still shows the name
  ///    and distance with a "—" price rather than nothing.
  Future<Station> priceFor(Station station) async {
    final cached = _entries[station.id];
    if (cached != null && _now().difference(cached.fetchedAt) <= _ttl) {
      return cached.station;
    }

    final existing = _inFlight[station.id];
    if (existing != null) {
      final priced = await existing;
      return priced ?? station;
    }

    final future = _fetchPrice(station);
    _inFlight[station.id] = future;
    try {
      final priced = await future;
      if (priced != null) {
        _entries[station.id] =
            _PricedEntry(station: priced, fetchedAt: _now());
        return priced;
      }
      return station;
    } on Object {
      return station;
    } finally {
      unawaited(_inFlight.remove(station.id) ?? Future<Station?>.value());
    }
  }

  /// Drop stale entries (older than [ttl]). Cheap housekeeping the caller can
  /// run periodically; not required for correctness ([priceFor] re-checks age).
  void evictStale() {
    final now = _now();
    _entries.removeWhere((_, e) => now.difference(e.fetchedAt) > _ttl);
  }
}

class _PricedEntry {
  final Station station;
  final DateTime fetchedAt;
  const _PricedEntry({required this.station, required this.fetchedAt});
}
