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
    // #3488 — a non-finite centre (or radius) would propagate NaN into the
    // camera; fall back to a finite centre / zero radius so the box stays
    // valid. `boundsOfPoints` then pads any zero span.
    if (!center.latitude.isFinite || !center.longitude.isFinite) {
      center = fallbackCenter;
    }
    if (!radiusKm.isFinite || radiusKm < 0) radiusKm = 0;
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
    // #3488 — a zero radius yields a zero-span box; route the corners
    // through `boundsOfPoints` so any near-zero span is epsilon-padded and
    // `CameraFit.bounds` never computes an infinite fit-zoom.
    return boundsOfPoints(
      [LatLng(south, west), LatLng(north, east)],
      fallback: center,
    );
  }

  /// A finite fallback camera centre when there is nothing sane to frame
  /// (empty / all-non-finite input). Paris — the historical default box
  /// centre used by the route/inline fallbacks — so behaviour is uniform.
  static const LatLng fallbackCenter = LatLng(48.8566, 2.3522);

  /// Half-width of the epsilon box (~50 m) used to pad a degenerate,
  /// zero-span bounds so `CameraFit.bounds` never computes an infinite
  /// fit-zoom (which projects to `LatLng(NaN, NaN)` and throws on every
  /// tile update — #3488). Fine at any latitude.
  static const double _boundsEpsilon = 0.0005;

  /// Calculate the geographic centroid of a list of stations.
  ///
  /// #3488 — hardened to be NaN-safe: stations whose `lat`/`lng` are
  /// non-finite (bad upstream data) are skipped, and an empty (or
  /// entirely non-finite) input returns [fallbackCenter] rather than
  /// `0/0 = NaN`. A `LatLng(NaN, NaN)` reaching the camera makes
  /// flutter_map throw `LatLng is not finite` on every tile update,
  /// which visually freezes the map.
  static LatLng centerOf(List<Station> stations) {
    double sumLat = 0, sumLng = 0;
    var count = 0;
    for (final s in stations) {
      if (!s.lat.isFinite || !s.lng.isFinite) continue;
      sumLat += s.lat;
      sumLng += s.lng;
      count++;
    }
    if (count == 0) return fallbackCenter;
    return LatLng(sumLat / count, sumLng / count);
  }

  /// The framing [LatLngBounds] over [points], guaranteed finite and
  /// non-degenerate so `CameraFit.bounds` can never divide-by-zero or
  /// compute an infinite fit-zoom (#3488).
  ///
  /// Contract:
  ///   * non-finite points are dropped;
  ///   * an empty result (no points, or all non-finite) frames a small
  ///     box around [fallback] (default [fallbackCenter]);
  ///   * a **zero (or near-zero) span in either axis** — a single point
  ///     OR several identical / co-located points (a chain returning a
  ///     duplicate station was the #3488 trigger) — is padded to a tiny
  ///     epsilon box, so the fit always has a finite area to frame.
  static LatLngBounds boundsOfPoints(
    List<LatLng> points, {
    LatLng fallback = fallbackCenter,
  }) {
    double? minLat, maxLat, minLng, maxLng;
    for (final p in points) {
      if (!p.latitude.isFinite || !p.longitude.isFinite) continue;
      minLat = (minLat == null) ? p.latitude : math.min(minLat, p.latitude);
      maxLat = (maxLat == null) ? p.latitude : math.max(maxLat, p.latitude);
      minLng = (minLng == null) ? p.longitude : math.min(minLng, p.longitude);
      maxLng = (maxLng == null) ? p.longitude : math.max(maxLng, p.longitude);
    }
    // No finite point at all — frame a small box around the fallback.
    if (minLat == null || maxLat == null || minLng == null || maxLng == null) {
      final f = fallback.latitude.isFinite && fallback.longitude.isFinite
          ? fallback
          : fallbackCenter;
      return LatLngBounds(
        LatLng(f.latitude - _boundsEpsilon, f.longitude - _boundsEpsilon),
        LatLng(f.latitude + _boundsEpsilon, f.longitude + _boundsEpsilon),
      );
    }
    // Pad any near-zero span so the box always has a finite area. Guards
    // BOTH the single-point case AND >=2 identical / co-located points,
    // which `LatLngBounds.fromPoints` would collapse to min == max (#3488).
    if (maxLat - minLat < _boundsEpsilon) {
      minLat -= _boundsEpsilon;
      maxLat += _boundsEpsilon;
    }
    if (maxLng - minLng < _boundsEpsilon) {
      minLng -= _boundsEpsilon;
      maxLng += _boundsEpsilon;
    }
    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
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
