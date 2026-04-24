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
/// * climbing — linear ramp over 0–8 % grade.
/// * decel — 1.0 when `accel < -0.5 m/s²` AND throttle < 5 %.
/// * fuelCut — 1.0 when throttle < 5 % AND rpm > 1500 AND
///   speed > 20 km/h. When fuelCut fires it zeros-out decel.
///
/// All six of the continuous memberships are computed first, the
/// fuel-cut override is applied, then the vector is L1-normalized.
/// If every membership would be zero (e.g. coasting at 65 km/h with
/// no other signal) urban wins — that's the gentlest fallback, and
/// prevents a divide-by-zero.
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
  }) {
    final raw = <Situation, double>{
      Situation.idle: _idleMembership(speedKmh),
      Situation.urban: _urbanMembership(speedKmh),
      Situation.stopAndGo: isStopAndGoContext
          ? _urbanMembership(speedKmh)
          : 0.0,
      Situation.highway: _highwayMembership(speedKmh),
      Situation.climbing: _climbingMembership(grade),
      Situation.decel: _decelMembership(accel, throttlePct),
      Situation.fuelCut: _fuelCutMembership(throttlePct, rpm, speedKmh),
    };

    // Fuel-cut overrides decel — both conditions can be satisfied at
    // once on a cruise-controlled downhill, but the more specific
    // fuel-cut signal should win the vote so the baseline store
    // doesn't double-count the same physical event.
    if (raw[Situation.fuelCut]! > 0) {
      raw[Situation.decel] = 0;
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

  /// Linear ramp in road grade: 0 % → 0, 8 % → 1, saturates at 1.
  double _climbingMembership(double grade) {
    if (grade <= 0) return 0;
    if (grade >= 8) return 1;
    return grade / 8;
  }

  /// Hard threshold: 1.0 when the driver is decelerating AND off the
  /// pedal, 0 otherwise.
  double _decelMembership(double accel, double throttlePct) =>
      (accel < -0.5 && throttlePct < 5) ? 1 : 0;

  /// Hard threshold: 1.0 when the injectors are cut — throttle closed
  /// but the engine still spinning fast while the car rolls.
  double _fuelCutMembership(double throttlePct, double rpm, double speed) =>
      (throttlePct < 5 && rpm > 1500 && speed > 20) ? 1 : 0;

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
