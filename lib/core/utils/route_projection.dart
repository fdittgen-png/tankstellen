// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'geo_utils.dart';

/// Where a station sits ALONG a route, and how far off it (#4146).
///
/// The route list already sorts stations by their nearest polyline
/// INDEX, which is enough to order them and useless for planning: an
/// index is not a distance, and a refuel plan needs to know that the
/// next station is 180 km ahead rather than "later in the list".
///
/// This converts the polyline into cumulative kilometres once and then
/// answers both questions per station.
@immutable
class RouteProjection {
  /// Build the cumulative-distance table for [polyline].
  ///
  /// O(n) once, then O(n/step) per station — the same sampling the list
  /// sort already uses, because a 740 km route carries thousands of
  /// points and a station's position does not need metre accuracy.
  factory RouteProjection(List<LatLng> polyline) {
    if (polyline.isEmpty) {
      return const RouteProjection._(points: [], cumulative: [], step: 1);
    }
    final cumulative = List<double>.filled(polyline.length, 0);
    for (var i = 1; i < polyline.length; i++) {
      cumulative[i] = cumulative[i - 1] +
          distanceKm(
            polyline[i - 1].latitude,
            polyline[i - 1].longitude,
            polyline[i].latitude,
            polyline[i].longitude,
          );
    }
    return RouteProjection._(
      points: polyline,
      cumulative: cumulative,
      step: polyline.length > 300 ? 3 : 1,
    );
  }

  const RouteProjection._({
    required this.points,
    required this.cumulative,
    required this.step,
  });

  final List<LatLng> points;

  /// Kilometres from the start at each polyline point.
  final List<double> cumulative;

  final int step;

  /// Total route length by the polyline's own geometry.
  ///
  /// Deliberately NOT the routing service's reported distance: a plan's
  /// positions and its total have to come from the same measurement, or
  /// the last stop can land beyond the end of the route.
  double get totalKm => cumulative.isEmpty ? 0 : cumulative.last;

  bool get isEmpty => points.isEmpty;

  /// Project a station onto the route.
  ///
  /// [alongKm] is how far from the start the nearest point is;
  /// [offRouteKm] is the crow-flies deviation from the route to the
  /// station — a ONE-WAY figure, which the planner doubles because a
  /// detour means leaving and rejoining.
  ({double alongKm, double offRouteKm}) project(double lat, double lng) {
    if (points.isEmpty) return (alongKm: 0, offRouteKm: 0);
    var best = double.infinity;
    var bestIdx = 0;
    for (var i = 0; i < points.length; i += step) {
      final d = distanceKm(lat, lng, points[i].latitude, points[i].longitude);
      if (d < best) {
        best = d;
        bestIdx = i;
      }
    }
    return (alongKm: cumulative[bestIdx], offRouteKm: best);
  }
}
