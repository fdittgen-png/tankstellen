// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../domain/vehicle_signal.dart';
import 'elm327_commands.dart';
import 'elm327_precision_pids.dart';

/// How a signal's support is decided before it is polled (#3532).
enum SignalGate {
  /// Resolved support set AND the bitmap claims the PID. For the rare
  /// modern PIDs a probe-less clone must never blind-subscribe.
  strict,

  /// Don't-reject-blind: allowed unless runtime probation parked it.
  optimistic,
}

/// The adapter's PID table for [VehicleSignal] (#4159) — the one place
/// that knows which Mode 01 PID carries which signal.
///
/// Command strings are the existing [Elm327Commands] /
/// [Elm327PrecisionPids] constants, so there is still exactly one
/// spelling of each request on the wire.
abstract final class Obd2SignalPids {
  /// The Mode 01 PID carrying [signal]. For [VehicleSignal.widebandPhi]
  /// this is sensor 1 of the voltage family; the full family is
  /// [Elm327PrecisionPids.allWidebandPids].
  static int pidOf(VehicleSignal signal) => switch (signal) {
        VehicleSignal.engineRpm => 0x0C,
        VehicleSignal.vehicleSpeed => 0x0D,
        VehicleSignal.throttle => 0x11,
        VehicleSignal.pedalD => 0x49,
        VehicleSignal.pedalE => 0x4A,
        VehicleSignal.pedalF => 0x4B,
        VehicleSignal.fuelRate => 0x5E,
        VehicleSignal.maf => 0x10,
        VehicleSignal.mafDual => 0x66,
        VehicleSignal.fuelMassRate => 0x9D,
        VehicleSignal.cylinderFuelRate => 0xA2,
        VehicleSignal.manifoldPressure => 0x0B,
        VehicleSignal.commandedPhi => 0x44,
        VehicleSignal.engineLoad => 0x04,
        VehicleSignal.absoluteLoad => 0x43,
        VehicleSignal.widebandPhi => 0x24,
        VehicleSignal.stftBank1 => 0x06,
        VehicleSignal.ltftBank1 => 0x07,
        VehicleSignal.stftBank2 => 0x08,
        VehicleSignal.ltftBank2 => 0x09,
        VehicleSignal.intakeAirTemp => 0x0F,
        VehicleSignal.timingAdvance => 0x0E,
        VehicleSignal.baroPressure => 0x33,
        VehicleSignal.ethanolPercent => 0x52,
        VehicleSignal.coolantTemp => 0x05,
        VehicleSignal.fuelTankLevel => 0x2F,
        VehicleSignal.oilTemp => 0x5C,
        VehicleSignal.ambientAirTemp => 0x46,
      };

  /// The Mode 01 request for [signal] (for [VehicleSignal.widebandPhi],
  /// sensor 1's).
  static String commandOf(VehicleSignal signal) => switch (signal) {
        VehicleSignal.engineRpm => Elm327Commands.engineRpmCommand,
        VehicleSignal.vehicleSpeed => Elm327Commands.vehicleSpeedCommand,
        VehicleSignal.throttle => Elm327Commands.throttlePositionCommand,
        VehicleSignal.pedalD => Elm327Commands.acceleratorPedalDCommand,
        VehicleSignal.pedalE => Elm327Commands.acceleratorPedalECommand,
        VehicleSignal.pedalF => Elm327Commands.acceleratorPedalFCommand,
        VehicleSignal.fuelRate => Elm327Commands.engineFuelRateCommand,
        VehicleSignal.maf => Elm327Commands.mafCommand,
        VehicleSignal.mafDual => Elm327PrecisionPids.mafSensorCommand,
        VehicleSignal.fuelMassRate =>
          Elm327PrecisionPids.engineFuelRateGramsCommand,
        VehicleSignal.cylinderFuelRate =>
          Elm327PrecisionPids.cylinderFuelRateCommand,
        VehicleSignal.manifoldPressure =>
          Elm327Commands.intakeManifoldPressureCommand,
        VehicleSignal.commandedPhi =>
          Elm327Commands.commandedEquivalenceRatioCommand,
        VehicleSignal.engineLoad => Elm327Commands.engineLoadCommand,
        VehicleSignal.absoluteLoad => Elm327Commands.absoluteLoadCommand,
        VehicleSignal.widebandPhi => Elm327PrecisionPids.widebandCommand(
            Elm327PrecisionPids.primaryWidebandPids.first),
        VehicleSignal.stftBank1 => Elm327Commands.shortTermFuelTrimCommand,
        VehicleSignal.ltftBank1 => Elm327Commands.longTermFuelTrimCommand,
        VehicleSignal.stftBank2 =>
          Elm327Commands.shortTermFuelTrimBank2Command,
        VehicleSignal.ltftBank2 => Elm327Commands.longTermFuelTrimBank2Command,
        VehicleSignal.intakeAirTemp => Elm327Commands.intakeAirTempCommand,
        VehicleSignal.timingAdvance => Elm327Commands.timingAdvanceCommand,
        VehicleSignal.baroPressure => Elm327Commands.baroPressureCommand,
        VehicleSignal.ethanolPercent =>
          Elm327PrecisionPids.ethanolPercentCommand,
        VehicleSignal.coolantTemp => Elm327Commands.coolantTempCommand,
        VehicleSignal.fuelTankLevel => Elm327Commands.fuelTankLevelCommand,
        VehicleSignal.oilTemp => Elm327Commands.engineOilTempCommand,
        VehicleSignal.ambientAirTemp => Elm327Commands.ambientAirTempCommand,
      };

  /// Which support gate [signal] passes before it is polled — strict for
  /// the Epic #3416 precision families, optimistic for everything else
  /// (the split `Obd2Service.isPidKnownSupported` documents). Listed
  /// exhaustively so a new signal has to choose.
  static SignalGate gateOf(VehicleSignal signal) => switch (signal) {
        VehicleSignal.mafDual ||
        VehicleSignal.fuelMassRate ||
        VehicleSignal.cylinderFuelRate ||
        VehicleSignal.ethanolPercent ||
        VehicleSignal.widebandPhi =>
          SignalGate.strict,
        VehicleSignal.engineRpm ||
        VehicleSignal.vehicleSpeed ||
        VehicleSignal.throttle ||
        VehicleSignal.pedalD ||
        VehicleSignal.pedalE ||
        VehicleSignal.pedalF ||
        VehicleSignal.fuelRate ||
        VehicleSignal.maf ||
        VehicleSignal.manifoldPressure ||
        VehicleSignal.commandedPhi ||
        VehicleSignal.engineLoad ||
        VehicleSignal.absoluteLoad ||
        VehicleSignal.stftBank1 ||
        VehicleSignal.ltftBank1 ||
        VehicleSignal.stftBank2 ||
        VehicleSignal.ltftBank2 ||
        VehicleSignal.intakeAirTemp ||
        VehicleSignal.timingAdvance ||
        VehicleSignal.baroPressure ||
        VehicleSignal.coolantTemp ||
        VehicleSignal.fuelTankLevel ||
        VehicleSignal.oilTemp ||
        VehicleSignal.ambientAirTemp =>
          SignalGate.optimistic,
      };
}
