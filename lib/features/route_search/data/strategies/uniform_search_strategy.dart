// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/geo_utils.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../profile/data/models/user_profile.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../search/domain/entities/search_result_item.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/route_search_strategy.dart';
import '../helpers/batch_query_helper.dart';

/// Default strategy: samples every ~15 km along the route,
/// queries stations at each sample point, deduplicates, and filters
/// by detour distance.
///
/// Performance levers (Epic #2100):
/// - **B (#2101)** — per-sample-point top-N reduce inside
///   [BatchQueryHelper], so the candidate pool feeding into the
///   distance math is bounded to roughly `samplePoints × N`.
/// - **A (#2102)** — the three O(N×M) distance passes (detour
///   filter, cheapest-per-segment, itinerary sort) are packed into
///   a single [compute] call so they run in a background isolate and
///   only cross the isolate boundary once.
/// - **C (#2103)** — `onPartial` streaming is forwarded from
///   [BatchQueryHelper.queryAll] so the provider can emit each
///   incoming batch to the UI. The final returned list is still the
///   fully reduced + itinerary-sorted set (contract unchanged for
///   callers that ignore `onPartial`).
class UniformSearchStrategy implements RouteSearchStrategy {
  @override
  String get name => 'Uniform';

  @override
  String get l10nKey => 'uniformSearch';

  @override
  Future<List<SearchResultItem>> searchAlongRoute({
    required RouteInfo route,
    required FuelType fuelType,
    required double searchRadiusKm,
    required StationQueryFunction queryStations,
    double? maxDetourKm,
    int topNPerSamplePoint = 10,
    RouteSearchCriterion criterion = RouteSearchCriterion.cheapest,
    void Function(List<SearchResultItem> partial)? onPartial,
  }) async {
    debugPrint('UniformSearch: querying ${route.samplePoints.length} '
        'sample points with radius=${searchRadiusKm}km, '
        'topN=$topNPerSamplePoint, criterion=${criterion.key}');

    const batchHelper = BatchQueryHelper();
    final results = await batchHelper.queryAll(
      samplePoints: route.samplePoints,
      queryStations: queryStations,
      fuelType: fuelType,
      searchRadiusKm: searchRadiusKm,
      topNPerSamplePoint: topNPerSamplePoint,
      criterion: criterion,
      onPartial: onPartial,
    );

    // #2102 lever A — one isolate hop runs detour filter + itinerary
    // sort together. EV results passed through unchanged here; the
    // EV path keeps its own straight-line code in the provider.
    final detourLimit = maxDetourKm ?? searchRadiusKm;
    return _runFilterAndSort(
      results: results,
      polyline: route.geometry,
      detourLimitKm: detourLimit,
    );
  }

  @override
  Map<int, String>? computeBestStops({
    required RouteInfo route,
    required List<SearchResultItem> results,
    required FuelType fuelType,
    required double segmentKm,
  }) {
    final stations = <_StationLite>[];
    for (final item in results) {
      if (item is FuelStationResult) {
        final price = item.station.priceFor(fuelType);
        if (price == null) continue;
        stations.add(_StationLite(
          id: item.id,
          lat: item.station.lat,
          lng: item.station.lng,
          price: price,
        ));
      }
    }
    return _computeBestStopsSync(
      stations: stations,
      samplePoints: route.samplePoints,
      segmentKm: segmentKm,
    );
  }
}

/// Runs the detour filter + itinerary sort in a background isolate.
///
/// Exposed for unit tests; production code reaches it via
/// [UniformSearchStrategy.searchAlongRoute].
@visibleForTesting
Future<List<SearchResultItem>> runFilterAndSortForTest({
  required List<SearchResultItem> results,
  required List<LatLng> polyline,
  required double detourLimitKm,
}) =>
    _runFilterAndSort(
      results: results,
      polyline: polyline,
      detourLimitKm: detourLimitKm,
    );

