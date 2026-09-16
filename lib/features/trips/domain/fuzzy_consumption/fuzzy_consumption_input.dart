// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

import 'fuzzy_variables.dart';

/// Which physics arithmetic produced the per-sample fuel-rate estimate the
/// fuzzy engine refines (#4232, Epic #4222).
///
/// The physics stays an **input feature**, never replaced: the engine only
/// scales it by a rule-base multiplier plus a residual. The basis decides
/// the confidence ceiling (see [FuzzyConfidencePriors]) and which
/// `ConsumptionSourceClass` the estimate is stamped with.
enum FuzzyPhysicsBasis {
  /// MAF air mass (the dual-sensor or legacy MAF PID) through the resolved
  /// AFR / density (`live_sample_snapshot_fuel_rate.dart`).
  maf,

  /// Speed-density (MAP + IAT + RPM) through η_v, AFR and density.
  speedDensity,

  /// `GpsLiveFuelEstimator`'s road-load force balance — no engine data.
  gpsRoadLoad,
}

/// Which ECU fuel reading a native rate came from — the three branches
/// Epic #4222's *Source semantics* call **measured**.
enum NativeFuelRateSource { pid9D, pidA2, pid5E }

/// One timestamped signal: its value and how old it is.
///
/// Age rather than a timestamp keeps the engine free of any clock (the
/// caller already knows "now"), which is what makes inference
/// deterministic for identical inputs.
@immutable
class FuzzyReading {
  const FuzzyReading(this.value, {this.ageSeconds = 0});

  /// The value, in the unit its [FuzzyVariable] documents.
  final double value;

  /// Seconds since the value was read. `0` is "this tick".
  final double ageSeconds;

  @override
  bool operator ==(Object other) =>
      other is FuzzyReading &&
      other.value == value &&
      other.ageSeconds == ageSeconds;

  @override
  int get hashCode => Object.hash(value, ageSeconds);

  @override
  String toString() => 'FuzzyReading($value, ${ageSeconds}s)';
}

/// Everything the fuzzy engine may consider for one sample.
///
/// Every field is optional: a GPS-only drive has no RPM, a car without a
/// grade fix has no grade. An absent field is **stated** as missing in the
/// evidence and lowers confidence — it never becomes a zero.
@immutable
class FuzzyConsumptionInput {
  const FuzzyConsumptionInput({
    this.physicsFuelRateLPerHour,
    this.physicsBasis,
    this.nativeFuelRateLPerHour,
    this.nativeSource,
    this.speedKmh,
    this.accelMps2,
    this.gradePercent,
    this.yawRateRadPerS,
    this.stopsPerMinute,
    this.rpm,
    this.engineLoadPercent,
    this.throttlePercent,
    this.coolantTempC,
    this.oilTempC,
    this.vehicleMassKg,
  });

  /// The physics estimate (L/h) the rules refine. Without it — or without
  /// its [physicsBasis] — there is nothing to estimate from, and the
  /// engine says so instead of inventing a figure.
  ///
  /// Pass it **before** any pump gain: the gain is applied exactly once,
  /// downstream, by the consumer that stamps the `ConsumptionEstimate`
  /// (#4233).
  final FuzzyReading? physicsFuelRateLPerHour;
  final FuzzyPhysicsBasis? physicsBasis;

  /// A native ECU fuel rate (L/h). When valid and fresh it is passed
  /// through untouched as the sample's **measured** figure.
  final FuzzyReading? nativeFuelRateLPerHour;
  final NativeFuelRateSource? nativeSource;

  /// Ground speed, km/h.
  final FuzzyReading? speedKmh;

  /// Low-passed longitudinal acceleration, m/s² (negative = slowing).
  final FuzzyReading? accelMps2;

  /// Road grade in percent — pass it **only when confident** (a
  /// `RoadGrade` with `confident == false` is a missing grade, not a flat
  /// road).
  final FuzzyReading? gradePercent;

  /// Signed yaw rate, rad/s. Only the magnitude is used.
  final FuzzyReading? yawRateRadPerS;

  /// Stops in the trailing minute.
  final FuzzyReading? stopsPerMinute;

  /// Engine speed, rev/min.
  final FuzzyReading? rpm;

  /// Engine / absolute load, percent.
  final FuzzyReading? engineLoadPercent;

  /// Throttle position, percent.
  final FuzzyReading? throttlePercent;

  /// Coolant temperature, °C.
  final FuzzyReading? coolantTempC;

  /// Oil temperature, °C — only consulted when coolant is unavailable.
  final FuzzyReading? oilTempC;

  /// Vehicle mass, kg (a static parameter: its age is ignored).
  final FuzzyReading? vehicleMassKg;

  /// The reading for [variable], or null when the caller supplied none.
  FuzzyReading? readingFor(FuzzyVariable variable) => switch (variable) {
        FuzzyVariable.speed => speedKmh,
        FuzzyVariable.accel => accelMps2,
        FuzzyVariable.grade => gradePercent,
        FuzzyVariable.curvature => yawRateRadPerS,
        FuzzyVariable.stops => stopsPerMinute,
        FuzzyVariable.rpm => rpm,
        FuzzyVariable.load => engineLoadPercent,
        FuzzyVariable.throttle => throttlePercent,
        FuzzyVariable.coolantTemp => coolantTempC,
        FuzzyVariable.oilTemp => oilTempC,
        FuzzyVariable.vehicleMass => vehicleMassKg,
      };
}

/// The status of one input after validation.
enum FuzzyInputStatus {
  /// Present, plausible and within its freshness horizon.
  fresh,

  /// Present and plausible, but older than its horizon — not used.
  stale,

  /// Not supplied.
  missing,

  /// Non-finite, outside the physically plausible domain, or carrying a
  /// negative / non-finite age — rejected, never clamped into a value
  /// that would look real.
  invalid,
}

/// Validation of one reading against a domain and a freshness horizon.
///
/// Shared by the context variables and the two fuel-rate inputs so every
/// input is judged by the same rule.
FuzzyInputStatus classifyReading(
  FuzzyReading? reading, {
  required double min,
  required double max,
  required double staleAfterSeconds,
}) {
  if (reading == null) return FuzzyInputStatus.missing;
  final v = reading.value;
  final age = reading.ageSeconds;
  if (!v.isFinite || v < min || v > max) return FuzzyInputStatus.invalid;
  if (age.isNaN || age < 0) return FuzzyInputStatus.invalid;
  if (age > staleAfterSeconds) return FuzzyInputStatus.stale;
  return FuzzyInputStatus.fresh;
}

/// Freshness in `[0, 1]`: 1 when read this tick, falling linearly to 0 at
/// the horizon. A static parameter (infinite horizon) is always 1.
double freshnessOf(FuzzyReading reading, double staleAfterSeconds) {
  if (staleAfterSeconds.isInfinite) return 1;
  final f = 1 - reading.ageSeconds / staleAfterSeconds;
  return f.clamp(0.0, 1.0);
}
