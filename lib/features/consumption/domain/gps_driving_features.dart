// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import '../../../core/utils/geo_utils.dart' as geo;
import 'accel_event_gate.dart';
import 'trip_recorder.dart';

/// Lateral-acceleration threshold (m/s²) above which a turn counts as a
/// "sharp corner" event. 3.5 m/s² ≈ 0.36 g — the telematics convention
/// for a harsh-cornering event (Digital Matter 3.5 m/s²; Verizon 0.4 g
/// sustained; Geotab ~0.47 g). We sit at the conservative end of that
/// band so a brisk-but-controlled bend doesn't trip it.
const double kSharpCornerThresholdMps2 = 3.5;

/// Horizontal-accuracy ceiling (m) for trusting a fix's bearing in the
/// corner-load integral. A jittery fix (urban canyon / cold start)
/// reports a noisy heading that would manufacture a phantom corner, so
/// fixes worse than this are skipped — "a bad fix is worse than no fix"
/// (HDOP > 2.5–3.0 / accuracy > 10 m, per the GNSS telematics guidance).
const double kCornerAccuracyGateM = 10.0;

/// Driving-style aggregate derived from a stream of [TripSample]s
/// **without** any OBD2 telemetry — the lean feature set the GPS
/// calibration matrix (ADR 0010 / #2057 / Epic #2055) is fit against.
///
/// Pure transform. No vehicle, no matrix, no I/O. The caller passes
/// in the trajet's `Iterable<TripSample>`; the static
/// [GpsDrivingFeatures.from] returns the aggregate (or `null` when
/// the sample stream is empty / too short to produce a meaningful
/// figure).
///
/// Field names map 1:1 to the matrix design in
/// `docs/decisions/0010-gps-calibration-matrix.md`. The 4-coefficient
/// lean model consumes:
///
/// - `idleSeconds / totalSeconds` → `idleCost`
/// - `highSpeedSeconds / totalSeconds` → `highSpeedPenalty`
/// - `accelEvents / distanceKm` → `accelEventCost`
/// - the constant term (baseline)
///
/// The remaining fields ([brakeEvents], [gradeClimbMeters],
/// [gradeDescentMeters], [cornerLoadIntegral]) are captured so the
/// 7-coefficient expansion path doesn't have to revisit the recorder
/// when it lands.
class GpsDrivingFeatures {
  /// Seconds where `speedKmh < 5` — engine running, car stationary.
  final double idleSeconds;

  /// Seconds where `5 ≤ speedKmh < 50` — urban / start-stop.
  final double lowSpeedSeconds;

  /// Seconds where `50 ≤ speedKmh < 110` — cruise / extra-urban.
  final double cruiseSeconds;

  /// Seconds where `speedKmh ≥ 110` — highway, the fuel-cost penalty
  /// bucket. Plain integration of speed-band time so brief overspeeds
  /// don't dominate a long cruise leg.
  final double highSpeedSeconds;

  /// Count of acceleration events from the ONE shared accel-event gate
  /// (#2667): `d(speed)/dt ≥ kHardAccelThresholdMps2` (3.0) sustained for
  /// ≥ 1 s, accuracy-/min-speed-gated. One per physical episode — agrees
  /// with the harsh detector, the score, and the insights analyzer.
  final int accelEvents;

  /// Count of deceleration / brake events from the same shared gate
  /// (#2667): `d(speed)/dt ≤ −kHardBrakeThresholdMps2` (−3.5) sustained
  /// for ≥ 1 s. Reserved for the 7-coef expansion.
  final int brakeEvents;

  /// Peak absolute acceleration in g, sample-to-sample. Provides a
  /// cap for the harsh-event detector + a quick sanity ceiling for
  /// the fit (an `accelEventCost × accelEvents/km` term shouldn't
  /// explode when the user does one hard accel on an otherwise calm
  /// trajet).
  final double maxAccelG;

  /// Mean speed = `distanceKm / (totalSeconds / 3600)`. Convenience.
  final double meanSpeedKmh;

  /// Total trajet distance — sum of great-circle segment lengths
  /// between consecutive GPS-fix samples (samples lacking lat/lng
  /// integrate via `speedKmh × dt` for the segment they cover).
  final double distanceKm;

  /// Total wall-clock duration covered by the samples.
  final double totalSeconds;

  /// Cumulative altitude climbed (positive deltas summed). Reserved
  /// for the 7-coef expansion (`gradeClimbCost`).
  final double gradeClimbMeters;

