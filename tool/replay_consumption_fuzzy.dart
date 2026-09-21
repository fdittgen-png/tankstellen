// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

// The fuzzy engine's half of the consumption replay (#4232, over the #4231
// harness). Replays one trace's samples through `FuzzyConsumptionEngine`
// and integrates the per-sample figure into litres, so the report can put
// the fuzzy path beside the shipped figure against the same pump truth.
//
// Imports the engine directly: unlike most of the app graph it is pure Dart
// (dart:math + package:meta + two core/domain contracts), which is exactly
// what lets a `tool/` script run it without Flutter. The structural test
// `fuzzy_engine_structure_test.dart` pins that import closure.
//
// What the samples can and cannot supply is stated rather than papered
// over: `sampleToJson` carries speed, RPM, load, throttle, temperatures and
// the per-tick fuel rate with its provenance — but no grade, yaw rate,
// stop count or vehicle mass. Those inputs replay as *missing*, so their
// rules stay closed, their degraded substitutes open, and confidence drops.

import 'package:tankstellen/features/trips/domain/fuzzy_consumption/fuzzy_consumption_engine.dart';

/// Longest inter-sample interval integrated as driving rather than a gap.
/// Same value as `ReplayGates.maxGapSeconds` (asserted by the test).
const double kFuzzyReplayMaxGapSeconds = 60;

/// The native source a per-tick `'fs'` stamp names, or null.
NativeFuelRateSource? nativeSourceForTag(String? tag) => switch (tag) {
      'pid9D' => NativeFuelRateSource.pid9D,
      'pidA2' => NativeFuelRateSource.pidA2,
      'pid5E' => NativeFuelRateSource.pid5E,
      _ => null,
    };

/// The physics basis a per-tick `'fs'` stamp names, or null.
FuzzyPhysicsBasis? physicsBasisForTag(String? tag) => switch (tag) {
      'maf66' || 'maf' => FuzzyPhysicsBasis.maf,
      'speedDensity' => FuzzyPhysicsBasis.speedDensity,
      _ => null,
    };

FuzzyReading? _reading(Map<String, dynamic> sample, String key) {
  final v = sample[key];
  return v is num ? FuzzyReading(v.toDouble()) : null;
}

/// The engine input for one `sampleToJson` map. [previous] and [dtSeconds]
/// derive acceleration; the first sample has none.
FuzzyConsumptionInput fuzzyInputForSample(
  Map<String, dynamic> sample, {
  Map<String, dynamic>? previous,
  double? dtSeconds,
}) {
  final tag = sample['fs'] is String ? sample['fs'] as String : null;
  final rate = _reading(sample, 'f');
  final native = nativeSourceForTag(tag);
  final airMass = physicsBasisForTag(tag);
  final gpsEstimate = _reading(sample, 'fe');

  FuzzyReading? accel;
  final s = sample['s'];
  final ps = previous?['s'];
  if (s is num && ps is num && dtSeconds != null && dtSeconds > 0) {
    accel = FuzzyReading((s - ps) / 3.6 / dtSeconds);
  }

  // The per-tick rate 'f' is native or air-mass physics by its stamp; the
  // GPS-physics estimate 'fe' is the physics input when no air mass is.
  final useAirMass = airMass != null && rate != null;
  return FuzzyConsumptionInput(
    nativeFuelRateLPerHour: native != null ? rate : null,
    nativeSource: rate != null ? native : null,
    physicsFuelRateLPerHour: useAirMass ? rate : gpsEstimate,
    physicsBasis: useAirMass
        ? airMass
        : (gpsEstimate != null ? FuzzyPhysicsBasis.gpsRoadLoad : null),
    speedKmh: _reading(sample, 's'),
    accelMps2: accel,
    rpm: _reading(sample, 'r'),
    engineLoadPercent: _reading(sample, 'el') ?? _reading(sample, 'aL'),
    throttlePercent: _reading(sample, 'th'),
    coolantTempC: _reading(sample, 'ct'),
    oilTempC: _reading(sample, 'ot'),
  );
}

/// One trace replayed through the engine.
class FuzzyReplayOutcome {
  FuzzyReplayOutcome({
    required this.litres,
    required this.totalSeconds,
    required this.uncoveredSeconds,
    required this.kinds,
  });

  /// Integrated litres over the covered intervals.
  final double litres;
  final double totalSeconds;

  /// Seconds with no figure (no usable input) or inside a gap.
  final double uncoveredSeconds;

  /// How many intervals each output kind produced.
  final Map<FuzzyOutputKind, int> kinds;

  /// Why the integrated litres cannot be compared to truth, or null.
  ///
  /// Any uncovered time disqualifies the trace: integrating only the
  /// covered part would under-count by exactly the fuel nobody estimated,
  /// and scaling it up would invent that fuel.
  String? get incompleteReason {
    if (totalSeconds <= 0) return 'no integrable interval';
    if (uncoveredSeconds <= 0) return null;
    final pct = uncoveredSeconds / totalSeconds * 100;
    return '${pct.toStringAsFixed(1)} % of the time has no fuzzy figure';
  }
}

/// Replay [samples] (any order) through [engine].
FuzzyReplayOutcome replayFuzzy(
  List<Map<String, dynamic>> samples, {
  FuzzyConsumptionEngine engine = const FuzzyConsumptionEngine(),
}) {
  final sorted = samples.where((s) => s['t'] is num).toList()
    ..sort((a, b) => (a['t'] as num).compareTo(b['t'] as num));
  var litres = 0.0;
  var total = 0.0;
  var uncovered = 0.0;
  final kinds = {for (final k in FuzzyOutputKind.values) k: 0};
  for (var i = 1; i < sorted.length; i++) {
    final dt =
        ((sorted[i]['t'] as num) - (sorted[i - 1]['t'] as num)) / 1000.0;
    if (dt <= 0) continue;
    total += dt;
    if (dt > kFuzzyReplayMaxGapSeconds) {
      uncovered += dt;
      continue;
    }
    final result = engine.infer(fuzzyInputForSample(sorted[i],
        previous: sorted[i - 1], dtSeconds: dt));
    kinds[result.kind] = kinds[result.kind]! + 1;
    final rate = result.fuelRateLPerHour;
    if (rate == null) {
      uncovered += dt;
    } else {
      litres += rate * dt / 3600.0;
    }
  }
  return FuzzyReplayOutcome(
    litres: litres,
    totalSeconds: total,
    uncoveredSeconds: uncovered,
    kinds: kinds,
  );
}
