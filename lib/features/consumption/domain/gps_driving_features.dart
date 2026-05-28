// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/utils/geo_utils.dart' as geo;
import 'trip_recorder.dart';

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

  /// Count of acceleration events: `d(speed)/dt > 2 m/s²` sustained
  /// for > 1 s. Counted once per event, not per sample.
  final int accelEvents;

  /// Count of deceleration / brake events: `d(speed)/dt < −2 m/s²`
  /// sustained for > 1 s. Reserved for the 7-coef expansion.
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

  /// Heading-rate × speed² integral — a proxy for lateral g-load over
  /// the trajet. Higher = more aggressive cornering. Reserved.
  final double cornerLoadIntegral;

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
  /// Acceleration events: rolling window detects `> 2 m/s²` (or
  /// `< -2 m/s²`) sustained for ≥ 1 s — the same threshold the
  /// trip recorder's harsh-event detector uses, so the two numbers
  /// agree on what counts as "an event".
  static GpsDrivingFeatures? from(Iterable<TripSample> samples) {
    final list = samples.toList();
    if (list.length < 2) return null;
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    double idle = 0, low = 0, cruise = 0, high = 0;
    double distM = 0;
    int accelEvents = 0, brakeEvents = 0;
    double maxAccelG = 0;
    double climb = 0, descent = 0;
    double cornerLoad = 0;

    // Acceleration-event detector state.
    bool inAccelEvent = false, inBrakeEvent = false;
    double accelEventDur = 0, brakeEventDur = 0;

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

      // Acceleration in m/s² (signed). speed in km/h → m/s via /3.6.
      final accelMps2 = (cur.speedKmh - prev.speedKmh) / 3.6 / dt;
      final absG = accelMps2.abs() / 9.81;
      if (absG > maxAccelG) maxAccelG = absG;

      // Sustained > 1 s windowing for accel / brake events.
      if (accelMps2 > 2.0) {
        accelEventDur += dt;
        if (!inAccelEvent && accelEventDur >= 1.0) {
          accelEvents++;
          inAccelEvent = true;
        }
      } else {
        accelEventDur = 0;
        inAccelEvent = false;
      }
      if (accelMps2 < -2.0) {
        brakeEventDur += dt;
        if (!inBrakeEvent && brakeEventDur >= 1.0) {
          brakeEvents++;
          inBrakeEvent = true;
        }
      } else {
        brakeEventDur = 0;
        inBrakeEvent = false;
      }

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

      // Corner-load integral: |Δheading| ≈ atan2(crossTrack) — we don't
      // have heading directly, so approximate via successive bearings
      // when 3 GPS-fixed samples are available. For v1 we keep this
      // term at zero unless extended in #G; the 4-coef lean fit
      // doesn't read it. Field stays present for the future expansion.
      cornerLoad += 0;
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
      accelEvents: accelEvents,
      brakeEvents: brakeEvents,
      maxAccelG: maxAccelG,
      meanSpeedKmh: meanSpeed,
      distanceKm: distKm,
      totalSeconds: total,
      gradeClimbMeters: climb,
      gradeDescentMeters: descent,
      cornerLoadIntegral: cornerLoad,
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
