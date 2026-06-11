// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../../../core/country/country_bounding_box.dart';
import '../../../../core/services/country_service_registry.dart';
import '../../../../core/utils/geo_utils.dart';
import '../../../../core/domain/search_result_item.dart';
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

/// The penetration threshold, in DEGREES (~111 km at this latitude), a
/// route vertex must clear INTO a country's overlap-exclusive territory
/// before that country is credited as genuinely entered (#2741).
///
/// At a border the continental bounding boxes overlap heavily (FR's box
/// over-extends ~165 km south past the Pyrenees, ES's symmetrically north),
/// so a purely-French route near Perpignan has EVERY vertex inside BOTH the
/// FR and ES boxes. A vertex is only credited to the SHADOWING country (ES)
/// when it sits within this margin of — or beyond — that country's exclusive
/// frontier (the part of its box no other matched box covers). ~1.0° cleanly
/// separates the field cases: Perpignan's southernmost vertex (lat 42.6973)
/// is 1.70° north of ES's exclusive southern edge (FR.minLat 41.0) → NOT
/// credited; a genuine Barcelona route reaches lat ≤41.39 (0.39° north) and a
/// Girona one ≤41.98 (0.98°) → both within the margin → ES credited.
const double kGenuineEntryMarginDeg = 1.0;

/// The unique set of ISO 3166-1 alpha-2 country codes the [route]'s
/// polyline GENUINELY passes through, detected OFFLINE (#2595 / #2741).
///
/// Walks every vertex of [route.geometry] and collects every registered
/// country whose bounding box contains that vertex, via the order-independent
/// [CountryServiceRegistry.entriesByLatLng] (#2621) — NOT the first-match
/// `countryCodeFromLatLng`. Continental boxes overlap: FR's box (lat 41.0–51.5,
/// lng −5.5–10.0) geographically contains all of Catalonia, and ES is declared
/// after FR, so a first-match lookup resolves every Catalonian vertex to FR
/// and silently drops the whole Spanish leg — a Pézenas→Barcelona route then
/// queried only FR and came back with zero Spanish stations (#2621).
///
/// #2741 — but the bare union over-collects symmetrically. The FR box extends
/// ~165 km south of the real Pyrenees border and ES's ~165 km north, so a
/// purely-French route (Pézenas→Perpignan, Pézenas→Paris) has EVERY vertex
/// inside BOTH boxes → the union returned {FR, ES}, the corridor queried a
/// full Spanish MITECO leg with no ES profile (spurious Spanish stations) and
/// the heavy uncached ES query starved the FR legs into a silent zero. So the
/// per-vertex collection is now GATED by [_genuinelyInside]: a vertex inside a
/// single box credits it unconditionally; a vertex inside several only credits
/// a country it has genuinely entered (penetrated that country's exclusive
/// side of the overlap by more than [kGenuineEntryMarginDeg]). A real crossing
/// into Spain (Barcelona / Girona) still credits ES; a near-border French
/// route does not.
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
    final matches = CountryServiceRegistry.entriesByLatLng(
      p.latitude,
      p.longitude,
    ).toList();
    if (matches.length == 1) {
      // Unambiguous interior — exactly one box owns this vertex.
      codes.add(matches.first.countryCode.toUpperCase());
      continue;
    }
    // Border fringe — the vertex sits in several overlapping boxes. Credit a
    // country only when the vertex genuinely entered it (#2741).
    final otherBoxes = matches.map((e) => e.boundingBox).toList();
    for (final entry in matches) {
      if (_genuinelyInside(entry.boundingBox, otherBoxes, p.latitude,
          p.longitude)) {
        codes.add(entry.countryCode.toUpperCase());
      }
    }
  }
  return codes;
}

/// Whether the vertex ([lat], [lng]) has GENUINELY entered [box] rather than
/// merely sitting in the slack of an over-generous border overlap (#2741).
///
/// [allBoxes] is every matched box at this vertex INCLUDING [box]. For each
/// OTHER matched box the vertex must lie within [kGenuineEntryMarginDeg] of —
/// or beyond — [box]'s exclusive frontier vs that box (the edge past which
/// [box] extends but the other does not). The margin is read from the
/// box-overlap exclusive extent (the signed distance to that frontier), not a
/// hard-coded latitude, so it holds at any border, not just the Pyrenees.
///
/// A box that does NOT extend past some other matched box in any direction has
/// no exclusive territory relative to it (it is wholly shadowed there), so it
/// is never credited via that pairing — exactly the over-collection we drop.
bool _genuinelyInside(
  CountryBoundingBox box,
  List<CountryBoundingBox> allBoxes,
  double lat,
  double lng,
) {
  for (final other in allBoxes) {
    if (identical(other, box)) continue;
    if (_signedDistIntoExclusive(box, other, lat, lng) <
        -kGenuineEntryMarginDeg) {
      return false;
    }
  }
  return true;
}

/// Signed distance, in degrees, from the vertex ([lat], [lng]) to [box]'s
/// territory that is EXCLUSIVE of [other] — i.e. the band of [box] lying
/// beyond [other]'s edge on whichever side(s) [box] extends further (#2741).
///
/// `0` = exactly on [other]'s edge (the exclusive frontier), positive = already
/// inside [box]-exclusive territory, negative = still in the shared overlap and
/// this far short of the frontier. Returns `-infinity` when [box] never extends
/// past [other] (no exclusive territory). When [box] extends past [other] in
/// several directions the LARGEST (closest-to-exclusive) value is returned, so
/// a vertex near any one exclusive frontier counts as a genuine entry.
double _signedDistIntoExclusive(
  CountryBoundingBox box,
  CountryBoundingBox other,
  double lat,
  double lng,
) {
  var best = double.negativeInfinity;
  if (box.minLat < other.minLat) {
    best = math.max(best, other.minLat - lat); // box extends SOUTH past other
  }
  if (box.maxLat > other.maxLat) {
    best = math.max(best, lat - other.maxLat); // box extends NORTH past other
  }
  if (box.minLng < other.minLng) {
    best = math.max(best, other.minLng - lng); // box extends WEST past other
  }
  if (box.maxLng > other.maxLng) {
    best = math.max(best, lng - other.maxLng); // box extends EAST past other
  }
  return best;
}
