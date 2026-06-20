// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../domain/station.dart';
import '../../telemetry/health_counters.dart';
import 'corridor_geo.dart';
import 'geo_tile.dart';

/// One wide-area station fetch the [CorridorLocationCache] performs — the
/// caller supplies this for the corridor centre + radius and the bulk/polled
/// branch lives behind it (the cache stays storage-agnostic).
typedef CorridorFetch = Future<List<Station>> Function(
  double lat,
  double lng,
  double radiusKm,
);

/// Gate the cache asks before it forces a *staleness/corruption* refetch
/// (#2932). The provider wires this to `ProviderRequestBudget.canFire` so a
/// corrupted-cache invalidation still honours each provider's published
/// frequency/volume rules; when it returns `false` the cache serves the
/// (validated) set rather than hammer the feed. A normal TTL-expiry or
/// first-entry fetch is NOT gated by this — only the forced refetch is.
typedef CorridorRefetchGate = bool Function();

/// Side-effect the cache fires the instant it decides to force a refetch
/// (#2932). The provider wires it to `ProviderRequestBudget.recordRequest`
/// (stamp the shared budget) AND to a staleness-tagged `DataAccessEvent` so the
/// #2824 tracer can tell a corruption-forced refetch apart from a plain TTL
/// refetch.
typedef CorridorRefetchSink = void Function();

/// Tier-1 of the Fuel Station Radar (#2283): a long-TTL cache of station
/// LISTS + geolocations for a wide corridor around the driver.
///
/// ## Why
///
/// The radar must fire "approaching X" by geofencing the live GPS against
/// nearby stations **without a network round-trip on every sample**. Station
/// *locations* are stable (a forecourt doesn't move), so they only need to be
/// fetched once per area and kept for a long TTL; only the *price* is volatile
/// and is fetched just-in-time on approach (tier-3, a separate cache).
///
/// ## What it does
///
///  - On [stationsNear] it returns the cached wide-area station set for the
///    driver's position, refreshing only when the position has moved into a
///    grid tile ([GeoTile]) that the cache does not yet cover, or when the
///    cached set has aged past [ttl].
///  - Coverage bookkeeping uses tiles, not per-station set math: each fetch's
///    bounding box maps to a small rectangle of tile ids ([GeoTile.tilesForBox])
///    added to [coveredTiles]; a GPS sample whose tile is already covered is a
///    pure cache hit (zero network).
///  - When [headingDegrees] is supplied and the driver nears the current
///    tile's edge, the cache also prefetches the tile ahead
///    ([GeoTile.tileAhead]) so the cached corridor always extends in front of
///    the vehicle.
///
/// ## Bulk vs polled
///
/// The cache itself is source-agnostic: the bulk-vs-polled decision lives in
/// the injected [fetchCorridor] callback (the provider passes a closure that
/// geo-filters the persisted national dataset for [SourceModel.bulkFile]
/// countries — zero network — or issues one corridor search for
/// [SourceModel.polledApi]). [isBulk] only tunes the cache's own cadence:
/// a bulk source can refresh aggressively (the data is already local) and
/// skips the edge prefetch (one local filter already returns the whole
/// corridor), while a polled source uses the long [ttl] and prefetches the
/// next tile to amortise the request.
class CorridorLocationCache {
  /// Default corridor fetch radius (km). ~60 km diameter ≈ 120 km of road
  /// coverage, comfortably more than several minutes of highway driving, so a
  /// single fetch keeps the geofence fed for a long stretch. Issue #2283 calls
  /// for a 50–100 km corridor; 60 km radius sits in the middle.
  static const double defaultCorridorRadiusKm = 60.0;

  /// Default long TTL for the cached locations. Forecourts are effectively
  /// static, so an hour between refreshes is conservative; price freshness is
  /// handled separately by the JIT price cache (tier-3).
  static const Duration defaultTtl = Duration(hours: 1);

  /// How far beyond the corridor radius the nearest cached station may sit
  /// before the cache treats the set as corrupted (#2932). 1.2 → a 20 % grace
  /// over the fetch radius, covering GPS jitter + the fetch-centre-vs-live-GPS
  /// offset without false-positiving a genuinely-near station near the edge.
  static const double defaultProximityToleranceFactor = 1.2;

