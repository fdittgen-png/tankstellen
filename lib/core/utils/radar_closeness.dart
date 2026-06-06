// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

/// The maintainer-tunable upper bound (in metres) on the list closeness bar's
/// absolute scale. Default 15 km (#2984).
///
/// The list bar scales each fill against `min(searchRadiusMeters, this)`, so
/// this cap keeps the scale — and therefore every station's fill — stable and
/// readable even when the user opens the search radius wide: a 2.5 km forecourt
/// reads the SAME fill at a 15 km, 20 km or 25 km radius. Lower it for a
/// tighter "near = full" feel; raise it (up to the 25 km radius ceiling) for a
/// gentler ramp. This is the single knob for the absolute list scale — tune it
/// HERE.
const double kRadarClosenessScaleCapMeters = 15000;

/// The single source of truth for the Fuel Station Radar "closeness" signal —
/// the green fill that grows as the driver nears a station (#2984, supersedes
/// the rejected relative-to-span model of #2956/#2959; lineage #2661 / #2808 /
/// #2899 / #2901 / #2944).
///
/// All three radar surfaces — the search-results list card, the recording PiP
/// overlay, and the trip radar card — compute closeness through THIS helper so
/// they can never desync again. The bar widget ([ProximityFillBar]) is
/// paint-only and delegates its fill arithmetic here.
///
/// ## The model: ABSOLUTE, fixed scale (fuller = closer)
///
/// The fill formula is the same everywhere:
///
/// ```
/// fill = clamp(1 - distanceMeters / scaleMeters, 0, 1)
/// ```
///
/// What each surface differs in is the **scale** it divides against — and the
/// scale is always an *absolute* distance, never derived from the result set:
///
///  * The trip card + PiP scale to the **approach radius** (`profile
///    .approachRadiusKm`) — the geofence the driver is approaching.
///  * The list scales to [listScaleMeters] — `min(searchRadiusMeters,
///    kRadarClosenessScaleCapMeters)` — the user's configured radar radius,
///    clamped to the tunable cap.
///
/// So the bar means "how close is THIS station, on a stable absolute scale":
///
///  * **Stable** — a 2.5 km station reads the SAME fill no matter what else is
///    in the list (the scale depends only on the radius setting + the cap, not
///    on the surfaced set).
///  * **Closer = fuller, nothing force-emptied** — the farthest row is never
///    pinned to 0% just for being last; it only nears empty if it is genuinely
///    near/beyond the scale.
///
/// ## Why the relative-to-span model was rejected (#2984)
///
/// #2959 scaled the list to the farthest surfaced station's distance (the
/// "span"). That made the fill *relative to the current list*: the farthest
/// station was always pinned to 0% even when genuinely near, and a given
/// station's fill changed whenever the result set changed (filter, refresh, a
/// far outlier appearing/disappearing). The maintainer rejected it for this
/// absolute, stable scale.
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

  /// The absolute scale (in metres) the radar *list* closeness bars divide
  /// against: `min(searchRadiusMeters, kRadarClosenessScaleCapMeters)` (#2984).
  ///
  /// [searchRadiusMeters] is the user's configured radar/search radius in
  /// metres (`searchRadiusProvider` km → m). The result is independent of the
  /// surfaced result set, so every station's fill is stable — the key property
  /// the rejected span model lacked. A non-positive / non-finite radius yields
  /// `null` so callers can collapse the bar instead of dividing by a
  /// degenerate scale.
  static double? listScaleMeters(double searchRadiusMeters) {
    if (searchRadiusMeters <= 0 || !searchRadiusMeters.isFinite) return null;
    return math.min(searchRadiusMeters, kRadarClosenessScaleCapMeters);
  }
}