  /// Cumulative altitude descended (absolute value of negative
  /// deltas summed). Reserved.
  final double gradeDescentMeters;

  /// Lateral-acceleration integral over the trajet (m/s² · s), a proxy
  /// for cumulative cornering g-load. Computed from the persisted
  /// `bearingDeg` (#2650): per segment `a_lat ≈ v · (dBearing/dt)`
  /// (yaw-rate × speed), accumulated as `|a_lat| · dt`. Higher = more
  /// aggressive cornering. Stays `0` on legacy trips that predate the
  /// persisted heading (#2655) and on fixes the accuracy gate rejects.
  final double cornerLoadIntegral;

  /// Count of sharp-corner events: segments whose lateral acceleration
  /// `|a_lat|` exceeds [kSharpCornerThresholdMps2] (#2655). Counted once
  /// per qualifying segment; `0` when heading is absent (legacy trips).
  final int sharpCornerEvents;

  const GpsDrivingFeatures({
    required this.idleSeconds,
    required this.lowSpeedSeconds,
    required this.cruiseSeconds,
    required this.highSpeedSeconds,
    required this.accelEvents,
    required this.brakeEvents,
    required this.maxAccelG,
    required this.meanSpeedKmh,
    required this.distanceKm,
    required this.totalSeconds,
    required this.gradeClimbMeters,
    required this.gradeDescentMeters,
    required this.cornerLoadIntegral,
    this.sharpCornerEvents = 0,
  });

  /// Idle share of the trajet (0.0–1.0). Used by the matrix's
  /// `idleCost` term. Returns 0 when the trajet has zero seconds
  /// (degenerate empty stream).
  double get idleShare =>
      totalSeconds > 0 ? idleSeconds / totalSeconds : 0.0;

  /// High-speed share (0.0–1.0). Used by the matrix's
  /// `highSpeedPenalty` term.
  double get highSpeedShare =>
      totalSeconds > 0 ? highSpeedSeconds / totalSeconds : 0.0;

  /// Acceleration events per km. Used by the matrix's
  /// `accelEventCost` term. Returns 0 for zero-distance trajets.
  double get accelEventsPerKm =>
      distanceKm > 0 ? accelEvents / distanceKm : 0.0;

  /// Sharp-corner events per km (#2655) — the cornering analogue of
  /// [accelEventsPerKm], normalised so a long calm motorway leg with one
  /// brisk exit ramp doesn't read worse than a short twisty drive.
  /// Returns 0 for zero-distance trajets.
  double get sharpCornersPerKm =>
      distanceKm > 0 ? sharpCornerEvents / distanceKm : 0.0;