  final CorridorFetch _fetchCorridor;
  final double _corridorRadiusKm;
  final double _tileStepDegrees;
  final Duration _ttl;
  final bool _isBulk;
  final double _proximityToleranceFactor;
  final CorridorRefetchGate? _canRefetch;
  final CorridorRefetchSink? _onRefetch;
  final DateTime Function() _now;

  /// The currently cached wide-area station set. Replaced wholesale on each
  /// refresh (the set is small enough — a corridor, not a country — that a
  /// merge would add complexity for no real benefit).
  List<Station> _stations = const [];

  /// Tiles the current cache covers. A GPS sample whose tile is in here needs
  /// no fetch. Cleared and rebuilt on every refresh.
  final Set<GeoTile> _coveredTiles = {};

  /// When [_stations] was last fetched — drives the [ttl] expiry.
  DateTime? _fetchedAt;

  /// The centre of the most recent *replacing* corridor fetch (#2932). The
  /// proximity validator measures the live GPS against the cached stations
  /// directly (GPS-truth distance), but the centre is kept so a degenerate
  /// fetch (empty set) still has a reference for the staleness check and the
  /// tracer. Null until the first successful non-empty replace.
  double? _fetchCenterLat;
  double? _fetchCenterLng;

  /// Coalesces concurrent refreshes for the same target so a burst of GPS
  /// samples crossing a tile boundary issues a single fetch.
  Future<void>? _inFlight;
  GeoTile? _inFlightTile;

  CorridorLocationCache({
    required CorridorFetch fetchCorridor,
    double corridorRadiusKm = defaultCorridorRadiusKm,
    double tileStepDegrees = GeoTile.defaultStepDegrees,
    Duration ttl = defaultTtl,
    bool isBulk = false,
    double proximityToleranceFactor = defaultProximityToleranceFactor,
    CorridorRefetchGate? canRefetch,
    CorridorRefetchSink? onRefetch,
    DateTime Function()? now,
  })  : _fetchCorridor = fetchCorridor,
        _corridorRadiusKm = corridorRadiusKm,
        _tileStepDegrees = tileStepDegrees,
        _ttl = ttl,
        _isBulk = isBulk,
        _proximityToleranceFactor = proximityToleranceFactor,
        _canRefetch = canRefetch,
        _onRefetch = onRefetch,
        _now = now ?? DateTime.now;

  /// The tiles the cache currently covers (read-only view for bookkeeping /
  /// tests). A position inside any of these is served without a network call.
  Set<GeoTile> get coveredTiles => Set.unmodifiable(_coveredTiles);

  /// The cached wide-area station set (read-only view).
  List<Station> get cachedStations => List.unmodifiable(_stations);

  /// Centre of the most recent replacing corridor fetch (#2932), or null
  /// before the first non-empty fetch. The proximity validator measures the
  /// live GPS against the cached stations directly, but exposing the fetch
  /// centre lets the radar provider tag a staleness-forced `DataAccessEvent`
  /// (#2824) with where the suspect corridor was originally fetched.
  ({double lat, double lng})? get fetchCenter {
    final lat = _fetchCenterLat;
    final lng = _fetchCenterLng;
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }

  /// `true` when a position at [lat]/[lng] would be answered from cache with
  /// no fetch — its tile is covered and the cache has not aged past [ttl].
  bool isFresh(double lat, double lng) {
    final fetchedAt = _fetchedAt;
    if (fetchedAt == null) return false;
    if (_now().difference(fetchedAt) > _ttl) return false;
    final tile = GeoTile.fromLatLng(lat, lng, stepDegrees: _tileStepDegrees);
    return _coveredTiles.contains(tile);
  }

