// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'pump_gain_entry.dart';
import 'vehicle_profile.dart';

/// Where a resolved pump gain came from (#3918).
enum PumpGainSource {
  /// `VehicleProfile.pumpGainByFuel[fuelKey]` — a grade-specific gain.
  perFuel,

  /// The scalar `VehicleProfile.pumpGain` (single-fuel vehicles, or a
  /// grade without its own entry yet).
  vehicle,

  /// Nothing learned yet — gain 1.0, the estimator's raw output.
  uncalibrated,
}

/// The gain a fuel-rate reader applies, with its provenance so the UI
/// can say WHICH calibration a figure carries (#3918 / #3919).
@immutable
class PumpGainResolution {
  const PumpGainResolution({
    required this.gain,
    required this.source,
    required this.samples,
    this.fuelKey,
    this.updatedAt,
  });

  static const PumpGainResolution none = PumpGainResolution(
    gain: 1.0,
    source: PumpGainSource.uncalibrated,
    samples: 0,
  );

  final double gain;
  final PumpGainSource source;

  /// Fill-ups behind the resolved gain.
  final int samples;

  /// The normalised fuel key the per-fuel entry was found under; null for
  /// the scalar / uncalibrated sources.
  final String? fuelKey;
  final DateTime? updatedAt;

  /// Signed distance from 1.0 in percent (`+8` = the estimates were
  /// raised, `-22` = lowered).
  int get correctionPercent => ((gain - 1.0) * 100).round();

  bool get isCalibrated => source != PumpGainSource.uncalibrated;
}

/// Normalise a free-text fuel key the way the per-fuel map is keyed
/// (`FuelType.apiValue` — lowercase, trimmed). Null / blank → null.
String? normalizePumpGainFuelKey(String? key) {
  final k = key?.trim().toLowerCase();
  return (k == null || k.isEmpty) ? null : k;
}

/// The fuel key a reader looks the per-fuel gain up under (#3918):
/// the tank's dominant grade per the fill history first (the most
/// precise — a flex-fuel tank holds what was last pumped, whatever the
/// ECU's coarse 0x51 family says), then the ECU session key, then the
/// profile's default fuel.
String? pumpGainFuelKeyFor(VehicleProfile? vehicle, {String? sessionFuelKey}) =>
    normalizePumpGainFuelKey(vehicle?.tankFuelKey) ??
    normalizePumpGainFuelKey(sessionFuelKey) ??
    normalizePumpGainFuelKey(vehicle?.preferredFuelType);

/// Resolve the gain to apply (#3918): `pumpGainByFuel[fuelKey]` →
/// scalar `pumpGain` → 1.0. The per-fuel entry only wins once it has
/// actually been learned (`samples > 0`); an untouched default entry
/// must not shadow a learned scalar.
PumpGainResolution resolvePumpGain(VehicleProfile? vehicle, {String? fuelKey}) {
  if (vehicle == null) return PumpGainResolution.none;
  final key = normalizePumpGainFuelKey(fuelKey);
  if (key != null) {
    final PumpGainEntry? entry = vehicle.pumpGainByFuel[key];
    if (entry != null && entry.samples > 0) {
      return PumpGainResolution(
        gain: entry.gain,
        source: PumpGainSource.perFuel,
        samples: entry.samples,
        fuelKey: key,
        updatedAt: entry.updatedAt,
      );
    }
  }
  if (vehicle.pumpGainSamples > 0 || vehicle.pumpGain != 1.0) {
    return PumpGainResolution(
      gain: vehicle.pumpGain,
      source: PumpGainSource.vehicle,
      samples: vehicle.pumpGainSamples,
      updatedAt: vehicle.pumpGainUpdatedAt,
    );
  }
  return PumpGainResolution.none;
}
