// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:meta/meta.dart';

import '../../../core/domain/data_value.dart';
import 'fuel_mixture_model.dart';
import 'signal_plausibility.dart';
import 'vehicle_signal.dart';

export 'signal_plausibility.dart' show SignalPlausibility;

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

/// [reading] marked against the band its consumer clamps to (#4159):
/// commanded φ and baro always, measured wideband φ by the resolved fuel
/// ([isDiesel] picks the diesel band). Other signals, and readings with
/// no value, are returned unchanged.
SignalReading markPlausibility(SignalReading reading, {required bool isDiesel}) {
  final v = reading.valueOrNull;
  if (v == null) return reading;
  return switch (reading.signal) {
    VehicleSignal.commandedPhi => reading.marked(classifyCommandedPhi(v)),
    VehicleSignal.baroPressure => reading.marked(classifyBaroKpa(v)),
    VehicleSignal.widebandPhi =>
      reading.marked(classifyMeasuredPhi(v, isDiesel: isDiesel)),
    _ => reading,
  };
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
