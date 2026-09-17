// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/domain/vehicle_profile.dart';
import '../../trips/api.dart' show FuzzyConsumptionInput, FuzzyReading;
import 'fuel_rate_estimator.dart' show kDefaultVolumetricEfficiency;
import 'signal_latch_store.dart';
import 'vehicle_signal.dart';

/// The context an OBD2 estimated fuel rate hands the fuzzy stage (#4233,
/// ADR 0024), read from the live latches with their **real ages**.
///
/// The latches are hold-last, so a value can be seconds old by the time a
/// MAF or speed-density rate is derived. #4159's [SignalLatchStore] records
/// when each one landed, so the engine is told how old every reading is and
/// judges it against its own freshness horizon. It is not handed a stale
/// value as if it were current (ADR 0023 §4).
///
/// What an OBD2 tick cannot supply stays missing, stated rather than zeroed:
/// longitudinal acceleration, grade, yaw rate and the stop count. The curb
/// weight is a static parameter.
///
/// With the neutral rule base none of this moves a figure. It exists so a
/// fitted rule base sees honest inputs on its first day.
FuzzyConsumptionInput obd2LiveFuzzyContext(
  SignalLatchStore signals, {
  required DateTime now,
  required VehicleProfile? vehicle,
}) {
  FuzzyReading? read(VehicleSignal signal) {
    final value = signals.latest(signal);
    final at = signals.arrivedAt(signal);
    if (value == null || at == null) return null;
    return FuzzyReading(value,
        ageSeconds: now.difference(at).inMicroseconds / 1e6);
  }

  return FuzzyConsumptionInput(
    speedKmh: read(VehicleSignal.vehicleSpeed),
    rpm: read(VehicleSignal.engineRpm),
    engineLoadPercent: read(VehicleSignal.engineLoad),
    throttlePercent: read(VehicleSignal.throttle),
    coolantTempC: read(VehicleSignal.coolantTemp),
    oilTempC: read(VehicleSignal.oilTemp),
    vehicleMassKg: fuzzyVehicleMassOf(vehicle),
  );
}

/// The vehicle's curb weight as a static fuzzy reading, or null when the
/// profile has none.
FuzzyReading? fuzzyVehicleMassOf(VehicleProfile? vehicle) {
  final kg = vehicle?.curbWeightKg;
  return kg == null ? null : FuzzyReading(kg.toDouble());
}

/// The user profile's η_v when it should beat the engine-tech default, or
/// null when the default should apply (#1422 phase 1). Read by the live
/// snapshot, the only speed-density implementation since #4315.
///
/// * No profile → null.
/// * No reference catalog row to derive a better default from → the stored
///   value, even the legacy 0.85.
/// * A learned value (`volumetricEfficiencySamples > 0`) or a non-default
///   one → the stored value.
/// * The cold-start 0.85 with nothing learned → null, so e.g. a Dacia dCi
///   gets the helper's 0.95 from day one.
double? profileVolumetricEfficiency(
  VehicleProfile? vehicle, {
  required bool hasReferenceVehicle,
}) {
  if (vehicle == null) return null;
  if (!hasReferenceVehicle) return vehicle.volumetricEfficiency;
  if (vehicle.volumetricEfficiencySamples > 0) {
    return vehicle.volumetricEfficiency;
  }
  if (vehicle.volumetricEfficiency != kDefaultVolumetricEfficiency) {
    return vehicle.volumetricEfficiency;
  }
  return null;
}
