// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:meta/meta.dart';

import '../../../core/domain/data_value.dart';
import 'fuel_mixture_model.dart';
import 'vehicle_signal.dart';

/// Whether a reading's value sits inside the band its consumer trusts
/// (#4159).
///
/// A band check MARKS a value; it never replaces it. The fuel math keeps
/// its own clamps, but a clamped φ or baro reading is an adapter or sensor
/// fault worth seeing, so the unclamped value travels with this mark.
enum SignalPlausibility {
  /// No band is defined for this signal (most signals).
  notChecked,

  /// Inside the band.
  plausible,

  /// Outside the band — the consumer's clamp would have hidden it.
  implausible,
}

/// One vehicle signal's value with its unit, provenance and freshness
/// (#4159): the normalized form every consumer above the adapter can read
/// without knowing which PID carried it.
///
/// * [value] is a [DataValue]: `Measured(at:)` while inside the signal's
///   freshness window, `Stale(age:)` past it (the value is kept — the
///   hold-last getters still return it), `Unknown(notMeasuredYet)` before
///   anything landed; a DERIVED figure (fuel rate from air mass) is
///   `Estimated(basis: derived)`.
/// * [unit] comes from the signal.
/// * [plausibility] says whether the value is inside its trusted band.
@immutable
final class SignalReading {
  const SignalReading({
    required this.signal,
    required this.value,
    this.plausibility = SignalPlausibility.notChecked,
  });

  final VehicleSignal signal;
  final DataValue<double> value;
  final SignalPlausibility plausibility;

  /// The unit [value] is expressed in.
  SignalUnit get unit => signal.unit;

  /// The value of any provenance (a stale one included), else null.
  double? get valueOrNull => value.valueOrNull;

  /// This reading with [plausibility] replaced.
  SignalReading marked(SignalPlausibility plausibility) => SignalReading(
        signal: signal,
        value: value,
        plausibility: plausibility,
      );

  @override
  bool operator ==(Object other) =>
      other is SignalReading &&
      other.signal == signal &&
      other.value == value &&
      other.plausibility == plausibility;

  @override
  int get hashCode => Object.hash(signal, value, plausibility);

  @override
  String toString() => 'SignalReading(${signal.name}, $value, '
      '${plausibility.name})';
}

/// A derived fuel-rate figure as a [VehicleSignal.fuelRate] reading
/// (#4159), so a MAP-derived rate and an ECU-reported one are never
/// indistinguishable downstream: the ECU's own figures (fuel mass rate,
/// cylinder fuel rate, fuel rate — `kMeasuredFuelSourceTags`) are
/// `Measured(at)`; air-mass derivations (dual MAF, MAF, speed-density) are
/// `Estimated(basis: derived)`; no figure is `Unknown(notMeasuredYet)`.
SignalReading fuelRateReadingOf(
  double? litresPerHour,
  FuelRateSourceTag? source, {
  DateTime? at,
}) {
  const unknown = Unknown<double>(reason: DataUnknownReason.notMeasuredYet);
  final DataValue<double> value = litresPerHour == null
      ? unknown
      : switch (source) {
          FuelRateSourceTag.pid9D ||
          FuelRateSourceTag.pidA2 ||
          FuelRateSourceTag.pid5E =>
            DataValue.measured(litresPerHour, at: at),
          FuelRateSourceTag.maf66 ||
          FuelRateSourceTag.maf ||
          FuelRateSourceTag.speedDensity =>
            DataValue.estimated(litresPerHour, basis: DataBasis.derived),
          FuelRateSourceTag.none || null => unknown,
        };
  return SignalReading(signal: VehicleSignal.fuelRate, value: value);
}
