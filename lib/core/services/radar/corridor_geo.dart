// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import '../../domain/station.dart';
import '../../utils/geo_utils.dart' as geo;

/// Pure geometry + corrupted-cache detection helpers for the
/// [CorridorLocationCache] (#2932). Kept out of the cache class so the cache
/// stays under the file-length cap and the validation logic is testable in
/// isolation — no cache state, just maths over the live GPS + the cached set.

/// An axis-aligned bounding box in degree-space.
typedef CorridorBox = ({double minLat, double minLng, double maxLat, double maxLng});

/// Axis-aligned bounding box covering a [radiusKm] circle around [lat]/[lng],
/// in degree-space. Latitude is uniform (~111.32 km/°); longitude shrinks with
/// cos(lat). Used purely for tile bookkeeping, so a slight over-cover is
/// harmless.
CorridorBox corridorBoundingBox(double lat, double lng, double radiusKm) {
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

/// `true` when the cached [stations] must be treated as INVALID for a driver at
/// the live [lat]/[lng] (#2932) — distinct from a plain TTL expiry. The check
/// is GPS-truth: it measures the live fix against the cached station
/// coordinates directly, so a set fetched 50 km away (same coarse 0.5° tile) is
/// rejected rather than served.
///
/// Corrupt when ANY of:
///  - the set is empty (a poisoned/degenerate fetch leaked through), OR
///  - any cached coordinate is the (0,0) null island (a parse/source bug), OR
///  - the NEAREST cached station is beyond `radiusKm × toleranceFactor` from
///    the live GPS — the set belongs to a different area than the driver is in
///    (the 12-km-only / far-station bug).
bool isCorridorCorrupt(
  List<Station> stations,
  double lat,
  double lng,
  double radiusKm,
  double toleranceFactor,
) {
  if (stations.isEmpty) return true;

  final maxMeters = radiusKm * 1000.0 * toleranceFactor;
  var nearest = double.infinity;
  for (final s in stations) {
    // A (0,0) station is a corrupt coordinate, not a real Gulf-of-Guinea
    // forecourt — reject the whole set so it is refetched.
    if (s.lat == 0 && s.lng == 0) return true;
    final d = geo.distanceMeters(lat, lng, s.lat, s.lng);
    if (d < nearest) nearest = d;
  }
  return nearest > maxMeters;
}
