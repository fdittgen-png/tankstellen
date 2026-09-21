// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../../../core/domain/fuzzy_membership.dart';

/// The linguistic variables of the fuzzy consumption engine (#4232) — their
/// units, plausible domains, freshness horizons and fuzzy terms.
///
/// ## Where the breakpoints come from
///
/// Nothing here is fitted: #4231's corpus holds no real trace yet. Every
/// breakpoint is either **reused** from code that already classifies the
/// same signal, or a **definitional** edge stated as such. The table in
/// `docs/decisions/0023-fuzzy-consumption-engine.md` lists each one with its
/// origin. Constants restated from files this pure-Dart library cannot
/// import (they pull in Flutter) are pinned by a parity test.
///
/// ## Partition shape
///
/// Every variable is a **Ruspini partition**: at every point of its domain
/// the memberships of its terms sum to exactly 1, adjacent terms overlap,
/// the first term is non-increasing and the last non-decreasing. So a
/// fresh reading always belongs somewhere — there is no gap where every
/// rule silently goes dark (the `FuzzyClassifier` covers its 60–70 km/h
/// gap with an urban fallback instead; the engine closes it with `rural`).
enum FuzzyVariable {
  /// Ground speed, km/h. Domain `[0, 400]`, horizon 3 s.
  speed(min: 0, max: 400, staleAfterSeconds: 3,
      terms: [FuzzyTerm.standstill, FuzzyTerm.urban, FuzzyTerm.rural,
        FuzzyTerm.highway]),

  /// Longitudinal acceleration, m/s². Domain `[-15, 15]`, horizon 3 s.
  accel(min: -15, max: 15, staleAfterSeconds: 3,
      terms: [FuzzyTerm.braking, FuzzyTerm.steady, FuzzyTerm.accelerating]),

  /// Confident road grade, percent. Domain `[-40, 40]`, horizon 10 s (the
  /// grade is a distance-window smoothing, slower than a 1 Hz tick).
  grade(min: -40, max: 40, staleAfterSeconds: 10,
      terms: [FuzzyTerm.downhill, FuzzyTerm.flat, FuzzyTerm.uphill]),

  /// Yaw-rate magnitude, rad/s. Domain `[-5, 5]`, horizon 3 s.
  curvature(min: -5, max: 5, staleAfterSeconds: 3,
      terms: [FuzzyTerm.straight, FuzzyTerm.curving]),

  /// Stops in the trailing minute. Domain `[0, 60]`, horizon 10 s.
  stops(min: 0, max: 60, staleAfterSeconds: 10,
      terms: [FuzzyTerm.flowing, FuzzyTerm.stopAndGo]),

  /// Engine speed, rev/min. Domain `[0, 12000]`, horizon 3 s.
  rpm(min: 0, max: 12000, staleAfterSeconds: 3,
      terms: [FuzzyTerm.low, FuzzyTerm.mid, FuzzyTerm.high]),

  /// Engine / absolute load, percent. Domain `[0, 400]` (absolute load on a
  /// boosted engine legitimately exceeds 100), horizon 3 s.
  load(min: 0, max: 400, staleAfterSeconds: 3,
      terms: [FuzzyTerm.light, FuzzyTerm.heavy]),

  /// Throttle position, percent. Domain `[0, 100]`, horizon 3 s.
  throttle(min: 0, max: 100, staleAfterSeconds: 3,
      terms: [FuzzyTerm.closed, FuzzyTerm.open]),

  /// Coolant temperature, °C. Domain `[-50, 150]`, horizon 60 s (it moves
  /// on a minutes scale and is read on a slow tier).
  coolantTemp(min: -50, max: 150, staleAfterSeconds: 60,
      terms: [FuzzyTerm.cold, FuzzyTerm.warm]),

  /// Oil temperature, °C. Domain `[-50, 180]`, horizon 60 s.
  oilTemp(min: -50, max: 180, staleAfterSeconds: 60,
      terms: [FuzzyTerm.cold, FuzzyTerm.warm]),

