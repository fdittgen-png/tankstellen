// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

/// Fixed-degree grid tiling for radar corridor-cache bookkeeping (#2283).
///
/// The Fuel Station Radar caches the station LIST + geolocations for a wide
/// corridor once, then geofences the live GPS against that cached set with
/// zero network while driving. To decide *what is already cached* (so we
/// don't re-fetch the same area and so we know when to prefetch the next
/// tile at the corridor edge) we need a cheap, stable way to bucket the map
/// — a per-station set difference would be O(stations) on every GPS sample.
///
/// [GeoTile] solves this with a uniform lat/lng grid: the world is divided
/// into square-ish cells [stepDegrees]° on a side, each addressed by its
/// integer `(latIndex, lngIndex)`. A tile id like `t:0.5/247:-46` is a
/// stable, hashable key the corridor cache stores in a `Set<String>` —
/// membership, neighbour enumeration and "which tiles does this corridor
/// cover" all reduce to integer arithmetic.
///
/// ### Why a fixed grid, not geohash
///
/// A classic geohash interleaves lat/lng bits into a base-32 string whose
/// prefix length controls precision. That is great for prefix range scans in
/// a database, but here we only need (a) a stable bucket id and (b) cheap
/// neighbour enumeration to find the next tile ahead. A fixed-degree grid
/// gives both with trivial, exactly-reversible integer math and no base-32
/// edge cases at the poles / antimeridian. [stepDegrees] is chosen so one
/// tile comfortably exceeds a single corridor fetch radius, so a moving
/// driver crosses a tile boundary every few minutes, not every few seconds.
class GeoTile {
  /// Default tile size in degrees. 0.5° latitude ≈ 55 km — large enough that
  /// one corridor fetch (≤ ~100 km diameter) lands inside a handful of tiles,
  /// small enough that "the next tile ahead" is a meaningful prefetch target
  /// rather than the whole country. The radar's corridor cache uses this
  /// unless a caller overrides it.
  static const double defaultStepDegrees = 0.5;

  /// Cell size in degrees (both axes). A tile spans
  /// `[latIndex·step, (latIndex+1)·step)` × `[lngIndex·step, …)`.
  final double stepDegrees;

  /// Integer latitude index — `floor(lat / step)`.
  final int latIndex;

  /// Integer longitude index — `floor(lng / step)`.
  final int lngIndex;

  const GeoTile({
    required this.latIndex,
    required this.lngIndex,
    this.stepDegrees = defaultStepDegrees,
  });

  /// The tile that contains [lat]/[lng] at [stepDegrees] resolution.
  factory GeoTile.fromLatLng(
    double lat,
    double lng, {
    double stepDegrees = defaultStepDegrees,
  }) {
    return GeoTile(
      latIndex: (lat / stepDegrees).floor(),
      lngIndex: (lng / stepDegrees).floor(),
      stepDegrees: stepDegrees,
    );
  }

  /// Stable string id — the key the corridor cache stores in its covered-tile
  /// set. Encodes the step so tiles from two different grid resolutions never
  /// collide. Format: `t:<step>/<latIndex>:<lngIndex>`.
  String get id => 't:$stepDegrees/$latIndex:$lngIndex';

  /// Latitude of the tile's south-west corner.
  double get originLat => latIndex * stepDegrees;

  /// Longitude of the tile's south-west corner.
  double get originLng => lngIndex * stepDegrees;

  /// Latitude of the tile's centre.
  double get centerLat => (latIndex + 0.5) * stepDegrees;

  /// Longitude of the tile's centre.
  double get centerLng => (lngIndex + 0.5) * stepDegrees;

  /// `true` when [lat]/[lng] falls inside this tile's bounds.
  bool contains(double lat, double lng) =>
      GeoTile.fromLatLng(lat, lng, stepDegrees: stepDegrees) == this;

  /// The eight neighbouring tiles (Moore neighbourhood). Used to decide
  /// whether a fetch centred here already covers the tiles a driver could
  /// reach next, and to seed the prefetch target.
  List<GeoTile> neighbours() {
    final out = <GeoTile>[];
    for (var dLat = -1; dLat <= 1; dLat++) {
      for (var dLng = -1; dLng <= 1; dLng++) {
        if (dLat == 0 && dLng == 0) continue;
        out.add(GeoTile(
          latIndex: latIndex + dLat,
          lngIndex: lngIndex + dLng,
          stepDegrees: stepDegrees,
        ));
      }
    }
    return out;
  }

  /// The tile one step in the direction of [headingDegrees] (compass: 0° =
  /// north, 90° = east). The radar prefetches this tile when the driver nears
  /// the current tile's edge so the cached corridor always extends ahead of
  /// the vehicle. Returns the current tile when the heading is non-finite or
  /// the step rounds to no movement.
  GeoTile tileAhead(double headingDegrees) {
    if (!headingDegrees.isFinite) return this;
    final rad = headingDegrees * math.pi / 180.0;
    // North (0°) → +lat; East (90°) → +lng. Round so a heading near a
    // diagonal can step both axes, matching the Moore neighbourhood.
    final dLat = math.cos(rad).round();
    final dLng = math.sin(rad).round();
    if (dLat == 0 && dLng == 0) return this;
    return GeoTile(
      latIndex: latIndex + dLat,
      lngIndex: lngIndex + dLng,
      stepDegrees: stepDegrees,
    );
  }

  /// All tiles whose bounds intersect the axis-aligned bounding box
  /// `[minLat, maxLat] × [minLng, maxLng]`. This is how the corridor cache
  /// records *which tiles a single fetch covers* — the fetch's bounding box
  /// maps to a small rectangle of tile indices, each added to the covered
  /// set so a later GPS sample inside any of them is a cache hit.
  static Set<GeoTile> tilesForBox({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    double stepDegrees = defaultStepDegrees,
  }) {
    final loLat = (math.min(minLat, maxLat) / stepDegrees).floor();
    final hiLat = (math.max(minLat, maxLat) / stepDegrees).floor();
    final loLng = (math.min(minLng, maxLng) / stepDegrees).floor();
    final hiLng = (math.max(minLng, maxLng) / stepDegrees).floor();
    final out = <GeoTile>{};
    for (var la = loLat; la <= hiLat; la++) {
      for (var ln = loLng; ln <= hiLng; ln++) {
        out.add(GeoTile(latIndex: la, lngIndex: ln, stepDegrees: stepDegrees));
      }
    }
    return out;
  }

  @override
  bool operator ==(Object other) =>
      other is GeoTile &&
      other.latIndex == latIndex &&
      other.lngIndex == lngIndex &&
      other.stepDegrees == stepDegrees;

  @override
  int get hashCode => Object.hash(latIndex, lngIndex, stepDegrees);

  @override
  String toString() => id;
}
