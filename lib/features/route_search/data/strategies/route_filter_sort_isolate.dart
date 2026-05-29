// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/geo_utils.dart';
import '../../../search/domain/entities/search_result_item.dart';

/// Shared off-isolate detour-filter + itinerary-sort for the route-search
/// strategies (#2303).
///
/// `UniformSearchStrategy` already moved its `O(N×M)` detour filter and
/// along-polyline sort into a single [compute] hop (#2102). The Cheapest,
/// Balanced and Eco strategies were still running the same two haversine
/// passes on the **UI isolate** — the `minDistanceToPolyline` filter plus a
/// comparator that called `distanceAlongPolyline` for every comparison
/// (`O(N·M·log N)` haversine ops). This helper hoists that work into a
/// background isolate for all three, so the boundary is crossed exactly once
/// per search.
///
/// ### Why not reuse Uniform's private `_filterAndSort`?
/// Uniform filters *every* candidate by min-distance-to-polyline. Cheapest /
/// Balanced / Eco instead pass **non-fuel** results (EV charging stations)
/// through the detour filter unconditionally — they are only sorted, never
/// dropped for being far from the road geometry. The [_PointLite.alwaysKeep]
/// flag carries that exemption across the isolate boundary so behaviour is
/// bit-identical to the previous on-UI-isolate loops.
///
/// The isolate entry + payload deliberately import only `dart:math`-backed
/// `geo_utils.distanceKm` and `latlong2` — no UI-side types cross the
/// boundary; survivors are returned as ids and re-hydrated on the UI side.

/// Filter fuel results by detour distance, keep non-fuel (EV) results, then
/// sort all survivors by itinerary order — in a background isolate.
///
/// [detourLimitKm] bounds how far a *fuel* station may sit from [polyline].
/// Non-fuel results bypass that filter (see class doc). The returned list
/// preserves the caller's original [SearchResultItem] instances, re-hydrated
/// by id in itinerary order. Empty results or polyline short-circuit on the
/// UI isolate (no `compute` hop).
Future<List<SearchResultItem>> filterAndSortAlongRoute({
  required List<SearchResultItem> results,
  required List<LatLng> polyline,
  required double detourLimitKm,
}) async {
  if (results.isEmpty || polyline.isEmpty) return results;

  final coords = <_PointLite>[
    for (final item in results)
      _PointLite(
        id: item.id,
        lat: item.lat,
        lng: item.lng,
        // Only fuel stations are subject to the detour filter; EV results
        // (and any future non-fuel kind) are always kept.
        alwaysKeep: item is! FuelStationResult,
      ),
  ];
  final polyLats =
      List<double>.unmodifiable(polyline.map((p) => p.latitude));
  final polyLngs =
      List<double>.unmodifiable(polyline.map((p) => p.longitude));

  final survivors = await compute(
    _filterAndSortIsolate,
    _RouteFilterSortPayload(
      points: coords,
      polyLats: polyLats,
      polyLngs: polyLngs,
      detourLimitKm: detourLimitKm,
    ),
  );

  final byId = {for (final r in results) r.id: r};
  return [
    for (final id in survivors)
      if (byId[id] != null) byId[id]!,
  ];
}

/// Runs the detour filter + itinerary sort on the UI isolate. Exposed for
/// unit tests; production code reaches it via [filterAndSortAlongRoute].
@visibleForTesting
List<SearchResultItem> filterAndSortAlongRouteSyncForTest({
  required List<SearchResultItem> results,
  required List<LatLng> polyline,
  required double detourLimitKm,
}) {
  if (results.isEmpty || polyline.isEmpty) return results;
  final coords = <_PointLite>[
    for (final item in results)
      _PointLite(
        id: item.id,
        lat: item.lat,
        lng: item.lng,
        alwaysKeep: item is! FuelStationResult,
      ),
  ];
  final survivors = _filterAndSortIsolate(
    _RouteFilterSortPayload(
      points: coords,
      polyLats: polyline.map((p) => p.latitude).toList(growable: false),
      polyLngs: polyline.map((p) => p.longitude).toList(growable: false),
      detourLimitKm: detourLimitKm,
    ),
  );
  final byId = {for (final r in results) r.id: r};
  return [
    for (final id in survivors)
      if (byId[id] != null) byId[id]!,
  ];
}

// ---------------------------------------------------------------------------
// Isolate entry + payload — top level so `compute()` can ship the function
// pointer across the boundary.

class _RouteFilterSortPayload {
  final List<_PointLite> points;
  final List<double> polyLats;
  final List<double> polyLngs;
  final double detourLimitKm;

  const _RouteFilterSortPayload({
    required this.points,
    required this.polyLats,
    required this.polyLngs,
    required this.detourLimitKm,
  });
}

class _PointLite {
  final String id;
  final double lat;
  final double lng;

  /// Exempt from the detour filter (non-fuel results pass through).
  final bool alwaysKeep;

  const _PointLite({
    required this.id,
    required this.lat,
    required this.lng,
    required this.alwaysKeep,
  });
}

/// Filter survivors by min-distance-to-polyline (unless [_PointLite.alwaysKeep]),
/// then sort by distance-along-polyline. Returns survivor ids in itinerary
/// order.
///
/// Both passes use the SAME stepped vertex walk and `distanceKm` math as the
/// on-UI-isolate helpers in `route_geometry.dart` (`minDistanceToPolyline` /
/// `sortByItineraryOrder`, which delegates to `geo_utils.distanceAlongPolyline`)
/// so the migrated ordering is bit-identical to the previous behaviour.
List<String> _filterAndSortIsolate(_RouteFilterSortPayload payload) {
  final polyLen = payload.polyLats.length;
  final step = polyLen > 300 ? 3 : 1;

  final survivors = <(_PointLite, double)>[];
  for (final p in payload.points) {
    if (!p.alwaysKeep) {
      // Mirrors route_geometry.minDistanceToPolyline.
      double minDist = double.infinity;
      for (int i = 0; i < polyLen; i += step) {
        final d = distanceKm(p.lat, p.lng, payload.polyLats[i], payload.polyLngs[i]);
        if (d < minDist) minDist = d;
      }
      if (minDist > payload.detourLimitKm) continue;
    }
    final along = _distanceAlongPolylineKm(
      p.lat,
      p.lng,
      payload.polyLats,
      payload.polyLngs,
      step,
    );
    survivors.add((p, along));
  }

  survivors.sort((a, b) => a.$2.compareTo(b.$2));
  return [for (final entry in survivors) entry.$1.id];
}

/// Flat-list re-implementation of `geo_utils.distanceAlongPolyline` —
/// numerically identical: same stepped vertex walk, same cumulative-to-
/// nearest-vertex result, so the isolate ships only primitives. Empty
/// polylines are short-circuited by the caller, never reaching here with
/// `step` derived from a real polyline.
double _distanceAlongPolylineKm(
  double lat,
  double lng,
  List<double> polyLats,
  List<double> polyLngs,
  int step,
) {
  double minDist = double.infinity;
  double cumulativeKm = 0;
  double bestCumulativeKm = 0;

  double? prevLat;
  double? prevLng;
  for (int i = 0; i < polyLats.length; i += step) {
    final pLat = polyLats[i];
    final pLng = polyLngs[i];
    if (prevLat != null && prevLng != null) {
      cumulativeKm += distanceKm(prevLat, prevLng, pLat, pLng);
    }
    final d = distanceKm(lat, lng, pLat, pLng);
    if (d < minDist) {
      minDist = d;
      bestCumulativeKm = cumulativeKm;
    }
    prevLat = pLat;
    prevLng = pLng;
  }
  return bestCumulativeKm;
}