  /// Vehicle mass, kg. Domain `[300, 10000]`; a static parameter, so it
  /// never goes stale.
  vehicleMass(min: 300, max: 10000, staleAfterSeconds: double.infinity,
      terms: [FuzzyTerm.light, FuzzyTerm.medium, FuzzyTerm.heavy]);

  const FuzzyVariable({
    required this.min,
    required this.max,
    required this.staleAfterSeconds,
    required this.terms,
  });

  /// Plausible domain; a reading outside it is `invalid`, not clamped.
  final double min;
  final double max;

  /// Age beyond which a reading is `stale` and no longer used.
  final double staleAfterSeconds;

  /// The terms partitioning this variable, lowest first.
  final List<FuzzyTerm> terms;

  /// Membership of [x] in [term], in `[0, 1]`.
  ///
  /// [x] must already be validated (finite, inside the domain). A [term]
  /// that is not one of [terms] has membership 0 — the rule-base test
  /// asserts no rule ever asks for one.
  double membership(FuzzyTerm term, double x) {
    const m = FuzzyMembership.trapezoid;
    const down = FuzzyMembership.rampDown;
    const up = FuzzyMembership.rampUp;
    return switch ((this, term)) {
      // Speed — `FuzzyClassifier` #894: idle 0→5, urban plateau to 45,
      // highway rising 70→90. `rural` closes the classifier's 60–70 gap.
      (FuzzyVariable.speed, FuzzyTerm.standstill) => down(x, 0, 5),
      (FuzzyVariable.speed, FuzzyTerm.urban) => m(x, 0, 5, 45, 70),
      (FuzzyVariable.speed, FuzzyTerm.rural) => m(x, 45, 70, 70, 90),
      (FuzzyVariable.speed, FuzzyTerm.highway) => up(x, 70, 90),
      // Accel — `FuzzyClassifier` #2515 coast band edges ±0.1 / −0.5;
      // acceleration saturates at the oscillation threshold (#4203).
      (FuzzyVariable.accel, FuzzyTerm.braking) =>
        down(x, kFuzzyDecelEdgeMps2, -kFuzzyCoastEdgeMps2),
      (FuzzyVariable.accel, FuzzyTerm.steady) => m(x, kFuzzyDecelEdgeMps2,
          -kFuzzyCoastEdgeMps2, kFuzzyCoastEdgeMps2, kFuzzyAccelSaturationMps2),
      (FuzzyVariable.accel, FuzzyTerm.accelerating) =>
        up(x, kFuzzyCoastEdgeMps2, kFuzzyAccelSaturationMps2),
      // Grade — `FuzzyClassifier` #2513 ramp 0→8 %, mirrored downhill.
      (FuzzyVariable.grade, FuzzyTerm.downhill) => down(x, -8, 0),
      (FuzzyVariable.grade, FuzzyTerm.flat) => m(x, -8, 0, 0, 8),
      (FuzzyVariable.grade, FuzzyTerm.uphill) => up(x, 0, 8),
      // Curvature — centred on #4203's turning threshold.
      (FuzzyVariable.curvature, FuzzyTerm.straight) =>
        down(x.abs(), kFuzzyCurveYawRateRadPerS / 2,
            kFuzzyCurveYawRateRadPerS * 1.5),
      (FuzzyVariable.curvature, FuzzyTerm.curving) =>
        up(x.abs(), kFuzzyCurveYawRateRadPerS / 2,
            kFuzzyCurveYawRateRadPerS * 1.5),
      // Stops — definitional: 0 stops/min flowing, 2 stops/min stop-and-go.
      (FuzzyVariable.stops, FuzzyTerm.flowing) => down(x, 0, 2),
      (FuzzyVariable.stops, FuzzyTerm.stopAndGo) => up(x, 0, 2),
      // RPM — `FuzzyClassifier` fuel-cut edge 1500, 1000 rev/min steps.
      (FuzzyVariable.rpm, FuzzyTerm.low) => down(x, 1500, 2500),
      (FuzzyVariable.rpm, FuzzyTerm.mid) => m(x, 1500, 2500, 2500, 3500),
      (FuzzyVariable.rpm, FuzzyTerm.high) => up(x, 2500, 3500),
      // Load — `FuzzyClassifier` #2513 load ramp 45→70 %.
      (FuzzyVariable.load, FuzzyTerm.light) => down(x, 45, 70),
      (FuzzyVariable.load, FuzzyTerm.heavy) => up(x, 45, 70),
      // Throttle — `FuzzyClassifier`'s closed-throttle edge 5 %.
      (FuzzyVariable.throttle, FuzzyTerm.closed) => down(x, 5, 15),
      (FuzzyVariable.throttle, FuzzyTerm.open) => up(x, 5, 15),
      // Temperatures — `FuzzyClassifier` #2515 cold-start ramps.
      (FuzzyVariable.coolantTemp, FuzzyTerm.cold) => down(x, 40, 70),
      (FuzzyVariable.coolantTemp, FuzzyTerm.warm) => up(x, 40, 70),
      (FuzzyVariable.oilTemp, FuzzyTerm.cold) => down(x, 30, 60),
      (FuzzyVariable.oilTemp, FuzzyTerm.warm) => up(x, 30, 60),
      // Mass — `VehicleRoadLoadParameters` body-class bounds (#4209):
      // compact ≤ 1450 kg, SUV > 1750 kg, midsize peaking between them.
      (FuzzyVariable.vehicleMass, FuzzyTerm.light) =>
        down(x, kFuzzyCompactMaxKg, _midsizePeakKg),
      (FuzzyVariable.vehicleMass, FuzzyTerm.medium) => m(x,
          kFuzzyCompactMaxKg, _midsizePeakKg, _midsizePeakKg,
          kFuzzyMidsizeMaxKg),
      (FuzzyVariable.vehicleMass, FuzzyTerm.heavy) =>
        up(x, _midsizePeakKg, kFuzzyMidsizeMaxKg),
      _ => 0,
    };
  }
}

