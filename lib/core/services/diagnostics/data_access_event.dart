// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The data-layer choke-points the data-access tracer records (#2824).
///
/// Each value maps to one place a price/station query enters the
/// [StationServiceChain] (or the radar caches), so an exported trace can be
/// grouped by `endpoint` to see which surface drove which upstream traffic.
enum DataAccessEndpoint {
  /// `searchStations` against a geographic centre (lat/lng/radius).
  searchGeo,

  /// `searchStations` driven by a postal code.
  searchPostcode,

  /// `getPrices` — the batch price refresh (favorites / alerts).
  batchPrices,

  /// `getStationDetail` — a single station's full detail payload.
  stationDetail,

  /// A bulk whole-country dataset fetch (local-filtered sources).
  bulkDataset,

  /// A corridor prefetch ahead of the live trip (radar).
  corridorPrefetch,

  /// A just-in-time single-price refresh (radar).
  jitPrice,
}

/// Where the data for one [DataAccessEvent] actually came from (#2824).
///
/// Only [networkApi] consumes a provider's rate-limit budget; every other
/// value was answered locally, so the cache-hit ratio is
/// `1 - networkCount / requestCount`.
enum DataAccessHit {
  /// A live upstream HTTP request hit a data provider.
  networkApi,

  /// Served from a fresh (< TTL) Hive cache entry — no network.
  hiveFresh,

  /// Served from a stale Hive entry after the network attempt failed.
  hiveStale,

  /// Folded into an already-in-flight identical request (coalesced) — no
  /// extra network call.
  coalesced,
}

/// One immutable record of a single data-layer access (#2824).
///
/// Pure data — hand-written [toJson], no codegen — so the diagnostics layer
/// stays dependency-light and the hot-path append in `recordDataAccess` is a
/// single object construction + enqueue.
class DataAccessEvent {
  /// Wall-clock capture time (for the human-readable trace).
  final DateTime at;

  /// Monotonic microsecond reading from the recorder's [Stopwatch]. Wall
  /// clock can jump (NTP, DST); the inter-request interval math uses THIS so
  /// a clock correction can never produce a negative or absurd interval.
  final int monotonicMicros;

  /// ISO country code the query targeted (`FR`, `DE`, …). Empty for legacy
  /// call sites that supply no country.
  final String country;

  /// `ServiceSource.name` of the provider/source that answered.
  final String source;

  /// Which choke-point this access entered through.
  final DataAccessEndpoint endpoint;

  /// Where the data actually came from (network vs a cache tier).
  final DataAccessHit hit;

  /// Number of rows returned, when the payload is a list; null otherwise.
  final int? resultCount;

  /// End-to-end latency of a network call in microseconds; null for cache
  /// hits (no upstream round-trip to time).
  final int? latencyMicros;

  /// Whether the served result was marked stale.
  final bool isStale;

  const DataAccessEvent({
    required this.at,
    required this.monotonicMicros,
    required this.country,
    required this.source,
    required this.endpoint,
    required this.hit,
    this.resultCount,
    this.latencyMicros,
    this.isStale = false,
  });

  /// True only for a live upstream request — the events that consume a
  /// provider's rate-limit budget.
  bool get isNetwork => hit == DataAccessHit.networkApi;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'monotonicMicros': monotonicMicros,
        'country': country,
        'source': source,
        'endpoint': endpoint.name,
        'hit': hit.name,
        if (resultCount != null) 'resultCount': resultCount,
        if (latencyMicros != null) 'latencyMicros': latencyMicros,
        'isStale': isStale,
      };
}
