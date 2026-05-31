// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

/// Seven mutually-overlapping driving situations the fuzzy
/// classifier (#894) can split a single sample across. Mirrors the
/// six steady-state `DrivingSituation` values the #779 baseline
/// store persists today, plus [fuelCut] (a transient the #768
/// classifier already tracked as an event) for symmetry with the
/// rule-based path.
///
/// Keeping our own enum instead of re-using `DrivingSituation` keeps
/// the vehicle layer independent of `lib/features/consumption/**` —
/// providers that wire the fuzzy output back into the Welford store
/// do the one-to-one mapping themselves.
enum Situation {
  idle,
  urban,
  stopAndGo,
  highway,
  climbing,
  decel,
  fuelCut,

  // --- #2515 (epic #2512) new calibration buckets -----------------
  /// Engine below operating temperature — open-loop enrichment burns
  /// proportionally more fuel during warm-up. A **high-priority
  /// override**: while it has any membership the steady-state buckets
  /// are zeroed so warm-up samples never pollute the steady means
  /// (persistence is keyed by `.name`, so appending mid-enum is
  /// ordinal-safe; we append to be tidy regardless).
  coldStart,

  /// High load held steady on a **flat** road (towing / fully loaded),
  /// distinct from a hill — the load ramp only feeds [climbing] when
  /// there is a grade, so on the flat a sustained high load lands here.
  sustainedLoad,

  /// Gentle engine-braking / coast where the injectors still fire —
  /// the band between [decel] (harder lift-off) and [fuelCut] (closed
  /// throttle, injectors cut). Disjoint accel band from [decel].
  partialDecel,
}

/// Pure-function fuzzy membership classifier.
///
/// Given the five inputs a `DrivingSample` carries (plus a caller-
/// owned "stop-and-go context" flag — see [classify]) returns a
/// normalized membership vector — values in [0, 1] summing to 1.0
/// within 1e-6. The downstream calibration logic feeds each entry
/// as a weighted vote into the Welford accumulator rather than
/// winner-take-all the way #779's rule-based path does.
///
/// Membership functions are the ones specified in the #894 ticket:
///
/// * idle — triangle, peak at 0 km/h, shoulders 0–5 km/h.
/// * urban — trapezoid 5-25-45-60 km/h.
/// * stopAndGo — urban-shaped, gated by the caller-owned
///   [isStopAndGoContext] flag (30-second speed-variance window).
/// * highway — trapezoid 70-90-130-200 km/h.
/// * climbing — `max` of two ramps so the bucket fills whether or not
///   the car has a confident GPS-altitude grade (#2513): a linear ramp
///   over 0–8 % road grade, **or** a load ramp over 45 %→70 % engine /
///   absolute load (a heavily-loaded car working hard on the flat is
///   the same baseline as a climb). Either signal alone reaches 1.0,
///   so "climbing/loaded" never depends on a single optional input.
/// * decel — 1.0 when `accel < -0.5 m/s²` AND throttle < 5 %.
/// * fuelCut — 1.0 when throttle < 5 % AND rpm > 1500 AND
///   speed > 20 km/h. When fuelCut fires it zeros-out decel AND
///   partialDecel.
/// * coldStart (#2515) — engine below operating temperature. Ramps
///   1.0 at ≤40 °C coolant → 0 at 70 °C (or, when coolant is null, the
///   oil ramp 1.0 at ≤30 °C → 0 at 60 °C). A **high-priority
///   override**: when its membership is > 0 every steady-state bucket
///   (idle/urban/stopAndGo/highway/climbing/sustainedLoad) is zeroed so
///   warm-up samples record ONLY against coldStart.
/// * sustainedLoad (#2515) — high load held steady on a FLAT road
///   (towing). Non-zero only when `grade < 2 % && speed > 20 km/h &&
///   load ≥ 60 %` (load ramp 60→75 % → 0→1). [climbing]'s load ramp is
///   re-split to only feed climbing when there IS a grade, so on the
///   flat a sustained high load lands here instead — the union of the
///   two is unchanged, only the means are separated.
/// * partialDecel (#2515) — gentle engine-braking / coast where the
///   injectors still fire, between [decel] (`accel < -0.5`) and
///   [fuelCut]. Non-zero when `accel ∈ [-0.5, -0.1) && throttle < 5 %
///   && speed > 15 km/h`. Disjoint accel band from [decel], so the two
///   never double-count; fuelCut zeros it just like decel.
///
/// All of the continuous memberships are computed first, the fuel-cut
/// and cold-start overrides are applied, then the vector is
/// L1-normalized. If every membership would be zero (e.g. coasting at
/// 65 km/h with no other signal) urban wins — that's the gentlest
/// fallback, and prevents a divide-by-zero.
class FuzzyClassifier {
  const FuzzyClassifier();

