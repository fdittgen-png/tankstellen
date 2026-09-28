// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'geo_utils.dart';

/// How far, in km, the off-route distance must rise between two passes
/// of the route before they count as two separate OCCURRENCES of the
/// same station (#4432).
///
/// A loop, a U-shaped route or a road driven twice brings the route
/// past one station more than once, at very different progress values.
/// A vertex-nearest search picks whichever pass happens to be a few
/// metres closer, which is how a station legitimately met AFTER the
/// loop was ordered — or retired — as if it were the first pass. Two
/// local minima of the off-route distance are distinct passes when the
/// route moves at least this far away from the station between them.
/// 1 km is well above the lateral wobble of one carriageway and well
/// below the separation of two genuinely different passes.
const double kRouteOccurrenceProminenceKm = 1.0;

/// How far behind the start (or past the end) a point may sit and still
/// count as AT that endpoint (#4432).
///
/// A point just behind the start clamps to progress zero; `progress >= 0`
/// alone would admit a forecourt the driver has just passed. The
/// tolerance keeps the stop at the actual origin reachable — the fix
/// that placed the origin may itself be up to 500 m off
/// (`kRouteOriginMaxAccuracyMeters`), so anything tighter would reject
/// the station the driver is standing at.
const double kRouteEndpointToleranceKm = 0.5;

/// Length of route, in km, that defines the direction of travel at each
/// endpoint when deciding "behind the start" / "past the end" (#4432).
///
/// Not the first segment's direction: OSRM snaps the origin onto the
/// nearest road, so the first segment can be a 20 m stub leaving a car
/// park at any angle. Half a kilometre of route is the heading the
/// driver actually leaves on.
const double kRouteHeadingBaselineKm = 0.5;

/// Kilometres per degree of latitude on the mean-radius sphere the rest
/// of the geo layer uses.
const double _kmPerDegree = 6371 * math.pi / 180;

/// Where along the route a projected point sits (#4432).
enum RouteProjectionStatus {
  /// The foot point lies on the route itself.
  onRoute,

  /// The point sits behind the start, against the direction of travel.
  beforeStart,

  /// The point sits past the end of the route.
  beyondEnd,
}

/// One pass of the route past a point (#4432).
@immutable
class RouteOccurrence {
  const RouteOccurrence({
    required this.alongKm,
    required this.offRouteKm,
    required this.segmentIndex,
    this.status = RouteProjectionStatus.onRoute,
    this.overhangKm = 0,
  });

  /// Progress, in km from the start, of the point on the route nearest
  /// to the station on this pass — clamped to `[0, totalKm]`.
  final double alongKm;

  /// Crow-flies distance from the station to that foot point: a ONE-WAY
  /// geometric figure, not a road detour.
  final double offRouteKm;

  /// Index of the route segment the foot point lies on.
  final int segmentIndex;

  final RouteProjectionStatus status;

  /// For [RouteProjectionStatus.beforeStart] / `beyondEnd`: how far
  /// behind the start / past the end the station sits along the
  /// endpoint's direction of travel. Zero on the route.
  final double overhangKm;

  /// Behind the start by more than [kRouteEndpointToleranceKm]: already
  /// passed, or reachable only by turning back. The clamp to progress
  /// zero must not make it look reachable.
  bool get isBehindStart =>
      status == RouteProjectionStatus.beforeStart &&
      overhangKm > kRouteEndpointToleranceKm;

  @override
  String toString() => 'RouteOccurrence(along: ${alongKm.toStringAsFixed(3)}, '
      'off: ${offRouteKm.toStringAsFixed(3)}, seg: $segmentIndex, '
      '${status.name}, overhang: ${overhangKm.toStringAsFixed(3)})';
}

/// Where a station sits ALONG a route, and how far off it (#4146, #4432).
///
/// The one along-route calculation for the provider, the search
/// isolates and the presentation (#4432 — the corridor filter, the list
/// order, the map's launch order and the planner each used to carry
/// their own nearest-VERTEX walk). It converts the polyline into
/// cumulative kilometres once and then projects each station onto the
/// route's SEGMENTS, so a station midway along a sparse 30 km segment
/// sits at its true progress and near-zero offset rather than at the
/// nearer vertex 15 km away.
@immutable
class RouteProjection {
  /// Build the cumulative-distance and per-segment tables for [polyline].
  ///
  /// O(n) once, then O(n) cheap planar operations per station: each
  /// segment is projected in a local equirectangular frame (accurate to
  /// well under 1 % at segment scale), and only the chosen foot point is
  /// measured with the haversine the rest of the app uses.
  factory RouteProjection(List<LatLng> polyline) {
    if (polyline.isEmpty) {
      return const RouteProjection._([], [], [], [], []);
    }
    final n = polyline.length;
    final cumulative = List<double>.filled(n, 0);
    final segs = n - 1;
    final segCos = List<double>.filled(segs, 0);
    final segDx = List<double>.filled(segs, 0);
    final segDy = List<double>.filled(segs, 0);
    for (var i = 1; i < n; i++) {
      final a = polyline[i - 1];
      final b = polyline[i];
      cumulative[i] = cumulative[i - 1] +
          distanceKm(a.latitude, a.longitude, b.latitude, b.longitude);
      final c = math.cos((a.latitude + b.latitude) / 2 * math.pi / 180);
      segCos[i - 1] = c;
      segDx[i - 1] = (b.longitude - a.longitude) * c * _kmPerDegree;
      segDy[i - 1] = (b.latitude - a.latitude) * _kmPerDegree;
    }
    return RouteProjection._(polyline, cumulative, segCos, segDx, segDy);
  }