/// The fuzzy terms. Shared across variables where the word means the same
/// thing (`light` load, `light` vehicle); which terms a variable owns is
/// [FuzzyVariable.terms].
enum FuzzyTerm {
  standstill,
  urban,
  rural,
  highway,
  braking,
  steady,
  accelerating,
  downhill,
  flat,
  uphill,
  straight,
  curving,
  flowing,
  stopAndGo,
  low,
  mid,
  high,
  light,
  medium,
  heavy,
  closed,
  open,
  cold,
  warm,
}

// ─── Restated constants (parity-tested against their owners) ───

/// `FuzzyClassifier`'s decel edge (#894): below −0.5 m/s² is braking.
const double kFuzzyDecelEdgeMps2 = -0.5;

/// `FuzzyClassifier`'s partial-decel upper edge (#2515), mirrored for
/// acceleration: within ±0.1 m/s² the car is holding speed.
const double kFuzzyCoastEdgeMps2 = 0.1;

/// `road_load_track.dart` `kOscillationAccelMps2` (#4203).
const double kFuzzyAccelSaturationMps2 = 1.5;

/// `road_load_track.dart` `kCurveYawRateRadPerS` (#4203).
const double kFuzzyCurveYawRateRadPerS = 0.08;

/// `VehicleRoadLoadParameters.compactMaxKg` / `.midsizeMaxKg` (#4209).
const double kFuzzyCompactMaxKg = 1450;
const double kFuzzyMidsizeMaxKg = 1750;

/// The midsize term peaks half-way between the two body-class bounds.
const double _midsizePeakKg = (kFuzzyCompactMaxKg + kFuzzyMidsizeMaxKg) / 2;
