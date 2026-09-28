// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later


import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/route_projection.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../profile/data/models/user_profile.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/search_result_item.dart';
import '../../domain/entities/route_info.dart';
import '../../domain/route_search_strategy.dart';
import '../cross_border_corridor.dart' show fuelForStation;
import '../helpers/batch_query_helper.dart';
import 'route_filter_sort_isolate.dart';

/// Default strategy: samples every ~15 km along the route,
/// queries stations at each sample point, deduplicates, and filters
/// by detour distance.
///
/// Performance levers (Epic #2100):
/// - **B (#2101)** — per-sample-point top-N reduce inside
///   [BatchQueryHelper], so the candidate pool feeding into the
///   distance math is bounded to roughly `samplePoints × N`.
/// - **A (#2102)** — the O(N×M) corridor eligibility + itinerary sort
///   run in a single background-isolate hop, shared with the other
///   strategies via [filterAndSortAlongRoute] since #4432.
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
    // #3610 — gated so release builds skip the string interpolation.
    if (kDebugMode) {
      debugPrint('UniformSearch: querying ${route.samplePoints.length} '
          'sample points with radius=${searchRadiusKm}km, '
          'topN=$topNPerSamplePoint, criterion=${criterion.key}');
    }

    // #2102 lever A — one isolate hop runs the corridor eligibility +
    // itinerary sort together. EV results are not produced here; the
    // EV path keeps its own code in the provider.
    final detourLimit = maxDetourKm ?? searchRadiusKm;
    // #4432 — partials pass the SAME eligibility as the final list, so
    // a station behind the driver never flashes onto the list or map.
    const batchHelper = BatchQueryHelper();
    return queryEligibleAlongRoute(
      polyline: route.geometry,
      detourLimitKm: detourLimit,
      keepNonFuel: false,
      onPartial: onPartial,
      query: (partial) => batchHelper.queryAll(
        samplePoints: route.samplePoints,
        queryStations: queryStations,
        fuelType: fuelType,
        searchRadiusKm: searchRadiusKm,
        topNPerSamplePoint: topNPerSamplePoint,
        criterion: criterion,
        onPartial: partial,
      ),
    );
  }

  @override
  Map<int, String>? computeBestStops({
    required RouteInfo route,
    required List<SearchResultItem> results,
    required FuelType fuelType,
    required double segmentKm,
    Map<String, FuelType> profileFuelByCountry = const {},
  }) {
    final stations = <_StationLite>[];
    for (final item in results) {
      if (item is FuelStationResult) {
        // #2631 — price by the station's OWN country profile fuel so a
        // cross-border ES station (E10 populated, E85 null) is ranked, not
        // dropped. Empty map → fallback = fuelType → unchanged single-country.
        final price = item.station.priceFor(
            fuelForStation(item.station, profileFuelByCountry, fuelType));
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

/// Runs the corridor eligibility + itinerary sort in a background
/// isolate — the shared [filterAndSortAlongRoute] with no non-fuel
/// exemption (#4432: Uniform's private nearest-vertex copy is gone).
///
/// Exposed for unit tests; production code reaches it via
/// [UniformSearchStrategy.searchAlongRoute].
@visibleForTesting
Future<List<SearchResultItem>> runFilterAndSortForTest({
  required List<SearchResultItem> results,
  required List<LatLng> polyline,
  required double detourLimitKm,
}) =>
    filterAndSortAlongRoute(
      results: results,
      polyline: polyline,
      detourLimitKm: detourLimitKm,
      keepNonFuel: false,
    );

/// Sync best-stop bucketing — no isolate hop (called from
/// `computeBestStops`, which the provider invokes after the search
/// returned, on the already-bounded result set).
///
/// #4432 — each station is bucketed by the progress at which the route
/// meets it ([RouteProjection.project] — the shared itinerary pass),
/// not by the index of its nearest sample point times 15 km: on a loop
/// the nearest sample can belong to the wrong pass, and a station
/// between two samples sat in whichever bucket the nearer one did. The
/// projection runs over the sample polyline (one point per ~15 km)
/// because bucket boundaries need kilometre, not metre, precision and
/// this runs on the UI isolate.
Map<int, String> _computeBestStopsSync({
  required List<_StationLite> stations,
  required List<LatLng> samplePoints,
  required double segmentKm,
}) {
  final segmentCheapest = <int, String>{};
  final cheapestPriceForSegment = <int, double>{};
  final projection = RouteProjection(samplePoints);

  for (final station in stations) {
    final alongKm = projection.project(station.lat, station.lng).alongKm;
    final segmentIdx = (alongKm / segmentKm).floor();
    final currentBest = cheapestPriceForSegment[segmentIdx];
    if (currentBest == null || station.price < currentBest) {
      segmentCheapest[segmentIdx] = station.id;
      cheapestPriceForSegment[segmentIdx] = station.price;
    }
  }
  return segmentCheapest;
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
