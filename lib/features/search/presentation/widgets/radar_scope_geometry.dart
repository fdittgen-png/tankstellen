// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math';

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
  });

  final Station station;

  /// Normalised radial position: 0 = centre (user), 1 = the outer ring
  /// (= the search radius). Out-of-range stations clamp to 1.
  final double fraction;

  /// Bearing from the user, degrees clockwise from North (which is "up").
  final double bearingDeg;

  final double distanceKm;

  /// True when the station is farther than the range and was clamped to the
  /// rim (so the UI can render it dimmer / on the edge).
  final bool beyondRange;

  /// Unit-scope x (centre = 0, rim = ±1), screen coords (East = +x).
  double get unitDx => fraction * sin(bearingDeg * pi / 180);

  /// Unit-scope y (screen coords, down = +y; North = up = −y).
  double get unitDy => -fraction * cos(bearingDeg * pi / 180);
}

/// Map [stations] to scope blips around `(centerLat, centerLng)`, with the
/// outer ring at [rangeKm]. Stations beyond the range clamp to the rim.
/// Returns empty when the range is non-positive or the centre is unusable.
List<RadarBlip> radarScopeBlips(
  List<Station> stations,
  double centerLat,
  double centerLng,
  double rangeKm,
) {
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
      ),
    );
  }
  return blips;
}
