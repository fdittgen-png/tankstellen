// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

/// A single GPS fix on a recorded trip's track — latitude / longitude
/// in decimal degrees (#1979), plus the optional reported horizontal
/// accuracy and fix timestamp the gating in [GpsTrackDistance] consumes
/// (#2963).
///
/// [hAccuracyM] and [at] are nullable and default to null so every
/// pre-existing caller / fixture (which passed lat/lon only) keeps
/// compiling and behaving exactly as before: a null accuracy is treated
/// as "unknown, accept" and a null timestamp disables the teleport gate
/// for that segment.
class GpsTrackPoint {
  final double latitude;
  final double longitude;

  /// Reported horizontal GPS accuracy (metres). null / non-finite =
  /// unknown → the accuracy gate accepts the segment (so non-GPS callers
  /// and good fixes are never rejected).
  final double? hAccuracyM;

  /// Wall-clock time of the fix. Used by the teleport / max-plausible-speed
  /// gate to reject a segment whose implied speed is physically impossible
  /// (a cold-start position jump). null disables the gate for that segment.
  final DateTime? at;

  const GpsTrackPoint(
    this.latitude,
    this.longitude, {
    this.hAccuracyM,
    this.at,
  });
}

/// Reported horizontal accuracy (metres) above which a fix is too noisy to
/// contribute road distance (#2963). A parked car's ~1 Hz scatter arrives
/// at σ≈25 m, so an endpoint reporting accuracy worse than this is dropped
/// rather than haversine-summed into phantom kilometres. A null /
/// non-finite accuracy is "unknown, accept" so non-GPS callers and good
/// fixes are unaffected. Chosen at 25 m to match the standstill-scatter
/// radius seen in the field export while staying loose enough that a real
/// urban-canyon driving fix (typically 5–15 m on `LocationAccuracy.high`)
/// still counts.
const double kGpsDistanceAccuracyGateM = 25.0;

/// Maximum implied speed (km/h) a single track segment may represent
/// before it is treated as a teleport, not motion (#2963). A real road
/// vehicle does not exceed ~200 km/h; a `segmentKm / dtHours` above this
/// is a cold-start position jump (the GPS engine snapping from a stale
/// last-known fix to the true position) and is dropped. Requires both
/// endpoints to carry a timestamp with a positive Δt; otherwise the gate
/// is skipped (timestamps are optional).
const double kGpsMaxPlausibleSpeedKmh = 200.0;

/// Haversine-summed road distance over a sequence of GPS fixes (#1979).
///
/// Used as a distance source for the consumption calculation: the GPS
/// track is the true road distance, more accurate than the OBD
/// speed-sensor `virtual` odometer (the speedometer sensor over-reads).
class GpsTrackDistance {
  GpsTrackDistance._();

  /// Mean Earth radius (km) — the WGS-84 IUGG mean radius.
  ///
  /// Deliberately NOT unified with `lib/core/utils/geo_utils.dart`'s
  /// `6371` / `earthRadiusMeters` (#3175): track integration sums
  /// thousands of tiny segments into a persisted trip distance that
  /// feeds the consumption calculation, so it uses the more precise
  /// mean radius — and switching it now would retroactively shift every
  /// stored trip's km (and thus l/100km) by ~0.014%. The search/sort
  /// callers in geo_utils only need comparative distances, where the
  /// rounded radius is fine.
  static const double _earthRadiusKm = 6371.0088;