  /// Normalized membership vector for one sample. `isStopAndGoContext`
  /// is the caller's 30-second speed-variance flag — the classifier
  /// doesn't own the rolling window itself (that lives in the sample
  /// provider), it just needs the outcome.
  Map<Situation, double> classify({
    required double speedKmh,
    required double accel,
    required double grade,
    required double throttlePct,
    required double rpm,
    bool isStopAndGoContext = false,
    double loadPct = 0,
    // --- #2515 precision signals (default-null so existing callers
    // compile unchanged) ---------------------------------------------
    double? coolantTempC,
    double? oilTempC,
    double? ambientTempC,
    double? pedalPct,
  }) {
    final raw = <Situation, double>{
      Situation.idle: _idleMembership(speedKmh),
      Situation.urban: _urbanMembership(speedKmh),
      Situation.stopAndGo: isStopAndGoContext
          ? _urbanMembership(speedKmh)
          : 0.0,
      Situation.highway: _highwayMembership(speedKmh),
      Situation.climbing: _climbingMembership(grade, loadPct),
      Situation.decel: _decelMembership(accel, throttlePct),
      Situation.fuelCut: _fuelCutMembership(throttlePct, rpm, speedKmh),
      // #2515 — three new buckets.
      Situation.coldStart: _coldStartMembership(coolantTempC, oilTempC),
      Situation.sustainedLoad:
          _sustainedLoadMembership(grade, speedKmh, loadPct),
      Situation.partialDecel:
          _partialDecelMembership(accel, throttlePct, speedKmh),
    };

    // Fuel-cut overrides decel AND partialDecel — all three can be
    // satisfied at once on a cruise-controlled downhill, but the more
    // specific fuel-cut signal should win the vote so the baseline
    // store doesn't double-count the same physical event (#2515 extends
    // the original decel-only override to partialDecel too).
    if (raw[Situation.fuelCut]! > 0) {
      raw[Situation.decel] = 0;
      raw[Situation.partialDecel] = 0;
    }

    // #2515 — cold-start is a HIGH-PRIORITY override: while the engine
    // is below operating temperature it burns enrichment fuel, so a
    // warm-up sample must NOT bleed into the steady-state means. Zero
    // every steady-state bucket so the sample records only against
    // coldStart. The transient decel/fuelCut/partialDecel buckets are
    // left untouched (a cold engine can still coast).
    if (raw[Situation.coldStart]! > 0) {
      raw[Situation.idle] = 0;
      raw[Situation.urban] = 0;
      raw[Situation.stopAndGo] = 0;
      raw[Situation.highway] = 0;
      raw[Situation.climbing] = 0;
      raw[Situation.sustainedLoad] = 0;
    }

    var sum = 0.0;
    for (final v in raw.values) {
      sum += v;
    }
    if (sum <= 0) {
      // Nothing matched — fall back to urban so the result is still a
      // valid probability vector.
      return {
        for (final s in Situation.values)
          s: s == Situation.urban ? 1.0 : 0.0,
      };
    }
    return {
      for (final entry in raw.entries) entry.key: entry.value / sum,
    };
  }

  // --- Membership function primitives ---------------------------------

  /// Triangle peak at 0, shoulders 0 → 5 km/h. Membership is 1.0 at
  /// standstill, linearly decays to 0 at 5 km/h.
  double _idleMembership(double speed) {
    if (speed <= 0) return 1;
    if (speed >= 5) return 0;
    return 1 - (speed / 5);
  }

  /// Trapezoid 5-25-45-60: ramp up 5→25, plateau 25→45, ramp down 45→60.
  double _urbanMembership(double speed) => _trapezoid(speed, 5, 25, 45, 60);

  /// Trapezoid 70-90-130-200. At 120 km/h membership is 1.0; above
  /// 200 km/h (very rare) it drops back to 0.
  double _highwayMembership(double speed) =>
      _trapezoid(speed, 70, 90, 130, 200);

  /// Climbing / heavily-loaded membership (#2513, re-split #2515).
  /// Either of two independent signals can fill this bucket and we take
  /// their `max`:
  ///
  ///  * **grade ramp** — linear in road grade: 0 % → 0, 8 % → 1. Only
  ///    non-zero once the [RoadGradeCalculator] reports a *confident*
  ///    grade from smoothed GPS altitude; cars without GPS altitude
  ///    pass `grade: 0` and this term stays 0.
  ///  * **load ramp** — linear in engine / absolute load: 45 % → 0,
  ///    70 % → 1, **but only when there IS a grade** (`grade ≥ 2 %`).
  ///
  /// #2515 re-split: the load ramp used to feed climbing on the flat
  /// too, which conflated a hill with a flat tow. Now a sustained high
  /// load on the flat lands in [sustainedLoad] instead and the load
  /// ramp only reinforces climbing when a grade is present. The union
  /// of the two buckets is identical to the pre-#2515 climbing bucket —
  /// only the means are separated.
  ///
  /// Both terms saturate at 1.0.
  double _climbingMembership(double grade, double loadPct) =>
      math.max(_gradeRamp(grade), grade >= 2 ? _loadRamp(loadPct) : 0.0);

