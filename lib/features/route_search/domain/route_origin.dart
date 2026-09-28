// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/error/guarded.dart';
import '../../../core/location/location_service.dart';
import '../../../core/location/position_fix_policy.dart';
import '../../../core/services/location_search_service.dart';
import '../../../core/time/app_clock.dart';
import '../../../core/utils/geo_utils.dart';
import 'entities/route_info.dart';

// #4432 — the freshness policy moved to core so the route map's device
// marker judges fixes by the same thresholds; re-exported so the
// origin's callers and tests keep one import.
export '../../../core/location/position_fix_policy.dart'
    show acceptAsCurrentFix, kRouteOriginMaxAccuracyMeters,
        kRouteOriginMaxFixAge;

/// Watchdog over one origin acquisition (#4432).
///
/// It does NOT shorten acquisition: [LocationService.getCurrentPosition]
/// asks the platform for a `medium`-accuracy fix with its own 30 s limit
/// (#3116 — a cold lock on an A11 iPhone routinely exceeds 10 s), and
/// that window is preserved deliberately. This is the outer bound for
/// the case where the platform's own limit does not fire at all, so a
/// tapped search can never hang forever; it degrades to the stored
/// origin with its age instead.
const Duration kRouteOriginAcquireWatchdog = Duration(seconds: 32);

/// Where a resolved "current position" origin came from (#4432).
enum RouteOriginFreshness {
  /// A sample measured within [kRouteOriginMaxFixAge] of now, accurate
  /// enough to route from.
  fresh,

  /// No usable new measurement: the read failed, timed out, came back
  /// degenerate, came back too old or came back too coarse. The
  /// coordinate is the previously stored one and
  /// [ResolvedRouteOrigin.age] says how old it is. It is a FIXED
  /// previous position, and must be presented as one.
  stale,

  /// Neither a usable measurement nor a usable stored one.
  none,
}

/// Why no fresh position could be read (#4432) — one per remedy the
/// driver has: grant the permission, switch the service on, try again,
/// or type a start instead. A silent "GPS error" offered none of them.
enum RouteOriginFailure {
  permissionDenied,
  serviceDisabled,
  timeout,

  /// A sample came back, but measured too long ago to be "where I am".
  staleFix,

  /// A sample came back, but too imprecise to route from.
  poorAccuracy,

  /// Anything else — a degenerate coordinate, a platform error.
  unavailable,
}

/// Classify a failed acquisition by the exception it threw (#4432).
RouteOriginFailure classifyOriginError(Object error) {
  if (error is TimeoutException) return RouteOriginFailure.timeout;
  if (error is PermissionDeniedException) {
    return RouteOriginFailure.permissionDenied;
  }
  if (error is LocationServiceDisabledException) {
    return RouteOriginFailure.serviceDisabled;
  }
  if (error is LocationException) {
    return switch (error.reason) {
      LocationFailureReason.serviceDisabled =>
        RouteOriginFailure.serviceDisabled,
      LocationFailureReason.permissionDenied ||
      LocationFailureReason.permissionDeniedForever =>
        RouteOriginFailure.permissionDenied,
      LocationFailureReason.degenerateFix || null =>
        RouteOriginFailure.unavailable,
    };
  }
  return RouteOriginFailure.unavailable;
}

/// Classify a sample that came back but was not accepted (#4432).
RouteOriginFailure _failureOfRejection(FixRejection rejection) =>
    switch (rejection) {
      FixRejection.tooOld ||
      FixRejection.fromTheFuture =>
        RouteOriginFailure.staleFix,
      FixRejection.tooCoarse => RouteOriginFailure.poorAccuracy,
      FixRejection.unusableCoordinate => RouteOriginFailure.unavailable,
    };

/// The origin a route search will actually use, and what it is worth
/// (#4432).
class ResolvedRouteOrigin {
  const ResolvedRouteOrigin({
    required this.coords,
    required this.freshness,
    required this.age,
    this.failure,
  });