  /// Derives the feature aggregate from [samples]. Returns `null`
  /// when the stream is empty or carries fewer than 2 samples (one
  /// sample = no integration possible).
  ///
  /// Speed-band integration uses each sample's `speedKmh` over the
  /// elapsed time to the next sample (rectangle rule — fine for
  /// 1 Hz GPS streams).
  ///
  /// Distance prefers great-circle math (`_haversineMeters`) when
  /// both samples carry lat/lng, falling back to `speedKmh × dt`
  /// for segments where either side is GPS-unfixed.
  ///
  /// Acceleration / brake events come from the ONE shared accel-event
  /// gate ([countAccelEvents], #2667): the canonical
  /// [kHardAccelThresholdMps2] / [kHardBrakeThresholdMps2] sustained ≥ 1 s
  /// with the accuracy + min-speed gate — so this number is identical to
  /// the harsh detector, the driving score, and the insights analyzer for
  /// the same physical event. (Pre-#2667 this file used a divergent
  /// 2.0 m/s² threshold with no accuracy / min-speed gate.)
  static GpsDrivingFeatures? from(Iterable<TripSample> samples) {
    final list = samples.toList();
    if (list.length < 2) return null;
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Hard accel / brake EPISODE counts via the shared gate (#2667). The
    // list is already timestamp-sorted; the gate copies + sorts again
    // defensively, which is cheap and keeps it the single authority.
    final accelCounts = countAccelEvents([
      for (final s in list)
        AccelSamplePoint(
          timestamp: s.timestamp,
          speedKmh: s.speedKmh,
          hAccuracyM: s.hAccuracyM,
        ),
    ]);

    double idle = 0, low = 0, cruise = 0, high = 0;
    double distM = 0;
    double maxAccelG = 0;
    double climb = 0, descent = 0;
    double cornerLoad = 0;
    int sharpCorners = 0;

    for (var i = 1; i < list.length; i++) {
      final prev = list[i - 1];
      final cur = list[i];
      final dt = cur.timestamp.difference(prev.timestamp).inMilliseconds /
          1000.0;
      if (dt <= 0 || dt > 60) continue; // gap — skip

      // Speed-band integration on the leading sample (rectangle rule).
      final v = prev.speedKmh;
      if (v < 5) {
        idle += dt;
      } else if (v < 50) {
        low += dt;
      } else if (v < 110) {
        cruise += dt;
      } else {
        high += dt;
      }

      // Distance — prefer haversine when both samples have a fix.
      final pLat = prev.latitude, pLng = prev.longitude;
      final cLat = cur.latitude, cLng = cur.longitude;
      if (pLat != null && pLng != null && cLat != null && cLng != null) {
        distM += _haversineMeters(pLat, pLng, cLat, cLng);
      } else {
        // m = (km/h × 1000/3600) × s
        distM += v / 3.6 * dt;
      }

      // Peak |acceleration| in g, sample-to-sample (a quick sanity ceiling
      // for the fit). The accel/brake EVENT counts come from the shared
      // gate above, not from this per-sample derivative.
      final accelMps2 = (cur.speedKmh - prev.speedKmh) / 3.6 / dt;
      final absG = accelMps2.abs() / 9.81;
      if (absG > maxAccelG) maxAccelG = absG;

      // Altitude delta.
      final pAlt = prev.altitudeM, cAlt = cur.altitudeM;
      if (pAlt != null && cAlt != null) {
        final dAlt = cAlt - pAlt;
        if (dAlt > 0) {
          climb += dAlt;
        } else {
          descent += -dAlt;
        }
      }

      // Corner-load integral (#2655). Now that #2650 persists `bearingDeg`
      // on every sample, lateral acceleration follows from yaw-rate ×
      // speed:  a_lat ≈ v · (dBearing/dt). The heading is null on legacy
      // (pre-#2650) samples and on cars/paths that never reported one, so
      // the term gracefully stays 0 for old data. Jittery fixes are gated
      // out (a noisy bearing manufactures phantom corners — a bad fix is
      // worse than no fix).
      final pBear = prev.bearingDeg, cBear = cur.bearingDeg;
      final pAcc = prev.hAccuracyM, cAcc = cur.hAccuracyM;
      final accurate = (pAcc == null || pAcc <= kCornerAccuracyGateM) &&
          (cAcc == null || cAcc <= kCornerAccuracyGateM);
      if (pBear != null && cBear != null && accurate) {
        // Signed minimal angular delta — handles the 0/360 wrap so a
        // 350°→10° step is +20°, not −340° ((d+540) mod 360) − 180.
        final dBearingDeg = ((cBear - pBear + 540.0) % 360.0) - 180.0;
        final yawRateRadPerSec = dBearingDeg * math.pi / 180.0 / dt;
        // v in m/s (speed in km/h ÷ 3.6) on the leading sample.
        final aLat = (v / 3.6) * yawRateRadPerSec;
        final absLat = aLat.abs();
        cornerLoad += absLat * dt;
        if (absLat > kSharpCornerThresholdMps2) sharpCorners++;
      }
    }

    final total = idle + low + cruise + high;
    if (total <= 0) return null;
    final distKm = distM / 1000.0;
    final meanSpeed = distKm / (total / 3600.0);

    return GpsDrivingFeatures(
      idleSeconds: idle,
      lowSpeedSeconds: low,
      cruiseSeconds: cruise,
      highSpeedSeconds: high,
      accelEvents: accelCounts.accelEvents,
      brakeEvents: accelCounts.brakeEvents,
      maxAccelG: maxAccelG,
      meanSpeedKmh: meanSpeed,
      distanceKm: distKm,
      totalSeconds: total,
      gradeClimbMeters: climb,
      gradeDescentMeters: descent,
      cornerLoadIntegral: cornerLoad,
      sharpCornerEvents: sharpCorners,
    );
  }

  /// Great-circle distance between two WGS-84 coordinates in metres.
  /// Delegates to the shared [geo.distanceMeters] (#2169).
  static double _haversineMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) =>
      geo.distanceMeters(lat1, lng1, lat2, lng2);
}
