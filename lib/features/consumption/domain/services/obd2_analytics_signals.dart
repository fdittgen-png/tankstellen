// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../data/obd2/fuel_rate_estimator.dart'
    show kPetrolAfr, kPetrolDensityGPerL, kDieselAfr, kDieselDensityGPerL;
import '../trip_recorder.dart';

/// RPM operating band (#2286). Aligns with the throttle/RPM histogram
/// card's edges (idle ≤ 900, cruise ≤ 2000, spirited ≤ 3000, hard >
/// 3000) so every analytics surface agrees on what "spirited" means and
/// matches `TripRecorder.highRpmThreshold` = 3000 at the hard cut.
enum RpmBand {
  /// Engine idling or barely turning (≤ 900 rpm).
  idle,

  /// Normal cruise (901–2000 rpm).
  cruise,

  /// Accelerating / lower gear / towing (2001–3000 rpm).
  spirited,

  /// High-RPM zone (> 3000 rpm) — the late-up-shift / over-revving cut.
  hard;

  /// Classify [rpm] into a band. Negative / zero rpm reads as [idle].
  static RpmBand fromRpm(double rpm) {
    if (rpm <= 900.0) return RpmBand.idle;
    if (rpm <= 2000.0) return RpmBand.cruise;
    if (rpm <= 3000.0) return RpmBand.spirited;
    return RpmBand.hard;
  }
}

/// Per-sample driver-analytics signals derived from the expanded OBD2
/// PID set (#2286), kept as a pure value object so it is computed on
/// demand from the persisted [TripSample] stream rather than widening
/// the persisted model.
///
/// The post-trip lessons (#2287) + consumption analytics consume these.
/// Every field degrades gracefully: when a source PID was absent for the
/// trip (GPS-only, no fuel-rate PID, no MAF) the derived field is null
/// rather than a bogus number.
class Obd2SampleSignals {
  const Obd2SampleSignals({
    required this.timestamp,
    required this.rpmBand,
    required this.idling,
    this.instantLPer100Km,
    this.accelG,
    this.harshAcceleration = false,
    this.harshDeceleration = false,
  });

  final DateTime timestamp;

  /// Instantaneous fuel use in L/100km, derived from the engine fuel
  /// rate (preferred) or MAF (fallback) against the road speed. Null when
  /// neither a fuel signal nor a positive speed is available (e.g. idling
  /// — infinite L/100km is meaningless, so we leave it null).
  final double? instantLPer100Km;

  /// Instantaneous acceleration in g vs. the previous sample (signed:
  /// positive = accelerating, negative = braking). Null for the first
  /// sample or an out-of-order timestamp.
  final double? accelG;

  /// True when [accelG] crossed the harsh-acceleration threshold.
  final bool harshAcceleration;

  /// True when [accelG] crossed the harsh-deceleration (braking)
  /// threshold.
  final bool harshDeceleration;

  /// True when the engine is running but the car is stationary
  /// (rpm > 0 ∧ speed ≈ 0) — idle / stop-and-go fuel waste.
  final bool idling;

  /// The RPM operating band at this sample.
  final RpmBand rpmBand;
}

/// Derivation of [Obd2SampleSignals] (#2286). Pure + side-effect free so
/// the math (fuel-rate vs MAF fallback, harsh classification, idle
/// detection, RPM band) is fully unit-testable without a transport.
class Obd2AnalyticsSignals {
  /// Harsh-acceleration threshold in g. Mirrors the m/s² threshold the
  /// [HarshEventDetector] uses (3.0 m/s² ÷ g).
  static const double harshAccelG = 3.0 / standardGravityMps2;

  /// Harsh-deceleration (braking) threshold in g (3.5 m/s² ÷ g).
  static const double harshBrakeG = 3.5 / standardGravityMps2;

  /// A car moving slower than this (km/h) counts as stationary for idle
  /// detection — covers GPS / wheel-speed jitter around a standstill.
  static const double idleSpeedEpsilonKmh = 1.5;

