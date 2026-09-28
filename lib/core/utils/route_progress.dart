// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math' as math;

import 'route_projection.dart';

/// How far, in km, the driver's progress must have moved PAST a
/// station's pass before that pass retires (#4432).
///
/// Retiring on the first sample that projects beyond a station would
/// drop the forecourt the driver is pulling into — the exit lane runs
/// alongside the carriageway for several hundred metres — and a single
/// noisy sample would flip it back and forth. One kilometre is ~30 s at
/// motorway speed: long enough to be past the exit, short enough that a
/// passed stop leaves the recommendations promptly.
const double kRouteRetireMarginKm = 1.0;

/// Furthest, in km beyond its own reported accuracy, a fix may lie from
/// the route and still count as ON it (#4432).
///
/// Roads are drawn down their centre line and a carriageway plus its
/// shoulder spans ~30 m; 300 m absorbs route-geometry simplification
/// without letting a parallel road a few hundred metres away pass as
/// the route.
const double kRouteOnRouteMaxOffKm = 0.3;

/// Consecutive off-route fixes before the driver counts as having LEFT
/// the route (#4432). One fix in a tunnel mouth or an urban canyon is
/// not a departure.
const int kRouteOffRouteConfirmFixes = 2;

/// Worst estimated accuracy, in metres, a fix may carry to move the
/// driver's progress at all (#4432). A coarse fix is recorded as
/// unreliable instead of being matched against the route.
const double kRouteProgressMaxAccuracyMeters = 250;

/// What the latest fix said about the driver's position on the route.
enum RouteProgressStatus {
  /// No fix matched yet.
  unknown,

  /// The fix lies on the route; progress is current.
  onRoute,

  /// Repeated fixes lie away from every pass of the route: the driver
  /// has left it, and route-relative claims need revalidating.
  offRoute,

  /// The fix was too coarse to place on the route.
  unreliable,
}

/// The driver's progress along a route, with hysteresis (#4432).
///
/// Pure and clock-free: the caller validates each fix's age and feeds
/// only accepted ones through [update].
///
/// ## Why progress is matched FORWARD, not globally
///
/// On a loop or where the route crosses itself, the globally nearest
/// point of the route is ambiguous — the crossing is both km 10 and
/// km 40. A driver at km 39 who passes the crossing again must not be
/// thrown back to km 10 (resurrecting every stop between), and a driver
/// at km 9 must not jump to km 40 (retiring every stop between). Each
/// fix is matched to the EARLIEST pass at or after the current progress
/// (less a small backward tolerance for jitter), and progress never
/// moves backward.
///
/// ## Why retirement lags progress
///
/// [retiredBeforeKm] trails progress by the fix's uncertainty plus
/// [kRouteRetireMarginKm] and is itself monotonic, so a pass retires
/// only once the driver is clearly beyond it, and a later coarse or
/// noisy fix can never bring it back.
class RouteProgressTracker {
  RouteProgressTracker(this.projection);

  final RouteProjection projection;

  double _progressKm = 0;
  double _retiredBeforeKm = 0;
  int _offRouteStreak = 0;
  double? _lastOffRouteKm;
  RouteProgressStatus _status = RouteProgressStatus.unknown;

  /// Furthest accepted progress, in km from the route's start.
  double get progressKm => _progressKm;

  /// Passes before this progress are retired — pass it as `fromKm` to
  /// [RouteProjection.itineraryOccurrence].
  double get retiredBeforeKm => _retiredBeforeKm;

  RouteProgressStatus get status => _status;

  /// Distance from the route of the last fix that matched none of its
  /// passes, or null while the driver is on it.
  double? get lastOffRouteKm => _lastOffRouteKm;

  /// Match one accepted fix against the route and return the new status.
  RouteProgressStatus update(
    double lat,
    double lng, {
    double accuracyMeters = 0,
  }) {
    if (projection.isEmpty) return _status;
    final hasAccuracy = accuracyMeters.isFinite && accuracyMeters > 0;
    if (hasAccuracy && accuracyMeters > kRouteProgressMaxAccuracyMeters) {
      return _status = RouteProgressStatus.unreliable;
    }
    final accuracyKm = hasAccuracy ? accuracyMeters / 1000 : 0.0;
    final onRouteKm = kRouteOnRouteMaxOffKm + accuracyKm;
    final backwardSlackKm = onRouteKm + kRouteRetireMarginKm;

    final passes = projection.occurrences(lat, lng, withinKm: onRouteKm);
    RouteOccurrence? match;
    for (final pass in passes) {
      if (pass.alongKm >= _progressKm - backwardSlackKm) {
        match = pass;
        break;
      }
    }

    if (match == null) {
      _offRouteStreak++;
      final nearest = projection.occurrences(lat, lng);
      _lastOffRouteKm = nearest.isEmpty
          ? null
          : nearest.map((o) => o.offRouteKm).reduce(math.min);
      if (_offRouteStreak >= kRouteOffRouteConfirmFixes) {
        _status = RouteProgressStatus.offRoute;
      }
      return _status;
    }

    _offRouteStreak = 0;
    _lastOffRouteKm = null;
    if (match.alongKm > _progressKm) _progressKm = match.alongKm;
    final retired = _progressKm - accuracyKm - kRouteRetireMarginKm;
    if (retired > _retiredBeforeKm) _retiredBeforeKm = retired;
    return _status = RouteProgressStatus.onRoute;
  }
}
