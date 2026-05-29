// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math' as math;

import '../../../features/search/domain/entities/station.dart';
import '../../utils/geo_utils.dart' as geo;
import 'geo_tile.dart';

/// One wide-area station fetch the [CorridorLocationCache] performs — the
/// caller supplies this for the corridor centre + radius and the bulk/polled
/// branch lives behind it (the cache stays storage-agnostic).
typedef CorridorFetch = Future<List<Station>> Function(
  double lat,
  double lng,
  double radiusKm,
);

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

  final CorridorFetch _fetchCorridor;
  final double _corridorRadiusKm;
  final double _tileStepDegrees;
  final Duration _ttl;
  final bool _isBulk;
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
    DateTime Function()? now,
  })  : _fetchCorridor = fetchCorridor,
        _corridorRadiusKm = corridorRadiusKm,
        _tileStepDegrees = tileStepDegrees,
        _ttl = ttl,
        _isBulk = isBulk,
        _now = now ?? DateTime.now;

  /// The tiles the cache currently covers (read-only view for bookkeeping /
  /// tests). A position inside any of these is served without a network call.
  Set<GeoTile> get coveredTiles => Set.unmodifiable(_coveredTiles);

  /// The cached wide-area station set (read-only view).
  List<Station> get cachedStations => List.unmodifiable(_stations);

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
  Future<List<Station>> stationsNear(
    double lat,
    double lng, {
    double? headingDegrees,
  }) async {
    if (!isFresh(lat, lng)) {
      await _refreshFor(lat, lng);
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

  /// Blocking refresh centred on [lat]/[lng]; coalesced per target tile.
  Future<void> _refreshFor(double lat, double lng) {
    final targetTile =
        GeoTile.fromLatLng(lat, lng, stepDegrees: _tileStepDegrees);
    final inFlight = _inFlight;
    if (inFlight != null && _inFlightTile == targetTile) return inFlight;

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

    final box = _boundingBox(lat, lng, _corridorRadiusKm);
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

  /// Axis-aligned bounding box covering a [radiusKm] circle around
  /// [lat]/[lng], in degree-space. Latitude is uniform (~111.32 km/°);
  /// longitude shrinks with cos(lat). Used purely for tile bookkeeping, so a
  /// slight over-cover is harmless.
  ({double minLat, double minLng, double maxLat, double maxLng}) _boundingBox(
    double lat,
    double lng,
    double radiusKm,
  ) {
    const kmPerDegLat = geo.earthRadiusMeters / 1000.0 * math.pi / 180.0;
    final latDelta = radiusKm / kmPerDegLat;
    final cosLat = math.cos(lat * math.pi / 180.0);
    final clampedCos = cosLat.abs() < 1e-6 ? 1e-6 : cosLat.abs();
    final lngDelta = radiusKm / (kmPerDegLat * clampedCos);
    return (
      minLat: lat - latDelta,
      minLng: lng - lngDelta,
      maxLat: lat + latDelta,
      maxLng: lng + lngDelta,
    );
  }
}