  /// Derive the per-sample signals for [sample]. [previous] (the prior
  /// sample) feeds the acceleration / harsh-event derivation; pass null
  /// for the first sample. [mafGramsPerSecond] enables the MAF fallback
  /// for the instantaneous L/100km when the sample carries no fuel rate.
  /// [diesel] selects the AFR / density pair for the MAF derivation.
  static Obd2SampleSignals derive(
    TripSample sample, {
    TripSample? previous,
    double? mafGramsPerSecond,
    bool diesel = false,
  }) {
    final lPer100 = instantLPer100Km(
      fuelRateLPerHour: sample.fuelRateLPerHour,
      speedKmh: sample.speedKmh,
      mafGramsPerSecond: mafGramsPerSecond,
      diesel: diesel,
    );
    double? accelG;
    if (previous != null) {
      final dt = sample.timestamp.difference(previous.timestamp).inMicroseconds /
          Duration.microsecondsPerSecond;
      accelG = accelGForInterval(
        prevSpeedKmh: previous.speedKmh,
        currSpeedKmh: sample.speedKmh,
        dtSeconds: dt,
      );
    }
    return Obd2SampleSignals(
      timestamp: sample.timestamp,
      // #2692 C4-G — GPS-only rpm null reads as 0 (→ idle band, harmless:
      // only `idling`, gated on a real rpm > 0, drives the idle lesson).
      rpmBand: RpmBand.fromRpm(sample.rpm ?? 0),
      idling: isIdling(rpm: sample.rpm, speedKmh: sample.speedKmh),
      instantLPer100Km: lPer100,
      accelG: accelG,
      harshAcceleration: accelG != null && accelG >= harshAccelG,
      harshDeceleration: accelG != null && accelG <= -harshBrakeG,
    );
  }

  /// Instantaneous L/100km. Prefers the directly-read [fuelRateLPerHour]
  /// (PID 5E or any source already on the sample); otherwise derives the
  /// flow from [mafGramsPerSecond] via the stoichiometric mass-air-flow
  /// formula `L/h = MAF × 3600 / (AFR × density)`. Returns null when
  /// there is no fuel signal or the car is not moving (a stationary
  /// engine has no per-distance figure).
  static double? instantLPer100Km({
    required double? fuelRateLPerHour,
    required double speedKmh,
    double? mafGramsPerSecond,
    bool diesel = false,
  }) {
    if (speedKmh <= 0) return null;
    final rate = fuelRateLPerHour ??
        fuelRateFromMaf(
          mafGramsPerSecond: mafGramsPerSecond,
          diesel: diesel,
        );
    if (rate == null || rate < 0) return null;
    // L/h ÷ km/h × 100 = L per 100 km.
    return (rate / speedKmh) * 100.0;
  }

  /// Derive engine fuel rate (L/h) from mass air flow (#2286 fallback
  /// when PID 5E is unsupported). `L/h = MAF_g_per_s × 3600 / (AFR ×
  /// density)`. Diesel runs a leaner AFR + denser fuel than petrol.
  /// Returns null for a null / non-positive MAF.
  static double? fuelRateFromMaf({
    required double? mafGramsPerSecond,
    bool diesel = false,
  }) {
    final maf = mafGramsPerSecond;
    if (maf == null || maf <= 0) return null;
    final afr = diesel ? kDieselAfr : kPetrolAfr;
    final density = diesel ? kDieselDensityGPerL : kPetrolDensityGPerL;
    return maf * 3600.0 / (afr * density);
  }

  /// Idle detection (#2286): the engine is turning ([rpm] > 0) but the
  /// car is effectively stationary (speed within [idleSpeedEpsilonKmh]
  /// of zero) — the fuel-wasting stop-and-go / red-light dwell the idling
  /// lesson penalises. #2692 C4-G — a GPS-only sample carries rpm null
  /// (no engine signal) and can never be classified as idling.
  static bool isIdling({required double? rpm, required double speedKmh}) {
    return rpm != null && rpm > 0 && speedKmh.abs() <= idleSpeedEpsilonKmh;
  }
}
