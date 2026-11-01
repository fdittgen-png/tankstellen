// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'trip_sample.dart';
import 'obd2_signal_distribution.dart';

/// Evidence behind mixture lessons and the speed-density fuel estimate.
/// No inference from a missing value to an unsupported PID or broken part.
Map<String, Object?> obd2HealthFeatures(List<TripSample> samples) {
  Map<String, dynamic> dist(double? Function(TripSample) pick) =>
      Obd2SignalDistribution.from(
        samples.map(pick).whereType<double>().toList(),
        totalSamples: samples.length,
      ).toJson();
  final warmPairs = samples
      .where(
        (s) =>
            (s.rpm ?? 0) > 0 &&
            (s.coolantTempC ?? 0) >= 70 &&
            s.stft != null &&
            s.ltft != null,
      )
      .toList();
  Map<String, dynamic> paired(double? Function(TripSample) pick) =>
      Obd2SignalDistribution.from(
        warmPairs.map(pick).whereType<double>().toList(),
        totalSamples: samples.length,
      ).toJson();
  return {
    'stftBank1Pct': dist((s) => s.stft),
    'ltftBank1Pct': dist((s) => s.ltft),
    'warmPairedFuelTrim': {
      'coolantMinimumC': 70,
      'engineRunning': true,
      'stftPct': paired((s) => s.stft),
      'ltftPct': paired((s) => s.ltft),
      'totalPct': paired((s) => s.stft! + s.ltft!),
      'context':
          'Paired stored readings; closed-loop status is in vehicleHealth. '
          'Positive correction alone does not identify a failed component.',
    },
    'warmIdleTrimPct': Obd2SignalDistribution.from(
      warmPairs
          .where((s) => s.speedKmh < 3)
          .map((s) => s.stft! + s.ltft!)
          .toList(),
      totalSamples: samples.length,
    ).toJson(),
    'warmMovingTrimPct': Obd2SignalDistribution.from(
      warmPairs
          .where((s) => s.speedKmh >= 3)
          .map((s) => s.stft! + s.ltft!)
          .toList(),
      totalSamples: samples.length,
    ).toJson(),
    'mapKpa': dist((s) => s.mapKpa),
    'mafGramsPerSecond': dist((s) => s.mafGramsPerSecond),
    'intakeAirTempC': dist((s) => s.iatC),
    'ignitionAdvanceDeg': dist((s) => s.timingAdvanceDeg),
    'coolantTempC': dist((s) => s.coolantTempC),
    'oilTempC': dist((s) => s.oilTempC),
    'baroKpa': dist((s) => s.baroKpa),
    'batteryVoltageV': dist((s) => s.batteryVoltageV),
    'commandedEquivalenceRatioPhi': dist((s) => s.lambda),
    'measuredEquivalenceRatioPhi': dist((s) => s.measuredPhi),
    'fuelRateLPerHour': dist((s) => s.fuelRateLPerHour),
    'interpretation':
        'Null means not stored, not zero. Commanded phi is not an '
        'oxygen-sensor measurement. Sparse fuel/trim samples are not time coverage. '
        'Speed-density and MAF fuel rates are estimates, not measured fuel flow.',
  };
}