  const ResolvedRouteOrigin.none({
    this.failure = RouteOriginFailure.unavailable,
  })  : coords = null,
        freshness = RouteOriginFreshness.none,
        age = Duration.zero;

  final LatLng? coords;
  final RouteOriginFreshness freshness;

  /// How long ago [coords] was MEASURED — from the fix's own timestamp,
  /// not from when some code last called a method.
  final Duration age;

  /// Why no fresh fix was obtained; null exactly when the origin is
  /// [RouteOriginFreshness.fresh].
  final RouteOriginFailure? failure;

  bool get isStale => freshness == RouteOriginFreshness.stale;
}

/// Resolve the origin of a "current position" route search, afresh, at
/// submission time.
///
/// ## Why a re-read and not a live subscription
///
/// The origin is consumed exactly once per submitted search, so a fix
/// accepted at the moment of consumption is by definition the one that
/// search is about; a subscription would only make it current *earlier*,
/// at the cost of holding GPS open for as long as the criteria sheet is
/// on screen. Every other one-shot-origin surface in the app
/// (`searchByGps`, `UserPosition.updateFromGps`) reads through
/// [LocationService.getCurrentPosition] the same way. (Watching the
/// driver's progress WHILE route results are on screen is a different
/// job with a different lifecycle — the shared position stream — and is
/// not this function.)
///
/// ## The method returning is not evidence of a new fix
///
/// The returned sample is validated, not trusted: [isUsableCoord]
/// (#2872) for the coordinate, [kRouteOriginMaxFixAge] against its own
/// `timestamp` read through [clock], and
/// [kRouteOriginMaxAccuracyMeters] for its estimated accuracy. Anything
/// that fails — plus a refused permission, a disabled service or an
/// acquisition slower than [kRouteOriginAcquireWatchdog] — degrades to
/// [stored] as an explicitly aged previous position. The #2872 guard is
/// applied to the stored coordinate too: a refresh path must not become
/// a new way to route from the Gulf of Guinea.
Future<ResolvedRouteOrigin> resolveCurrentPositionOrigin({
  required LocationService locationService,
  required AppClock clock,
  required LatLng? stored,
  required DateTime? capturedAt,
  Duration watchdog = kRouteOriginAcquireWatchdog,
}) async {
  RouteOriginFailure failure;
  try {
    final position =
        await locationService.getCurrentPosition().timeout(watchdog);
    final rejection = rejectFix(position, clock.now());
    if (rejection == null) {
      return ResolvedRouteOrigin(
        coords: LatLng(position.latitude, position.longitude),
        freshness: RouteOriginFreshness.fresh,
        age: Duration.zero,
      );
    }
    failure = _failureOfRejection(rejection);
  } catch (e, st) {
    // #2146 — the exportable log; the search carries on with the stored
    // origin rather than failing.
    logFailure(e, st, where: 'resolveCurrentPositionOrigin');
    failure = classifyOriginError(e);
  }

  if (stored == null || !isUsableCoord(stored.latitude, stored.longitude)) {
    return ResolvedRouteOrigin.none(failure: failure);
  }
  final since = capturedAt;
  return ResolvedRouteOrigin(
    coords: stored,
    freshness: RouteOriginFreshness.stale,
    age: since == null ? Duration.zero : clock.now().difference(since),
    failure: failure,
  );
}

