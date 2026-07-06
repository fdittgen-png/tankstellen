// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'trip_recorder.dart';

/// Why a trip's OBD2 engine-data coverage is what it is (#3499, epic #3498).
///
/// The field export that motivated this showed a `gpsPlusObd2` trip whose
/// `obd2Features` were null — the OBD2 link contributed ZERO engine PIDs,
/// the fuel chart silently fell back to the "~ estimated" GPS-physics
/// series, and nothing on screen said why. This classification names the
/// gap so the trip detail can explain it and the export can carry it.
enum Obd2EngineCoverageReason {
  /// Engine PIDs present on (nearly) every sample — the healthy trip.
  full,

  /// Engine data present but patchy across the whole trip (a flaky link /
  /// slow PID round-trips), with no clean cut-off point.
  partial,

  /// Engine data flowed, then stopped well before the trip ended — the
  /// adapter-dropped-mid-trip signature.
  droppedMidTrip,

  /// Not a single sample carried an engine PID: the adapter session never
  /// delivered engine data (drop at start, silent ECU, no supported PIDs).
  noEngineData,
}

/// Per-trip OBD2 engine-sample coverage (#3499): what share of the recorded
/// samples actually carried an engine signal, and the coarse reason.
///
/// Pure + representation-agnostic: callers map their own sample type onto a
/// per-sample "has an engine PID" flag (the same predicate
/// `Obd2TripFeatures.fromSamples` uses — rpm / engine load / throttle /
/// MEASURED fuel rate; a GPS-physics *estimated* rate does NOT count).
class Obd2EngineCoverage {
  const Obd2EngineCoverage({
    required this.engineSamples,
    required this.totalSamples,
    required this.share,
    required this.lastEngineAtShare,
    required this.reason,
  });

  /// Samples that carried at least one engine PID.
  final int engineSamples;

  /// All samples considered.
  final int totalSamples;

  /// `engineSamples / totalSamples`, 0..1.
  final double share;

  /// Position (0..1 of the sample index range) of the LAST engine-bearing
  /// sample — the drop point when the link died mid-trip. 0 when no engine
  /// sample exists.
  final double lastEngineAtShare;

  final Obd2EngineCoverageReason reason;

  /// Share of samples above which the trip counts as fully covered.
  static const double fullShareFloor = 0.9;

  /// [lastEngineAtShare] below which a sub-full trip reads as a mid-trip
  /// drop (engine data ended in the first ~85% of the trip) rather than as
  /// generally-patchy coverage.
  static const double droppedCutoff = 0.85;

  /// Classify a trip from per-sample engine flags (index order = time
  /// order). Returns null for an empty trip — nothing to classify.
  static Obd2EngineCoverage? fromFlags(List<bool> hasEngineBySample) {
    final n = hasEngineBySample.length;
    if (n == 0) return null;
    var engine = 0;
    var lastIdx = -1;
    for (var i = 0; i < n; i++) {
      if (hasEngineBySample[i]) {
        engine++;
        lastIdx = i;
      }
    }
    final share = engine / n;
    final lastAt = lastIdx < 0 ? 0.0 : (n == 1 ? 1.0 : lastIdx / (n - 1));
    final Obd2EngineCoverageReason reason;
    if (engine == 0) {
      reason = Obd2EngineCoverageReason.noEngineData;
    } else if (share >= fullShareFloor) {
      reason = Obd2EngineCoverageReason.full;
    } else if (lastAt < droppedCutoff) {
      reason = Obd2EngineCoverageReason.droppedMidTrip;
    } else {
      reason = Obd2EngineCoverageReason.partial;
    }
    return Obd2EngineCoverage(
      engineSamples: engine,
      totalSamples: n,
      share: share,
      lastEngineAtShare: lastAt,
      reason: reason,
    );
  }

  /// Convenience over the domain [TripSample] shape — the SAME engine
  /// predicate `Obd2TripFeatures.fromSamples` uses (rpm / engine load /
  /// throttle / MEASURED fuel rate).
  static Obd2EngineCoverage? fromTripSamples(List<TripSample> samples) =>
      fromFlags([
        for (final s in samples)
          s.rpm != null ||
              s.engineLoadPercent != null ||
              s.throttlePercent != null ||
              s.fuelRateLPerHour != null,
      ]);

  /// Export shape for the drivingAnalysis trace (#3499, schema v4).
  Map<String, Object?> toJson() => {
        'engineSamples': engineSamples,
        'totalSamples': totalSamples,
        'engineSampleShare': double.parse(share.toStringAsFixed(3)),
        'lastEngineAtShare': double.parse(lastEngineAtShare.toStringAsFixed(3)),
        'reason': reason.name,
      };
}
