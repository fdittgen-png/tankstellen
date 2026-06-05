// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math';

import 'package:latlong2/latlong.dart';

/// Earth's mean radius in metres (the value the GPS/approach/glide-coach
/// callers have always used for their metre-precision haversine). Kept as
/// a named constant so the metre formula has one source (#2169).
const double earthRadiusMeters = 6371000.0;

/// Whether [lat]/[lng] is a real, usable coordinate fit to drive routing,
/// the route origin, or a persisted user position (#2872).
///
/// A coordinate is usable when it is finite, in range
/// (`|lat| <= 90`, `|lng| <= 180`), and NOT a degenerate GPS fix. The
/// degenerate shapes the issue calls out are:
///   * `(0,0)` — the "null island" sentinel the rest of the geo layer
///     already treats as "unset" (see [distanceKm]'s short-circuit and
///     the per-country parser guards);
///   * a one-axis-unacquired `(lat,0)` / `(0,lng)` — a fix where the
///     device returned one axis but the other is still exactly `0`;
///   * a `NaN`/`Inf` axis.
///
/// Any of these slipping into the route origin makes OSRM route from the
/// Gulf of Guinea so the polyline + bounds span 0°N..42°N and the route
/// map centres in the Sahara. Rejecting them here, at the GPS-*acquisition*
/// boundary the existing station/distance guards never covered, is the fix.
///
/// ## Why an *exact* `0.0` axis is rejected
/// A real GNSS fix reports each axis to many decimal places; an axis that
/// is *exactly* `0.0` is the unacquired-axis sentinel, not a genuine point
/// on the equator / prime meridian. The vanishingly rare legitimate point
/// that lands on `lat == 0` or `lng == 0` to full float precision is a
/// worthwhile trade for never letting a half-acquired fix poison routing —
/// nudging it by a metre yields a usable coordinate. Callers that need a
/// real distance through a genuine `(0,…)` point use [distanceMeters],
/// which has no such guard.
bool isUsableCoord(double lat, double lng) {
  if (!lat.isFinite || !lng.isFinite) return false;
  if (lat == 0 || lng == 0) return false;
  if (lat.abs() > 90 || lng.abs() > 180) return false;
  return true;
}

/// Haversine distance between two coordinates in kilometers.
///
/// Short-circuits a `(0,0)` endpoint to `0` — an unset coordinate is
/// treated as "no distance" by the station-sorting / search callers.
/// Callers that need a real distance for a genuine equator/prime-meridian
/// point (GPS track integration, approach detection) must use
/// [distanceMeters], which has no such guard.
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  if (lat1 == 0 && lng1 == 0) return 0;
  if (lat2 == 0 && lng2 == 0) return 0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
      sin(dLng / 2) * sin(dLng / 2);
  return 6371 * 2 * atan2(sqrt(a), sqrt(1 - a));
}

/// Haversine distance between two coordinates in metres.
///
/// Unlike [distanceKm] this does NOT short-circuit `(0,0)` endpoints —
/// GPS-track and approach callers need a real distance even at the
/// equator/prime meridian. Uses [earthRadiusMeters]; numerically
/// identical to the per-feature copies it replaces (#2169).
double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
      sin(dLng / 2) * sin(dLng / 2);
  return earthRadiusMeters * 2 * atan2(sqrt(a), sqrt(1 - a));
}

/// Computes how far along a polyline a given point is (in km from start).
///
/// Walks the polyline segments, accumulating distance. Returns the cumulative
/// distance to the polyline vertex closest to [lat]/[lng]. For performance,
/// steps through every [step]th vertex on long polylines.
double distanceAlongPolyline(
  double lat,
  double lng,
  List<LatLng> polyline, {
  int? step,
}) {
  if (polyline.isEmpty) return double.infinity;
  final effectiveStep = step ?? (polyline.length > 300 ? 3 : 1);

  double minDist = double.infinity;
  double cumulativeKm = 0;
  double bestCumulativeKm = 0;

  LatLng? prev;
  for (int i = 0; i < polyline.length; i += effectiveStep) {
    final p = polyline[i];
    if (prev != null) {
      cumulativeKm += distanceKm(
        prev.latitude, prev.longitude,
        p.latitude, p.longitude,
      );
    }
    final d = distanceKm(lat, lng, p.latitude, p.longitude);
    if (d < minDist) {
      minDist = d;
      bestCumulativeKm = cumulativeKm;
    }
    prev = p;
  }
  return bestCumulativeKm;
}
