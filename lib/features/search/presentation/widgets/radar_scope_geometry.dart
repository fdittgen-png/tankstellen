// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math';
import 'dart:ui' show Offset;

import '../../../../core/domain/station.dart';
import '../../../../core/utils/geo_utils.dart';

/// A station placed on the PPI radar scope relative to the user at the centre
/// (#3342). Pure value — no painting — so the polar mapping is unit-testable.
class RadarBlip {
  const RadarBlip({
    required this.station,
    required this.fraction,
    required this.bearingDeg,
    required this.distanceKm,
    required this.beyondRange,
    this.price,
    this.aggregatedCount = 1,
  });

  final Station station;

  /// Normalised radial position: 0 = centre (user), 1 = the outer ring
  /// (= the search radius). Out-of-range stations clamp to 1.
  final double fraction;

  /// Bearing from the user, degrees clockwise from North (which is "up" on a
  /// North-up scope). The view applies the heading rotation for display.
  final double bearingDeg;

  final double distanceKm;

  /// True when the station is farther than the range and was clamped to the
  /// rim (so the UI can render it dimmer / on the edge).
  final bool beyondRange;

  /// Price for the active fuel type (#3354), or null when unpriced. The view
  /// renders this instead of a plain dot, and clustering keeps the lowest.
  final double? price;

  /// #3354 — how many overlapping stations this blip stands in for after
  /// [aggregateOverlapping] collapsed a cluster to its cheapest member. 1 when
  /// it represents only itself.
  final int aggregatedCount;

  /// Unit-scope offset (centre = origin, rim = ±1) in screen coords (East =
  /// +x, North = −y), rotated so [headingDeg] points UP (#3354). A station
  /// dead ahead of the driver then sits at the top of the scope. Pass 0 for
  /// the North-up default.
  Offset unitOffset({double headingDeg = 0}) {
    final a = (bearingDeg - headingDeg) * pi / 180;
    return Offset(fraction * sin(a), -fraction * cos(a));
  }

  /// North-up x (kept for the existing tests / default orientation).
  double get unitDx => unitOffset().dx;

  /// North-up y.
  double get unitDy => unitOffset().dy;

  RadarBlip _asAggregate(int count) => RadarBlip(
        station: station,
        fraction: fraction,
        bearingDeg: bearingDeg,
        distanceKm: distanceKm,
        beyondRange: beyondRange,
        price: price,
        aggregatedCount: count,
      );
}

/// Map [stations] to scope blips around `(centerLat, centerLng)`, with the
/// outer ring at [rangeKm]. Stations beyond the range clamp to the rim.
/// [priceOf] resolves each station's price for the active fuel type (#3354).
/// Returns empty when the range is non-positive or the centre is unusable.
List<RadarBlip> radarScopeBlips(
  List<Station> stations,
  double centerLat,
  double centerLng,
  double rangeKm, {
  double? Function(Station station)? priceOf,
}) {
  if (rangeKm <= 0 || !isUsableCoord(centerLat, centerLng)) {
    return const <RadarBlip>[];
  }
  final blips = <RadarBlip>[];
  for (final s in stations) {
    if (!isUsableCoord(s.lat, s.lng)) continue;
    final dKm = distanceKm(centerLat, centerLng, s.lat, s.lng);
    final beyond = dKm > rangeKm;
    blips.add(
      RadarBlip(
        station: s,
        fraction: beyond ? 1.0 : (dKm / rangeKm).clamp(0.0, 1.0),
        bearingDeg: bearingDegrees(centerLat, centerLng, s.lat, s.lng),
        distanceKm: dKm,
        beyondRange: beyond,
        price: priceOf?.call(s),
      ),
    );
  }
  return blips;
}

/// #3354 — collapse blips whose scope positions are within [minSeparation]
/// (unit-scope distance) into a single representative carrying the LOWEST
/// price, so overlapping price labels don't pile up. Pairwise distances are
/// rotation-invariant, so clustering on the North-up offsets matches the
/// rotated (heading-up) display. Greedy, cheapest-first: the cheapest blip
/// seeds a cluster and absorbs every still-unclaimed neighbour within
/// [minSeparation]; the representative keeps the seed's (cheapest) price and an
/// [RadarBlip.aggregatedCount] of the cluster size. Unpriced blips sort last so
/// a real price always wins a cluster.
List<RadarBlip> aggregateOverlapping(
  List<RadarBlip> blips, {
  double minSeparation = 0.16,
}) {
  if (blips.length < 2) return blips;
  // Cheapest first; unpriced (null) last, then nearer-first as a tiebreak.
  final order = [...blips]..sort((a, b) {
      final pa = a.price, pb = b.price;
      if (pa != null && pb != null && pa != pb) return pa.compareTo(pb);
      if (pa == null && pb != null) return 1;
      if (pa != null && pb == null) return -1;
      return a.fraction.compareTo(b.fraction);
    });
  final claimed = List<bool>.filled(order.length, false);
  final out = <RadarBlip>[];
  final minSepSq = minSeparation * minSeparation;
  for (var i = 0; i < order.length; i++) {
    if (claimed[i]) continue;
    claimed[i] = true;
    final seed = order[i];
    final seedPos = seed.unitOffset();
    var count = 1;
    for (var j = i + 1; j < order.length; j++) {
      if (claimed[j]) continue;
      final d = order[j].unitOffset() - seedPos;
      if (d.dx * d.dx + d.dy * d.dy <= minSepSq) {
        claimed[j] = true;
        count++;
      }
    }
    out.add(count > 1 ? seed._asAggregate(count) : seed);
  }
  return out;
}