  const RouteProjection._(
    this.points,
    this.cumulative,
    this._segCos,
    this._segDx,
    this._segDy,
  );

  final List<LatLng> points;

  /// Kilometres from the start at each polyline point.
  final List<double> cumulative;

  final List<double> _segCos;
  final List<double> _segDx;
  final List<double> _segDy;

  /// Total route length by the polyline's own geometry.
  ///
  /// Deliberately NOT the routing service's reported distance: a plan's
  /// positions and its total have to come from the same measurement, or
  /// the last stop can land beyond the end of the route.
  double get totalKm => cumulative.isEmpty ? 0 : cumulative.last;

  bool get isEmpty => points.isEmpty;

  /// Project a station onto the route: its ITINERARY occurrence
  /// ([itineraryOccurrence] with no corridor or progress limit).
  ///
  /// [alongKm] is how far from the start the station is met; [offRouteKm]
  /// is the crow-flies deviation from the route to the station — a
  /// ONE-WAY figure, which the planner doubles because a detour means
  /// leaving and rejoining.
  ({double alongKm, double offRouteKm}) project(double lat, double lng) {
    if (points.isEmpty) return (alongKm: 0, offRouteKm: 0);
    final at = itineraryOccurrence(lat, lng, rejectBehindStart: false)!;
    return (alongKm: at.alongKm, offRouteKm: at.offRouteKm);
  }

  /// Every separate pass of the route past ([lat], [lng]) within
  /// [withinKm], in route order.
  ///
  /// A pass is a local minimum of the segment distance; two minima are
  /// separate passes only when the route moves at least
  /// [kRouteOccurrenceProminenceKm] further away between them, so the
  /// wobble of a winding road is one pass and a loop's second visit is
  /// another.
  List<RouteOccurrence> occurrences(
    double lat,
    double lng, {
    double withinKm = double.infinity,
  }) {
    if (points.isEmpty) return const [];
    if (points.length == 1) {
      final p = points.first;
      final off = distanceKm(lat, lng, p.latitude, p.longitude);
      if (off > withinKm) return const [];
      return [RouteOccurrence(alongKm: 0, offRouteKm: off, segmentIndex: 0)];
    }

    final minima = <int>[];
    var armed = true;
    var bestIdx = -1;
    var bestOff = double.infinity;
    var peak = 0.0;
    for (var i = 0; i < _segDx.length; i++) {
      final off = _planarOff(i, lat, lng);
      if (armed) {
        if (off < bestOff) {
          bestOff = off;
          bestIdx = i;
        } else if (off > bestOff + kRouteOccurrenceProminenceKm) {
          if (bestOff <= withinKm) minima.add(bestIdx);
          armed = false;
          peak = off;
        }
      } else {
        if (off > peak) peak = off;
        if (off < peak - kRouteOccurrenceProminenceKm) {
          armed = true;
          bestOff = off;
          bestIdx = i;
        }
      }
    }
    if (armed && bestIdx >= 0 && bestOff <= withinKm) minima.add(bestIdx);

    return [
      for (final i in minima)
        if (_occurrenceOn(i, lat, lng) case final o
            when o.offRouteKm <= withinKm)
          o,
    ];
  }

  /// The pass at which the route actually meets the station, or null
  /// when there is none the driver can still use (#4432).
  ///
  /// The single eligibility rule every along-route consumer shares:
  ///
  /// * only passes within [corridorKm] of the route count;
  /// * a pass behind the start by more than [kRouteEndpointToleranceKm]
  ///   is rejected when [rejectBehindStart] — the clamp to progress zero
  ///   does not make a passed forecourt reachable, while the station AT
  ///   the origin stays eligible;
  /// * a pass before [fromKm] — the driver's progress minus its
  ///   hysteresis margin, see `RouteProgressTracker.retiredBeforeKm` —
  ///   is retired;
  /// * of what remains, the EARLIEST pass that is nearly as close as the
  ///   closest one wins, so a loop's later, much closer pass is not
  ///   shadowed by a distant first brush, and a station met again after
  ///   a loop stays eligible even though it is geographically behind.
  ///
  /// A point past the destination keeps its pass at the end of the
  /// route: its overhang is already in [RouteOccurrence.offRouteKm], and
  /// continuing a little past an arrival is a detour like any other —
  /// unlike turning back at the start, which is what a passed stop
  /// costs.
  RouteOccurrence? itineraryOccurrence(
    double lat,
    double lng, {
    double corridorKm = double.infinity,
    double fromKm = 0,
    bool rejectBehindStart = true,
  }) {
    RouteOccurrence? chosen;
    var bestOff = double.infinity;
    final eligible = <RouteOccurrence>[
      for (final o in occurrences(lat, lng, withinKm: corridorKm))
        if (o.alongKm >= fromKm && !(rejectBehindStart && o.isBehindStart)) o,
    ];
    for (final o in eligible) {
      if (o.offRouteKm < bestOff) bestOff = o.offRouteKm;
    }
    for (final o in eligible) {
      if (o.offRouteKm <= bestOff + kRouteOccurrenceProminenceKm) {
        chosen = o;
        break;
      }
    }
    return chosen;
  }

