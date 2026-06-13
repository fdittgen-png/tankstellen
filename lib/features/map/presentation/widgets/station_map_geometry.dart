// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import '../../../../core/utils/price_utils.dart';

/// Pure geometry + marker-ranking helpers for the station map (#3233).
///
/// Extracted from `StationMapLayers` so this map math (camera zoom/bounds,
/// centroid, the price-paint ordering + emphasis ranking) lives next to its
/// own unit tests without dragging in the widget, and the widget file stays
/// closer to the line cap. All members are pure (no widget state).
class StationMapGeometry {
  const StationMapGeometry._();

  /// Camera zoom bounds for the +/− button handlers + the [MapOptions]
  /// camera constraints. Aligned with the OSM tile cap (`maxNativeZoom: 19`)
  /// so a programmatic zoom-in past the cap doesn't park the camera at
  /// a level with no tiles to render. The min is conservative — flutter_map
  /// itself wraps the world at zoom 0, but anything below ~3 puts every
  /// pin in a single pixel, which is unhelpful UX. Per #1457.
  static const double minZoom = 3.0;
  static const double maxZoom = 19.0;

  /// Calculate zoom level from search radius.
  static double zoomForRadius(double radiusKm) {
    if (radiusKm <= 5) return 13;
    if (radiusKm <= 10) return 12;
    if (radiusKm <= 15) return 11;
    if (radiusKm <= 25) return 10;
    return 9;
  }

  /// Compute the [LatLngBounds] of a circle of [radiusKm] around [center].
  ///
  /// Uses a flat-earth approximation that is accurate enough for the
  /// search radii we deal with (< 100 km). 1 degree latitude is ~111 km;
  /// the longitude degree shrinks with the cosine of the latitude.
  static LatLngBounds boundsForRadius(LatLng center, double radiusKm) {
    const double kmPerLatDegree = 111.0;
    final double latDelta = radiusKm / kmPerLatDegree;
    final double cosLat = math.cos(center.latitude * math.pi / 180.0).abs();
    // Guard against the poles where cos(lat) approaches zero.
    final double safeCos = cosLat < 0.01 ? 0.01 : cosLat;
    final double lngDelta = radiusKm / (kmPerLatDegree * safeCos);
    final double south = (center.latitude - latDelta).clamp(-90.0, 90.0);
    final double north = (center.latitude + latDelta).clamp(-90.0, 90.0);
    final double west = (center.longitude - lngDelta).clamp(-180.0, 180.0);
    final double east = (center.longitude + lngDelta).clamp(-180.0, 180.0);
    return LatLngBounds(
      LatLng(south, west),
      LatLng(north, east),
    );
  }

  /// Calculate center point from a list of stations.
  static LatLng centerOf(List<Station> stations) {
    double sumLat = 0, sumLng = 0;
    for (final s in stations) {
      sumLat += s.lat;
      sumLng += s.lng;
    }
    return LatLng(sumLat / stations.length, sumLng / stations.length);
  }

  /// How many top-ranked stations keep their full price label; the rest
  /// render as compact price-band dots (#2510). Small enough that the
  /// emphasized bubbles stay legible at the search zoom, large enough to
  /// surface the handful of stations a driver actually compares.
  static const int emphasisCount = 4;

  /// At or above this many stations a NON-`clusterAlways` map falls back to
  /// count-clustering (#2510): a bounded nearby search stays well under this,
  /// only a genuinely huge / zoomed-far set collapses into tappable clusters.
  static const int clusterThreshold = 80;

  /// Order [stations] so that, when their markers are handed to the
  /// marker layer, the CHEAPEST (green/günstig) marker is painted ON
  /// TOP of any more-expensive (orange/red) markers it overlaps (#2434).
  ///
  /// flutter_map paints markers in the order of the source list — a marker
  /// LATER in the list is painted on top of earlier ones. So the rule is:
  ///   - sort by the SELECTED-fuel price (`station.priceFor(selectedFuel)`)
  ///     — the SAME price the marker is COLOURED by and the SAME strict
  ///     resolution the search list uses (#2510, reverting the #2400
  ///     fallback chain) — DESCENDING: most expensive first (painted at
  ///     the bottom), cheapest last (painted on top), so colour and
  ///     stacking always agree;
  ///   - markers with NO selected-fuel price (the grey "--" bubble) sort
  ///     to the very FRONT (the bottom of the stack) so a price-less
  ///     marker can never cover a real green one.
  ///
  /// Returns a NEW list; the input is not mutated. A stable sort keeps the
  /// relative order of equal-priced stations.
  static List<Station> orderedByPriceForPainting(
    List<Station> stations,
    FuelType selectedFuel, {
    FuelType Function(Station)? fuelResolver,
  }) {
    // A null selected-fuel price is treated as the most-expensive bucket
    // (+infinity) so, under a descending sort, it lands first → painted
    // at the very bottom, beneath every priced marker. #2631 — when a
    // cross-border resolver is set, the key is each station's OWN country
    // fuel price so the cheapest ES (E10) marker still paints on top.
    double sortKey(Station s) =>
        priceForFuelType(s, fuelResolver != null ? fuelResolver(s) : selectedFuel) ??
        double.infinity;
    final ordered = List<Station>.of(stations);
    // Descending: highest price first (bottom), lowest last (top).
    mergeSort<Station>(ordered,
        compare: (a, b) => sortKey(b).compareTo(sortKey(a)));
    return ordered;
  }

  /// Rank [stations] for marker EMPHASIS (#2510): the cheapest stations first
  /// when [byPrice] (a price-oriented sort), the closest first otherwise. The
  /// first [emphasisCount] entries get the full price bubble; the rest become
  /// compact dots. Stations without a comparable value sort last so they never
  /// steal emphasis from a station that has a real price/distance.
  ///
  /// [byPrice] is passed in (not the SortMode enum) so this map-geometry helper
  /// stays free of a search-feature import (#3233 keeps the feature boundary).
  ///
  /// Returns a NEW list; the input is not mutated. Stable for ties.
  static List<Station> rankForEmphasis(
    List<Station> stations,
    FuelType selectedFuel, {
    required bool byPrice,
  }) {
    final ranked = List<Station>.of(stations);
    int compare(Station a, Station b) {
      if (byPrice) {
        // Cheapest first; price-less stations sort last (sentinel handled
        // inside compareByPrice).
        return compareByPrice(a, b, selectedFuel);
      }
      // Closest first for distance / 24h / rating / name sorts — distance
      // is the universally available, savings-relevant tie-breaker.
      return a.dist.compareTo(b.dist);
    }

    mergeSort<Station>(ranked, compare: compare);
    return ranked;
  }
}