/// Capture an origin for the GPS button, stamped with the fix's OWN
/// measurement time (#4432).
///
/// Distinct from [resolveCurrentPositionOrigin] because there is nothing
/// stored to fall back to yet: a usable coordinate is adopted even when
/// the platform answered from a cached sample, but it is then returned
/// as [RouteOriginFreshness.stale] with its real age so the field can
/// say so rather than claiming "Current location". Returns
/// [ResolvedRouteOrigin.none] on a refused permission, a disabled
/// service or a degenerate #2872 coordinate — the caller shows the GPS
/// error and leaves the field for manual entry.
///
/// No watchdog here, unlike [resolveCurrentPositionOrigin]: this runs
/// fire-and-forget while the driver fills the form, so a slow lock
/// blocks nothing and the service's own 30 s limit (#3116) is the right
/// and only bound. The watchdog exists for the submission path, where a
/// stalled acquisition would be a stalled search.
Future<ResolvedRouteOrigin> captureCurrentPositionOrigin({
  required LocationService locationService,
  required AppClock clock,
}) async {
  try {
    final position = await locationService.getCurrentPosition();
    // #2872 — defence in depth behind getCurrentPosition's own guard: a
    // (0,0)/(lat,0) origin makes OSRM route from the Gulf of Guinea and
    // centres the route map in the Sahara.
    if (!isUsableCoord(position.latitude, position.longitude)) {
      return const ResolvedRouteOrigin.none();
    }
    final now = clock.now();
    final rejection = rejectFix(position, now);
    final current = rejection == null;
    final measuredAgo = now.difference(position.timestamp);
    return ResolvedRouteOrigin(
      coords: LatLng(position.latitude, position.longitude),
      freshness:
          current ? RouteOriginFreshness.fresh : RouteOriginFreshness.stale,
      age: current || measuredAgo.isNegative ? Duration.zero : measuredAgo,
      failure: current ? null : _failureOfRejection(rejection),
    );
  } catch (e, st) {
    logFailure(e, st, where: 'captureCurrentPositionOrigin');
    return ResolvedRouteOrigin.none(failure: classifyOriginError(e));
  }
}

/// Assemble the OSRM waypoint list, or null when an anchor is unusable.
///
/// #2872 — a required endpoint that is missing OR degenerate (`(0,0)`, a
/// one-axis-unacquired `(lat,0)`, or out-of-range) must not reach OSRM:
/// it would route from the Gulf of Guinea and centre the route map in
/// the Sahara. Null tells the caller to ask for a manual entry. A
/// degenerate OPTIONAL stop is dropped silently instead — start and end
/// are the anchors, and a `?? 0`-fallback geocode should not bend the
/// route to null island.
///
/// #4432 — [originIsVehiclePosition] marks the start waypoint as the
/// driver's own position, which is what lets the corridor run from the
/// driver onward instead of in both directions.
List<RouteWaypoint>? buildRouteWaypoints({
  required LatLng? start,
  required String startLabel,
  required LatLng? end,
  required String endLabel,
  required List<LatLng?> stops,
  required List<String> stopLabels,
  bool originIsVehiclePosition = false,
}) {
  if (start == null ||
      end == null ||
      !isUsableCoord(start.latitude, start.longitude) ||
      !isUsableCoord(end.latitude, end.longitude)) {
    return null;
  }
  return <RouteWaypoint>[
    RouteWaypoint(
      lat: start.latitude,
      lng: start.longitude,
      label: startLabel,
      isVehiclePosition: originIsVehiclePosition,
    ),
    for (var i = 0; i < stops.length; i++)
      if (stops[i] case final stop?)
        if (isUsableCoord(stop.latitude, stop.longitude))
          RouteWaypoint(
            lat: stop.latitude,
            lng: stop.longitude,
            label: i < stopLabels.length ? stopLabels[i] : '',
          ),
    RouteWaypoint(lat: end.latitude, lng: end.longitude, label: endLabel),
  ];
}

/// Geocode [text] into a coordinate when [current] has none yet.
///
/// Returns [current] unchanged when it is already resolved, when the
/// field is empty, or when the city search comes back with nothing —
/// the three "leave it alone" cases the route input repeated verbatim
/// for start, destination and each stop.
Future<LatLng?> geocodeIfNeeded(
  LocationSearchService service,
  LatLng? current,
  String text,
) async {
  if (current != null || text.isEmpty) return current;
  final results = await service.searchCities(text);
  if (results.isEmpty) return current;
  return LatLng(results.first.lat, results.first.lng);
}
