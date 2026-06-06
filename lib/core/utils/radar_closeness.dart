// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../features/search/domain/entities/station.dart';

/// The single source of truth for the Fuel Station Radar "closeness" signal —
/// the green fill that grows as the driver nears a station (#2956, root-cause
/// reimplementation of #2661 / #2808 / #2899 / #2901 / #2944).
///
/// All three radar surfaces — the search-results list card, the recording PiP
/// overlay, and the trip radar card — compute closeness through THIS helper so
/// they can never desync again. The bar widget ([ProximityFillBar]) is
/// paint-only and delegates its fill arithmetic here.
///
/// ## Why prior fixes kept missing it
///
/// The fill formula itself was always correct:
///
/// ```
/// fill = clamp(1 - distanceMeters / radiusMeters, 0, 1)
/// ```
///
/// The defect was the **radius** each surface scaled against. Every surface
/// fed a *statically configured* radius (the 1 km approach geo-fence, or the
/// `searchRadiusProvider` slider — up to 25 km) that is **decoupled from where
/// the surfaced stations actually are**. When the configured radius is large
/// relative to the real spread of results, `distance / radius` is small for
/// EVERY row, so `1 - distance/radius` clusters near 1.0 and all bars look the
/// same length — exactly the recurring field report (265 m, 9.3 km, 9.9 km,
/// 10.0 km all rendering ~identical bars under a 25 km slider).
///
/// The fix for a *list* surface is to scale closeness against the **span the
/// results actually occupy** — the farthest surfaced station's distance — so
/// the nearest forecourt reads near-full and the farthest near-empty,
/// regardless of the config knob. See [spanRadiusMeters].
class RadarCloseness {
  const RadarCloseness._();

  /// The clamped closeness fraction (0..1) for a station [distanceMeters] from
  /// the driver, scaled to [radiusMeters]. 1.0 at the station, 0.0 at/beyond
  /// the radius. Never throws and never divides by zero: a non-positive or
  /// non-finite radius yields 0 (an unknown/degenerate scale reads as empty,
  /// not full).
  static double fillFor(double distanceMeters, double radiusMeters) {
    if (radiusMeters <= 0 || !radiusMeters.isFinite) return 0;
    final raw = 1.0 - (distanceMeters / radiusMeters);
    return raw.clamp(0.0, 1.0);
  }

  /// The radius (in metres) a *list* of radar results should scale its
  /// closeness bars to: the distance of the FARTHEST surfaced station (the
  /// actual span of the visible set), so closeness reads as RELATIVE position
  /// across the list — nearest near-full, farthest near-empty — instead of
  /// every row pinning toward full against an oversized config radius (#2956).
  ///
  /// `station.dist` is the great-circle distance in KILOMETRES (the same value
  /// the card's distance text shows), so the result is `maxDist * 1000`.
  ///
  /// Returns `null` — collapsing the bar — when the set is empty or carries no
  /// positive distance (e.g. an unlocated test fixture), so callers can render
  /// the bar unconditionally and it simply hides when there is nothing to
  /// scale against.
  static double? spanRadiusMeters(Iterable<Station> stations) {
    var maxDistKm = 0.0;
    for (final s in stations) {
      if (s.dist > maxDistKm) maxDistKm = s.dist;
    }
    if (maxDistKm <= 0) return null;
    return maxDistKm * 1000.0;
  }
}