  /// Linear ramp in road grade: 0 % → 0, 8 % → 1, saturates at 1.
  double _gradeRamp(double grade) {
    if (grade <= 0) return 0;
    if (grade >= 8) return 1;
    return grade / 8;
  }

  /// Linear ramp in engine / absolute load: 45 % → 0, 70 % → 1,
  /// saturates at 1. Below 45 % the engine is loafing — not a climb /
  /// load situation.
  double _loadRamp(double loadPct) {
    if (loadPct <= 45) return 0;
    if (loadPct >= 70) return 1;
    return (loadPct - 45) / (70 - 45);
  }

  /// Hard threshold: 1.0 when the driver is decelerating AND off the
  /// pedal, 0 otherwise.
  double _decelMembership(double accel, double throttlePct) =>
      (accel < -0.5 && throttlePct < 5) ? 1 : 0;

  /// Hard threshold: 1.0 when the injectors are cut — throttle closed
  /// but the engine still spinning fast while the car rolls.
  double _fuelCutMembership(double throttlePct, double rpm, double speed) =>
      (throttlePct < 5 && rpm > 1500 && speed > 20) ? 1 : 0;

  /// Cold-start / warm-up membership (#2515). The engine is below
  /// operating temperature and running open-loop rich. Prefers coolant
  /// (PID 0x05): ramp 1.0 at ≤40 °C → 0 at 70 °C. When coolant is null,
  /// falls back to oil temp (PID 0x5C): ramp 1.0 at ≤30 °C → 0 at
  /// 60 °C. Returns 0 when neither temperature is available (we can't
  /// claim a cold start without evidence). [ambientTempC] is plumbed
  /// for PR 2's precision folding and intentionally unused here.
  double _coldStartMembership(double? coolantTempC, double? oilTempC) {
    if (coolantTempC != null) return _coolingRamp(coolantTempC, 40, 70);
    if (oilTempC != null) return _coolingRamp(oilTempC, 30, 60);
    return 0;
  }

  /// Descending ramp: 1.0 at or below [cold], 0 at or above [warm],
  /// linear between. Used for the temperature-based cold-start signal.
  double _coolingRamp(double tempC, double cold, double warm) {
    if (tempC <= cold) return 1;
    if (tempC >= warm) return 0;
    return (warm - tempC) / (warm - cold);
  }

  /// Sustained-load / towing membership (#2515). High load held steady
  /// on a FLAT road — distinct from a hill. Non-zero only when the road
  /// is flat (`grade < 2 %`), the car is actually moving (`speed >
  /// 20 km/h`) and the engine is working hard (`load ≥ 60 %`). The load
  /// ramp runs 60 % → 0, 75 % → 1.
  double _sustainedLoadMembership(
    double grade,
    double speedKmh,
    double loadPct,
  ) {
    if (grade >= 2 || speedKmh <= 20 || loadPct < 60) return 0;
    if (loadPct >= 75) return 1;
    return (loadPct - 60) / (75 - 60);
  }

  /// Partial-throttle / gentle-coast membership (#2515). The band
  /// between [decel] (`accel < -0.5`) and [fuelCut] (closed throttle,
  /// injectors cut): the driver has lifted off gently, the car is
  /// slowing but the injectors still fire. Hard threshold: 1.0 when
  /// `accel ∈ [-0.5, -0.1) && throttle < 5 % && speed > 15 km/h`, else
  /// 0. The accel band is disjoint from [decel]'s `< -0.5`, so the two
  /// can never double-count the same sample.
  double _partialDecelMembership(
    double accel,
    double throttlePct,
    double speedKmh,
  ) =>
      (accel >= -0.5 && accel < -0.1 && throttlePct < 5 && speedKmh > 15)
          ? 1
          : 0;

  /// Trapezoidal membership: rises 0→1 across [a, b], stays at 1 across
  /// [b, c], falls 1→0 across [c, d]. Returns 0 outside [a, d].
  double _trapezoid(double x, double a, double b, double c, double d) {
    assert(a <= b && b <= c && c <= d,
        'trapezoid parameters must satisfy a ≤ b ≤ c ≤ d');
    if (x <= a || x >= d) return 0;
    if (x >= b && x <= c) return 1;
    if (x < b) return (x - a) / math.max(b - a, 1e-9);
    return (d - x) / math.max(d - c, 1e-9);
  }
}
