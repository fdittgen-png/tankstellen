// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:latlong2/latlong.dart';

import '../../../../core/services/country_service_registry.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../search/domain/entities/search_result_item.dart';
import '../../domain/entities/route_info.dart';

/// Shared route-search geometry helpers (#2197).
///
/// `CheapestSearchStrategy`, `BalancedSearchStrategy` and
/// `EcoRouteSearchStrategy` each carried byte-identical copies of the
/// polyline-distance, itinerary-sort and segment-bucketing logic, and
/// `route_search_provider.dart` inlined the same itinerary sort for its
/// EV-along-route results. They are hoisted here so the math lives in
/// one place; behaviour is bit-identical to the previous inlined copies.
///
/// `UniformSearchStrategy`'s isolate path (`_StationLite` /
/// `_computeBestStopsSync` / `_filterAndSortIsolate`) deliberately keeps
/// its own inlined geometry — it must stay free of UI-side imports so it
/// can run inside a background isolate — and is intentionally NOT a
/// consumer of these helpers.

/// Approximate spacing, in km, between the sample points that
/// `RoutingService._sampleAlongPolyline` (and
/// `EcoRouteCandidate.toRouteInfo`) lay down along a route polyline.
///
/// The per-segment bucketing in [segmentIndexFor] re-uses this spacing
/// to translate a nearest-sample-point index back into an along-route
/// distance before dividing into segments. Kept as a named constant so
/// the magic `15` the strategies used has one source (#2197). The
/// sampler itself (`routing_service.dart:112`,
/// `eco_route_candidate.dart:46`) still passes the literal `15.0` —
/// that's a sampling-interval argument, distinct from this bucketing
/// approximation, and deliberately left in place.
const double kSamplePointSpacingKm = 15.0;

/// Minimum great-circle distance (km) from a point to any vertex of
/// [polyline]. Steps through every third vertex on long polylines
/// (>300 vertices) to keep the scan cheap — the same approximation the
/// strategies have always used. Returns `double.infinity` for an empty
/// polyline.
double minDistanceToPolyline(double lat, double lng, List<LatLng> polyline) {
  if (polyline.isEmpty) return double.infinity;
  double minDist = double.infinity;
  final step = polyline.length > 300 ? 3 : 1;
  for (int i = 0; i < polyline.length; i += step) {
    final p = polyline[i];
    final d = distanceKm(lat, lng, p.latitude, p.longitude);
    if (d < minDist) minDist = d;
  }
  return minDist;
}

/// Sorts [items] in place by their position along [geometry]
/// (itinerary order), nearest-to-start first.
void sortByItineraryOrder(
  List<SearchResultItem> items,
  List<LatLng> geometry,
) {
  items.sort((a, b) {
    final da = distanceAlongPolyline(a.lat, a.lng, geometry);
    final db = distanceAlongPolyline(b.lat, b.lng, geometry);
    return da.compareTo(db);
  });
}

/// Map a nearest-sample-point index onto a per-segment bucket index.
///
/// Approximates the along-route distance as
/// `nearestSampleIdx * kSamplePointSpacingKm`, then divides by
/// [segmentKm] and floors — i.e. each `segmentKm`-wide stretch of the
/// route is one bucket. Preserves the original
/// `(nearestSampleIdx * 15 / segmentKm).floor()` semantics exactly.
int segmentIndexFor(int nearestSampleIdx, double segmentKm) =>
    (nearestSampleIdx * kSamplePointSpacingKm / segmentKm).floor();

/// The unique set of ISO 3166-1 alpha-2 country codes the [route]'s
/// polyline passes through, detected OFFLINE (#2595).
///
/// Walks every vertex of [route.geometry] and collects EVERY registered
/// country whose bounding box contains that vertex, via the
/// order-independent [CountryServiceRegistry.entriesByLatLng] (#2621) —
/// NOT the first-match `countryCodeFromLatLng`. Continental boxes overlap:
/// FR's box (lat 41.0–51.5, lng −5.5–10.0) geographically contains all of
/// Catalonia, and ES is declared after FR, so a first-match lookup
/// resolves every Catalonian vertex to FR and silently drops the whole
/// Spanish leg — a Pézenas→Barcelona route then queried only FR and came
/// back with zero Spanish stations (#2621). Unioning all matches lets the
/// shadowed ES through; over-collecting is safe because
/// `UniformSearchStrategy._runFilterAndSort` drops every station whose
/// detour from the corridor exceeds the budget, so a FR station fetched
/// near Barcelona is filtered out while the local ES stations survive.
///
/// (This already replaced the original per-sample-point NETWORK geocode
/// that, on null/timeout, fell back to the active profile's country — the
/// bbox lookup is sub-millisecond and never blackholes.)
///
/// Returns the codes upper-cased so they collate with profile country
/// codes regardless of upstream casing.
Set<String> corridorCountries(RouteInfo route) {
  final codes = <String>{};
  for (final p in route.geometry) {
    for (final entry
        in CountryServiceRegistry.entriesByLatLng(p.latitude, p.longitude)) {
      codes.add(entry.countryCode.toUpperCase());
    }
  }
  return codes;
}
