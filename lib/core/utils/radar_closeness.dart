// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The single source of truth for the Fuel Station Radar "closeness" signal —
/// the green fill that grows as the driver nears a station (#2995, lineage
/// #2661 / #2808 / #2899 / #2901 / #2944 / #2984).
///
/// All three radar surfaces — the search-results list card, the recording PiP
/// overlay, and the trip radar card — compute closeness through THIS helper so
/// they can never desync again. The bar widget ([ProximityFillBar]) is
/// paint-only and delegates its fill arithmetic here.
///
/// ## The model: APPROACH-RADIUS scale (fuller = closer)
///
/// The fill formula is the same everywhere:
///
/// ```
/// fill = clamp(1 - distanceMeters / scaleMeters, 0, 1)
/// ```
///
/// and so is the **scale**: every surface divides against the user's APPROACH
/// RADIUS (`profile.approachRadiusKm * 1000`) — the geofence the driver is
/// approaching. The trip card, the PiP and the search list are therefore
/// consistent on the user's approach-radius base, so the bar means the same
/// thing wherever it appears: "how close is THIS station, on the user's
/// approach-radius base". A 2.5 km forecourt reads `1 - 2.5/3 ≈ 0.17` on a 3 km
/// profile (the same on all three surfaces), and a station beyond the approach
/// radius reads ~0 — by design, only stations within reach show a fill.
///
/// ## History (#2995 reverses #2984/#2985)
///
/// #2984/#2985 had the search list scale to `min(searchRadius, 15 km cap)`
/// (the removed `listScaleMeters` helper), which let a 2.5 km station read ~0.83
/// on the list while reading ~0.17 on the recording radar for the same profile.
/// The maintainer decided the recording radar's approach-radius base is correct
/// and the list was wrong; #2995 brings the list onto the same base.
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
}