  /// Return the cached wide-area station set for [lat]/[lng], fetching the
  /// corridor first when the position is not yet covered or the cache has
  /// expired. Pass [headingDegrees] so the cache can prefetch the tile ahead
  /// when the driver nears the current tile's edge.
  ///
  /// Never throws: a failed fetch leaves the previous cache in place (so the
  /// geofence keeps working on the last-known corridor) and returns whatever
  /// is cached.
  ///
  /// ### Corrupted-cache detection (#2932)
  ///
  /// A coarse 0.5° tile spans ~55 km, so tile membership alone would serve a
  /// set fetched at one end of the tile to a driver at the other end. On a
  /// cache *hit* the cache therefore re-validates the cached set against the
  /// LIVE GPS [lat]/[lng] ([_isCorrupted]): if the nearest cached station sits
  /// beyond the corridor radius (× the tolerance factor), the set is empty, or
  /// any cached coordinate is the (0,0) null island, the entry is treated as
  /// INVALID — not merely TTL-expired — and a fresh fetch is forced. That
  /// forced refetch is rate-gated ([_canRefetch], wired to the shared provider
  /// budget): if the min-interval has not elapsed, the validated cache is
  /// served rather than the feed hammered.
  Future<List<Station>> stationsNear(
    double lat,
    double lng, {
    double? headingDegrees,
  }) async {
    if (!isFresh(lat, lng)) {
      // Cache miss / TTL expiry — a NORMAL refetch (never rate-gated; the
      // gate only governs the corruption-forced path so the geofence is never
      // starved on a legitimate first entry into an area).
      await _refreshFor(lat, lng);
    } else if (_isCorrupted(lat, lng)) {
      // Cache HIT by tile + TTL, but the set is stale/degenerate for THIS GPS
      // fix. Force a fresh fetch, but only if the shared provider budget
      // allows it — otherwise keep serving the (validated-as-best-available)
      // cache rather than breach the provider's rate limit.
      await _refreshIfBudgetAllows(lat, lng);
    } else if (headingDegrees != null &&
        headingDegrees.isFinite &&
        !_isBulk &&
        _nearTileEdge(lat, lng) &&
        !_aheadCovered(lat, lng, headingDegrees)) {
      // Polled corridor edge prefetch: extend the cached corridor ahead of
      // the vehicle before the driver crosses into an uncovered tile, so the
      // geofence never has to wait on a network fetch mid-approach.
      unawaited(_prefetchAhead(lat, lng, headingDegrees));
    }
    return _stations;
  }

  /// `true` when the cached set must be treated as INVALID for a driver at the
  /// live [lat]/[lng] (#2932) — distinct from a plain TTL expiry. Delegates to
  /// the pure [isCorridorCorrupt] validator (GPS-truth distance over the cached
  /// set vs the corridor radius × tolerance).
  bool _isCorrupted(double lat, double lng) => isCorridorCorrupt(
        _stations,
        lat,
        lng,
        _corridorRadiusKm,
        _proximityToleranceFactor,
      );

  /// Force a fresh corridor fetch for a corruption-invalidated cache (#2932),
  /// but ONLY when the injected rate gate ([_canRefetch], wired to the shared
  /// provider budget) allows it — otherwise serve the cache rather than breach
  /// the provider's published cadence. On a refetch the [_onRefetch] sink
  /// stamps the budget + emits the staleness-tagged tracer event.
  ///
  /// Honours [stationsNear]'s never-throws contract: a faulty injected gate or
  /// sink (e.g. a closed Hive box behind `canFire`) must never break the
  /// geofence — any throw degrades to "serve the validated cache, no refetch".
  Future<void> _refreshIfBudgetAllows(double lat, double lng) async {
    final bool allowed;
    try {
      final gate = _canRefetch;
      allowed = gate == null || gate();
    } on Object {
      return; // Gate faulted — keep serving the cache (geofence survives).
    }
    if (!allowed) return;
    try {
      _onRefetch?.call();
    } on Object {
      // A faulty sink (budget stamp / tracer) must not block the refetch the
      // gate just authorised, nor break the contract — swallow and proceed.
    }
    await _refreshFor(lat, lng);
  }