  /// Total polyline distance, in km, through [track].
  ///
  /// Each consecutive pair contributes a great-circle segment, subject to
  /// three independent rejections (#1979 / #2963):
  ///   * **accuracy gate** — a segment is dropped when EITHER endpoint
  ///     reports a finite horizontal accuracy worse than
  ///     [accuracyGateM]. A parked car's GPS scatter all arrives at poor
  ///     accuracy, so the whole idle track collapses to ~0 km instead of
  ///     accumulating phantom kilometres of jitter. A null / non-finite
  ///     accuracy is "unknown, accept", so non-GPS callers and good fixes
  ///     are never rejected.
  ///   * **teleport gate** — when both endpoints carry timestamps a real
  ///     [_minTeleportGateSec] or more apart, a segment whose implied speed
  ///     exceeds [maxPlausibleSpeedKmh] is dropped (a cold-start position
  ///     jump). Sub-[_minTeleportGateSec] Δt is too short to trust an
  ///     implied-speed estimate (a fix burst / a test that stamps many
  ///     fixes microseconds apart) and is left to the accuracy + jitter
  ///     gates, so a tightly-clocked legitimate track is not gutted.
  ///   * **jitter floor** — the original [jitterFloorKm] per-segment floor
  ///     drops sub-floor hops, preserved verbatim.
  ///
  /// Deliberately NOT added: a "displacement must exceed the accuracy
  /// radius" floor. At ~1 Hz a real car covers only ~2.8 m at 10 km/h,
  /// ~13.9 m at 50, ~25 m at 90 — such a floor would reject EVERY
  /// legitimate city / highway segment and gut the GPS-distance feature.
  ///
  /// A track with fewer than two points has zero length.
  static double haversineKm(
    List<GpsTrackPoint> track, {
    double jitterFloorKm = 0.003,
    double accuracyGateM = kGpsDistanceAccuracyGateM,
    double maxPlausibleSpeedKmh = kGpsMaxPlausibleSpeedKmh,
  }) {
    var total = 0.0;
    for (var i = 1; i < track.length; i++) {
      final a = track[i - 1];
      final b = track[i];
      // Accuracy gate — drop a segment touching a too-noisy endpoint.
      if (_tooInaccurate(a.hAccuracyM, accuracyGateM) ||
          _tooInaccurate(b.hAccuracyM, accuracyGateM)) {
        continue;
      }
      final segment = _segmentKm(a, b);
      if (segment < jitterFloorKm) continue;
      // Teleport gate — drop a segment whose implied speed is impossible
      // (a cold-start jump). Only when both timestamps are present with a
      // positive Δt; otherwise the gate is skipped (timestamps optional).
      if (_isTeleport(a.at, b.at, segment, maxPlausibleSpeedKmh)) continue;
      total += segment;
    }
    return total;
  }

  /// True when [accuracyM] is finite and worse than [gateM]. A null /
  /// non-finite accuracy is "unknown, accept".
  static bool _tooInaccurate(double? accuracyM, double gateM) =>
      accuracyM != null && accuracyM.isFinite && accuracyM > gateM;

  /// Minimum Δt (seconds) between two fixes before the teleport gate trusts
  /// the implied-speed estimate. A real Geolocator stream delivers fixes
  /// ~1 Hz apart, and a genuine cold-start teleport is whole seconds stale;
  /// a sub-half-second Δt is a fix burst (or a test stamping fixes
  /// microseconds apart) where `segmentKm / dtHours` explodes for a normal
  /// hop, so the gate must not fire there.
  static const double _minTeleportGateSec = 0.5;

  /// True when the [segmentKm] hop between two timestamped fixes implies a
  /// speed above [maxPlausibleSpeedKmh]. Skipped (returns false) when a
  /// timestamp is missing, the Δt is non-positive, or the Δt is shorter
  /// than [_minTeleportGateSec] (too tight to trust the estimate).
  static bool _isTeleport(
    DateTime? a,
    DateTime? b,
    double segmentKm,
    double maxPlausibleSpeedKmh,
  ) {
    if (a == null || b == null) return false;
    final dtSec =
        b.difference(a).inMicroseconds / Duration.microsecondsPerSecond;
    if (dtSec < _minTeleportGateSec) return false;
    return segmentKm / (dtSec / 3600.0) > maxPlausibleSpeedKmh;
  }

  /// Great-circle distance (km) between two fixes via the haversine
  /// formula.
  static double _segmentKm(GpsTrackPoint a, GpsTrackPoint b) {
    final lat1 = _radians(a.latitude);
    final lat2 = _radians(b.latitude);
    final dLat = _radians(b.latitude - a.latitude);
    final dLon = _radians(b.longitude - a.longitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    // `min(1.0, …)` guards asin's domain against floating-point drift.
    return 2 * _earthRadiusKm * math.asin(math.min(1.0, math.sqrt(h)));
  }

  static double _radians(double degrees) => degrees * math.pi / 180.0;
}