  /// Planar distance, in km, from ([lat], [lng]) to segment [i].
  double _planarOff(int i, double lat, double lng) {
    final (:px, :py, :t) = _local(i, lat, lng);
    final tc = t.clamp(0.0, 1.0);
    final dx = px - tc * _segDx[i];
    final dy = py - tc * _segDy[i];
    return math.sqrt(dx * dx + dy * dy);
  }

  ({double px, double py, double t}) _local(int i, double lat, double lng) {
    final a = points[i];
    final px = (lng - a.longitude) * _segCos[i] * _kmPerDegree;
    final py = (lat - a.latitude) * _kmPerDegree;
    final bx = _segDx[i];
    final by = _segDy[i];
    final len2 = bx * bx + by * by;
    final t = len2 == 0 ? 0.0 : (px * bx + py * by) / len2;
    return (px: px, py: py, t: t);
  }

  RouteOccurrence _occurrenceOn(int i, double lat, double lng) {
    final (px: _, py: _, :t) = _local(i, lat, lng);
    final tc = t.clamp(0.0, 1.0);
    final a = points[i];
    final b = points[i + 1];
    final footLat = a.latitude + tc * (b.latitude - a.latitude);
    final footLng = a.longitude + tc * (b.longitude - a.longitude);
    final off = distanceKm(lat, lng, footLat, footLng);
    final along = cumulative[i] + tc * (cumulative[i + 1] - cumulative[i]);

    if (along <= kRouteHeadingBaselineKm) {
      final behind = -_alongHeading(
        from: points.first,
        to: pointAtKm(math.min(kRouteHeadingBaselineKm, totalKm)),
        lat: lat,
        lng: lng,
      );
      if (behind > 0) {
        return RouteOccurrence(
          alongKm: along,
          offRouteKm: off,
          segmentIndex: i,
          status: RouteProjectionStatus.beforeStart,
          overhangKm: behind,
        );
      }
    }
    if (along >= totalKm - kRouteHeadingBaselineKm) {
      final past = _alongHeading(
        from: pointAtKm(math.max(0, totalKm - kRouteHeadingBaselineKm)),
        to: points.last,
        lat: lat,
        lng: lng,
        measureFromEnd: true,
      );
      if (past > 0) {
        return RouteOccurrence(
          alongKm: along,
          offRouteKm: off,
          segmentIndex: i,
          status: RouteProjectionStatus.beyondEnd,
          overhangKm: past,
        );
      }
    }
    return RouteOccurrence(alongKm: along, offRouteKm: off, segmentIndex: i);
  }

  /// Signed distance, in km, of ([lat], [lng]) along the direction
  /// [from] → [to], measured from [from] (or from [to] when
  /// [measureFromEnd]).
  double _alongHeading({
    required LatLng from,
    required LatLng to,
    required double lat,
    required double lng,
    bool measureFromEnd = false,
  }) {
    final c = math.cos(from.latitude * math.pi / 180);
    final hx = (to.longitude - from.longitude) * c * _kmPerDegree;
    final hy = (to.latitude - from.latitude) * _kmPerDegree;
    final len = math.sqrt(hx * hx + hy * hy);
    if (len == 0) return 0;
    final origin = measureFromEnd ? to : from;
    final px = (lng - origin.longitude) * c * _kmPerDegree;
    final py = (lat - origin.latitude) * _kmPerDegree;
    return (px * hx + py * hy) / len;
  }

  /// The point [km] from the start along the route, clamped to it.
  LatLng pointAtKm(double km) {
    if (points.isEmpty) throw StateError('empty route');
    if (km <= 0 || points.length == 1) return points.first;
    if (km >= totalKm) return points.last;
    var lo = 0;
    var hi = cumulative.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (cumulative[mid] <= km) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final span = cumulative[hi] - cumulative[lo];
    final t = span == 0 ? 0.0 : (km - cumulative[lo]) / span;
    final a = points[lo];
    final b = points[hi];
    return LatLng(
      a.latitude + t * (b.latitude - a.latitude),
      a.longitude + t * (b.longitude - a.longitude),
    );
  }
}