  /// Blocking refresh centred on [lat]/[lng]; coalesced per target tile.
  Future<void> _refreshFor(double lat, double lng) {
    final targetTile =
        GeoTile.fromLatLng(lat, lng, stepDegrees: _tileStepDegrees);
    final inFlight = _inFlight;
    if (inFlight != null && _inFlightTile == targetTile) return inFlight;

    // #3257 — count corridor (re)fetches so a field export shows whether the
    // radar's location set is being fed (a stalled corridor = silent radar).
    healthCounters.increment('radar.corridorRefetches');
    final future = _doFetch(lat, lng, replace: true);
    _inFlight = future;
    _inFlightTile = targetTile;
    return future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
        _inFlightTile = null;
      }
    });
  }

  /// Background prefetch of the tile ahead — folds the result into the current
  /// cache (does not replace it) so the driver keeps the corridor behind them
  /// while gaining the one in front.
  Future<void> _prefetchAhead(double lat, double lng, double headingDegrees) {
    final here = GeoTile.fromLatLng(lat, lng, stepDegrees: _tileStepDegrees);
    final ahead = here.tileAhead(headingDegrees);
    if (ahead == here) return Future<void>.value();
    return _doFetch(ahead.centerLat, ahead.centerLng, replace: false);
  }

  /// Perform one corridor fetch centred on [lat]/[lng]. When [replace] the
  /// result becomes the new cache and the covered-tile set is rebuilt; when
  /// not (edge prefetch) the result is merged in and the new tiles are added.
  Future<void> _doFetch(
    double lat,
    double lng, {
    required bool replace,
  }) async {
    final List<Station> fetched;
    try {
      fetched = await _fetchCorridor(lat, lng, _corridorRadiusKm);
    } on Object {
      // Keep the previous cache so the geofence survives a network blip.
      return;
    }

    // #2932 — a degenerate (empty) fetch must NOT mark the tile covered and
    // must NOT replace a good corridor: mirror `station_service_chain`'s
    // `isValid: stations.isNotEmpty`. A failed fetch already returned `const []`
    // upstream (the provider catches and returns empty) AND an exception is
    // caught above; both land here as an empty list. Keeping the prior coverage
    // means the next access retries instead of serving a poisoned empty set
    // "covered + fresh" for a full TTL. The geofence keeps the last good
    // corridor in the meantime.
    if (fetched.isEmpty) return;

    final box = corridorBoundingBox(lat, lng, _corridorRadiusKm);
    final tiles = GeoTile.tilesForBox(
      minLat: box.minLat,
      minLng: box.minLng,
      maxLat: box.maxLat,
      maxLng: box.maxLng,
      stepDegrees: _tileStepDegrees,
    );

    if (replace) {
      _stations = fetched;
      _coveredTiles
        ..clear()
        ..addAll(tiles);
      // Record the centre of this replacing fetch as the corridor's GPS-truth
      // reference (#2932) for the proximity validator + the tracer.
      _fetchCenterLat = lat;
      _fetchCenterLng = lng;
    } else {
      // Merge by id so an overlapping prefetch doesn't duplicate stations.
      final byId = {for (final s in _stations) s.id: s};
      for (final s in fetched) {
        byId[s.id] = s;
      }
      _stations = byId.values.toList();
      _coveredTiles.addAll(tiles);
    }
    _fetchedAt = _now();
  }

  /// `true` when the closest covered tile *ahead* of the driver is not yet
  /// covered — i.e. there is something worth prefetching.
  bool _aheadCovered(double lat, double lng, double headingDegrees) {
    final here = GeoTile.fromLatLng(lat, lng, stepDegrees: _tileStepDegrees);
    final ahead = here.tileAhead(headingDegrees);
    return _coveredTiles.contains(ahead);
  }

  /// `true` when [lat]/[lng] sits within [_edgeFraction] of any edge of its
  /// current tile — the trigger window for the edge prefetch.
  bool _nearTileEdge(double lat, double lng) {
    final tile = GeoTile.fromLatLng(lat, lng, stepDegrees: _tileStepDegrees);
    final fracLat = (lat - tile.originLat) / _tileStepDegrees;
    final fracLng = (lng - tile.originLng) / _tileStepDegrees;
    const edge = _edgeFraction;
    return fracLat < edge ||
        fracLat > 1 - edge ||
        fracLng < edge ||
        fracLng > 1 - edge;
  }

  /// How close (as a fraction of tile size) to a tile edge the driver must be
  /// before the edge prefetch fires. 0.25 → the outer quarter on each side.
  static const double _edgeFraction = 0.25;
}
