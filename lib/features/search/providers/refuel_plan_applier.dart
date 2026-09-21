// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Handing a chosen plan to navigation (#4363, Epic #4358).
///
/// "Apply this plan" is the moment the app stops advising and starts
/// acting, so it goes through one seam that a test can hold: an injected
/// [RefuelPlanLauncher] receives exactly the origin, destination and
/// ordered stops the OS would be handed, and the gates of #4348 are
/// applied BEFORE anything leaves the app — a reference price stood in
/// at a town centre launches nothing, and so does a stop whose country's
/// price source is declared unavailable.
///
/// Existing route intent is preserved, not replaced: the intermediate
/// stops the driver typed into the route form travel with the plan's
/// stops, every one of them ordered along the route. A plan may add
/// stops; it may not silently drop the ones the driver already chose.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/refuel_plan.dart';
import '../../../core/error/guarded.dart';
import '../../../core/services/station_offer.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/utils/route_projection.dart';
import '../../route_search/api.dart';
import 'refuel_plan_candidates.dart';

/// One point handed to navigation, in route order.
@immutable
class RefuelPlanWaypoint {
  const RefuelPlanWaypoint({
    required this.lat,
    required this.lng,
    required this.alongRouteKm,
    this.stationId,
  });

  final double lat;
  final double lng;
  final double alongRouteKm;

  /// The plan stop this point is, or null for a stop the driver had
  /// already placed on the route themselves.
  final String? stationId;

  bool get isPlanStop => stationId != null;
}

/// Exactly what would be launched.
@immutable
class RefuelPlanLaunch {
  const RefuelPlanLaunch({
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.waypoints,
  });

  final double originLat;
  final double originLng;
  final double destinationLat;
  final double destinationLng;

  /// Ordered along the route: the driver's own stops and the plan's.
  final List<RefuelPlanWaypoint> waypoints;

  Iterable<RefuelPlanWaypoint> get planStops => waypoints.where((w) => w.isPlanStop);
}

/// Why a plan was NOT handed to navigation.
enum RefuelPlanApplyRefusal {
  /// No active route to apply it to.
  noRoute,

  /// A stop is a reference price, not a place (#4348).
  referenceLocation,

  /// A stop's country price source is declared unavailable (#4348).
  providerUnavailable,

  /// The platform refused the launch.
  launchFailed,
}

@immutable
class RefuelPlanApplyResult {
  const RefuelPlanApplyResult.launched(RefuelPlanLaunch this.launch)
      : refusal = null;
  const RefuelPlanApplyResult.refused(RefuelPlanApplyRefusal this.refusal)
      : launch = null;

  final RefuelPlanLaunch? launch;
  final RefuelPlanApplyRefusal? refusal;

  bool get isLaunched => launch != null;
}

typedef RefuelPlanLauncher = Future<bool> Function(RefuelPlanLaunch launch);

/// The production launcher: the same maps handoff the route map uses.
Future<bool> _openInMaps(RefuelPlanLaunch launch) async {
  await NavigationUtils.openRouteInMaps(
    origin: '${launch.originLat},${launch.originLng}',
    destination: '${launch.destinationLat},${launch.destinationLng}',
    waypoints: [for (final w in launch.waypoints) '${w.lat},${w.lng}'],
  );
  return true;
}

/// Injected so a test sees the launch instead of the OS.
final refuelPlanLauncherProvider =
    Provider<RefuelPlanLauncher>((ref) => _openInMaps);

/// Gate, order, launch.
class RefuelPlanApplier {
  RefuelPlanApplier(this._ref);

  final Ref _ref;

  Future<RefuelPlanApplyResult> apply(
    RefuelPlan plan,
    PlanCandidateSet candidates,
  ) async {
    final route = _ref.read(routeSearchStateProvider).value;
    final geometry = route?.route.geometry;
    if (geometry == null || geometry.isEmpty) {
      return const RefuelPlanApplyResult.refused(RefuelPlanApplyRefusal.noRoute);
    }
    final coords = {for (final s in candidates.travelStops) s.id: s};
    final projection = RouteProjection(geometry);
    final waypoints = <RefuelPlanWaypoint>[];

    for (final stop in plan.stops) {
      final id = stop.candidate.stationId;
      final at = coords[id];
      if (at == null) continue;
      // #4348 — the two gates every station action shares, checked here
      // even though the candidate set already excludes both: this is the
      // last point before the OS, and a backstop costs nothing.
      final offer =
          StationOffer.forStation(stationId: id, lat: at.lat, lng: at.lng);
      // A dead source is checked FIRST: a country whose provider is
      // declared unavailable also publishes no coordinates, and "this
      // country's prices are gone" is the truer thing to tell the driver
      // than "that point is a stand-in".
      if (offer.capability?.isUnavailable ?? false) {
        return const RefuelPlanApplyResult.refused(
            RefuelPlanApplyRefusal.providerUnavailable);
      }
      if (!offer.canNavigate) {
        return const RefuelPlanApplyResult.refused(
            RefuelPlanApplyRefusal.referenceLocation);
      }
      waypoints.add(RefuelPlanWaypoint(
        lat: at.lat,
        lng: at.lng,
        alongRouteKm: stop.candidate.alongRouteKm,
        stationId: id,
      ));
    }

    // The driver's own intermediate stops keep their place on the route.
    for (final coord in _ref.read(routeInputControllerProvider).stopCoords) {
      if (coord == null) continue;
      waypoints.add(RefuelPlanWaypoint(
        lat: coord.latitude,
        lng: coord.longitude,
        alongRouteKm:
            projection.project(coord.latitude, coord.longitude).alongKm,
      ));
    }
    waypoints.sort((a, b) => a.alongRouteKm.compareTo(b.alongRouteKm));

    final launch = RefuelPlanLaunch(
      originLat: geometry.first.latitude,
      originLng: geometry.first.longitude,
      destinationLat: geometry.last.latitude,
      destinationLng: geometry.last.longitude,
      waypoints: waypoints,
    );
    try {
      final ok = await _ref.read(refuelPlanLauncherProvider)(launch);
      return ok
          ? RefuelPlanApplyResult.launched(launch)
          : const RefuelPlanApplyResult.refused(
              RefuelPlanApplyRefusal.launchFailed);
    } catch (e, st) {
      logFailure(e, st, where: 'RefuelPlanApplier.apply');
      return const RefuelPlanApplyResult.refused(
          RefuelPlanApplyRefusal.launchFailed);
    }
  }
}

final refuelPlanApplierProvider =
    Provider<RefuelPlanApplier>((ref) => RefuelPlanApplier(ref));
