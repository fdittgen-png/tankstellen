// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The vehicle signals the recording path consumes, named by what they
/// MEAN rather than by the OBD-II PID that carries them (#4159).
///
/// A PID number is an adapter detail: `0x0C` means nothing to a fuel-rate
/// derivation, `engineRpm` does. The PID table lives in the adapter
/// (`data/protocol/obd2_signal_pids.dart`); everything above it asks for a
/// signal by name, so the next signal costs one enum value and one table
/// row instead of a literal in every consumer.
///
/// Deliberately not the place for cadence: how often a signal is polled
/// (hz, tier, priority) is a recording decision and stays at the call
/// site that subscribes it.
library;

/// The physical unit a [VehicleSignal]'s value is expressed in, after the
/// adapter decoded it.
enum SignalUnit {
  /// Revolutions per minute.
  rpm,

  /// Kilometres per hour.
  kmh,

  /// Percent. Absolute load exceeds 100 on boosted engines; fuel trims
  /// are signed.
  percent,

  /// Litres per hour.
  litresPerHour,

  /// Grams per second.
  gramsPerSecond,

  /// Milligrams per cylinder per intake stroke.
  mgPerStroke,

  /// Kilopascals, absolute.
  kPa,

  /// Dimensionless fuel–air equivalence ratio φ (1.0 = stoichiometric,
  /// above 1 rich).
  equivalenceRatio,

  /// Degrees Celsius.
  celsius,

  /// Ignition timing, crank-angle degrees before top dead centre.
  degreesBtdc,
}

/// One vehicle signal the recording path reads, with its [unit].
enum VehicleSignal {
  engineRpm(SignalUnit.rpm),
  vehicleSpeed(SignalUnit.kmh),
  throttle(SignalUnit.percent),

  /// Accelerator-pedal channels D / E / F — three views of one pedal.
  pedalD(SignalUnit.percent),
  pedalE(SignalUnit.percent),
  pedalF(SignalUnit.percent),

  /// ECU-reported fuel VOLUME flow, already post-trim.
  fuelRate(SignalUnit.litresPerHour),

  /// Mass air flow from the legacy single sensor.
  maf(SignalUnit.gramsPerSecond),

  /// Mass air flow, total of the dual-sensor channel.
  mafDual(SignalUnit.gramsPerSecond),

  /// ECU-reported engine fuel MASS flow.
  fuelMassRate(SignalUnit.gramsPerSecond),

  /// ECU-reported fuel mass per cylinder per intake stroke.
  cylinderFuelRate(SignalUnit.mgPerStroke),

  manifoldPressure(SignalUnit.kPa),
  commandedPhi(SignalUnit.equivalenceRatio),
  engineLoad(SignalUnit.percent),
  absoluteLoad(SignalUnit.percent),

  /// Measured wideband φ — one signal that up to sixteen sensors carry.
  widebandPhi(SignalUnit.equivalenceRatio),

  stftBank1(SignalUnit.percent),
  ltftBank1(SignalUnit.percent),
  stftBank2(SignalUnit.percent),
  ltftBank2(SignalUnit.percent),
  intakeAirTemp(SignalUnit.celsius),
  timingAdvance(SignalUnit.degreesBtdc),
  baroPressure(SignalUnit.kPa),
  ethanolPercent(SignalUnit.percent),
  coolantTemp(SignalUnit.celsius),
  fuelTankLevel(SignalUnit.percent),
  oilTemp(SignalUnit.celsius),
  ambientAirTemp(SignalUnit.celsius);

  const VehicleSignal(this.unit);

  /// The unit the decoded value is expressed in.
  final SignalUnit unit;
}
