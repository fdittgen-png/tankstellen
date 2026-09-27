// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/services/routing_service.dart';
import '../domain/entities/route_info.dart';

part 'route_fetcher_provider.g.dart';

/// One driving-route request: the ordered, already-validated waypoints
/// in, the routed polyline out (#4432).
typedef RouteFetcher = Future<RouteInfo> Function(
  List<RouteWaypoint> waypoints,
  bool avoidHighways,
);

/// The single route-fetch seam of the route search (#4432).
///
/// `RouteSearchState` used to construct its [RoutingService] inline, so
/// the one path that matters for a "current position" search — submit
/// or refresh, re-resolve the origin, route from it — could only be
/// tested around the route fetch, never through it. Overriding this
/// provider lets a test record which origin was actually routed and
/// answer with a recorded polyline, without a public endpoint. It is
/// the sibling of `roadDistanceFetcherProvider` and
/// `travelEstimateFetcherProvider`, which already do the same for the
/// `/table` calls.
@Riverpod(keepAlive: true)
RouteFetcher routeFetcher(Ref ref) {
  final service = RoutingService();
  return (waypoints, avoidHighways) async =>
      (await service.getRoute(waypoints, avoidHighways: avoidHighways)).data;
}