Future<List<SearchResultItem>> _runFilterAndSort({
  required List<SearchResultItem> results,
  required List<LatLng> polyline,
  required double detourLimitKm,
}) async {
  if (results.isEmpty || polyline.isEmpty) return results;

  // Pack inputs into isolate-safe primitives — flutter_map's [LatLng]
  // and our [SearchResultItem] hierarchy are kept on the UI side; the
  // isolate decides survival + order from coordinates alone, then we
  // re-hydrate by id.
  final coords = <_PointLite>[
    for (final item in results)
      _PointLite(id: item.id, lat: item.lat, lng: item.lng),
  ];
  final polyLats = List<double>.unmodifiable(
      polyline.map((p) => p.latitude));
  final polyLngs = List<double>.unmodifiable(
      polyline.map((p) => p.longitude));

  final survivors = await compute(
    _filterAndSortIsolate,
    _FilterSortPayload(
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

/// Sync version of computeBestStops — same algorithm, just no isolate
/// hop (called from `computeBestStops`, which is itself invoked from
/// the provider after the search returned). Cheap enough on the
/// already-bounded result set to stay on the UI isolate.
Map<int, String> _computeBestStopsSync({
  required List<_StationLite> stations,
  required List<LatLng> samplePoints,
  required double segmentKm,
}) {
  final segmentCheapest = <int, String>{};
  final cheapestPriceForSegment = <int, double>{};

  for (final station in stations) {
    int nearestSampleIdx = 0;
    double minDist = double.infinity;
    for (int i = 0; i < samplePoints.length; i++) {
      final p = samplePoints[i];
      final d = distanceKm(station.lat, station.lng, p.latitude, p.longitude);
      if (d < minDist) {
        minDist = d;
        nearestSampleIdx = i;
      }
    }
    final segmentIdx = (nearestSampleIdx * 15 / segmentKm).floor();
    final currentBest = cheapestPriceForSegment[segmentIdx];
    if (currentBest == null || station.price < currentBest) {
      segmentCheapest[segmentIdx] = station.id;
      cheapestPriceForSegment[segmentIdx] = station.price;
    }
  }
  return segmentCheapest;
}

// ---------------------------------------------------------------------------
// Isolate entry + payload — kept at top level so `compute()` can ship
// the function pointer across the boundary.

class _FilterSortPayload {
  final List<_PointLite> points;
  final List<double> polyLats;
  final List<double> polyLngs;
  final double detourLimitKm;

  const _FilterSortPayload({
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
  const _PointLite({required this.id, required this.lat, required this.lng});
}

class _StationLite {
  final String id;
  final double lat;
  final double lng;
  final double price;
  const _StationLite({
    required this.id,
    required this.lat,
    required this.lng,
    required this.price,
  });
}

/// Filter survivors by min-distance-to-polyline, then sort by
/// distance-along-polyline. Returns survivor ids in itinerary order.
List<String> _filterAndSortIsolate(_FilterSortPayload payload) {
  final polyLen = payload.polyLats.length;
  final step = polyLen > 300 ? 3 : 1;

  // First pass — survivors plus precomputed along-polyline distance.
  final survivors = <(_PointLite, double)>[];
  for (final p in payload.points) {
    double minDist = double.infinity;
    for (int i = 0; i < polyLen; i += step) {
      final d = _haversineKm(
        p.lat,
        p.lng,
        payload.polyLats[i],
        payload.polyLngs[i],
      );
      if (d < minDist) minDist = d;
      // Cheap early exit — if we're already well inside the limit,
      // the survival check is satisfied; we still need the precise
      // along-polyline position for sorting, computed below.
    }
    if (minDist <= payload.detourLimitKm) {
      final along = _distanceAlongPolylineKm(
        p.lat,
        p.lng,
        payload.polyLats,
        payload.polyLngs,
      );
      survivors.add((p, along));
    }
  }

  survivors.sort((a, b) => a.$2.compareTo(b.$2));
  return [for (final entry in survivors) entry.$1.id];
}

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthKm = 6371.0;
  const deg2rad = 3.141592653589793 / 180.0;
  final dLat = (lat2 - lat1) * deg2rad;
  final dLng = (lng2 - lng1) * deg2rad;
  final a = _sin(dLat / 2) * _sin(dLat / 2) +
      _cos(lat1 * deg2rad) *
          _cos(lat2 * deg2rad) *
          _sin(dLng / 2) *
          _sin(dLng / 2);
  return 2 * earthKm * _atan2(_sqrt(a), _sqrt(1 - a));
}

double _distanceAlongPolylineKm(
  double lat,
  double lng,
  List<double> polyLats,
  List<double> polyLngs,
) {
  // Same shape as core/utils/geo_utils.dart distanceAlongPolyline,
  // re-implemented inline so the isolate has no UI-side imports.
  double accumulated = 0;
  double bestAlong = 0;
  double bestDist = double.infinity;
  for (int i = 0; i < polyLats.length - 1; i++) {
    final segStart = _haversineKm(lat, lng, polyLats[i], polyLngs[i]);
    if (segStart < bestDist) {
      bestDist = segStart;
      bestAlong = accumulated;
    }
    accumulated += _haversineKm(
      polyLats[i],
      polyLngs[i],
      polyLats[i + 1],
      polyLngs[i + 1],
    );
  }
  // Final point.
  if (polyLats.isNotEmpty) {
    final last = _haversineKm(
        lat, lng, polyLats.last, polyLngs.last);
    if (last < bestDist) {
      bestAlong = accumulated;
    }
  }
  return bestAlong;
}

double _sin(double x) => math.sin(x);
double _cos(double x) => math.cos(x);
double _atan2(double y, double x) => math.atan2(y, x);
double _sqrt(double x) => math.sqrt(x);
