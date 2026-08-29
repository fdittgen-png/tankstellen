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
///
/// #3861 (Epic #3855) — coverage is measured INSIDE the engine-running
/// envelope. A recording that started before the engine or kept running
/// after it was switched off has a GPS-only head and/or tail that are not
/// link failures — they are the car being off. Classifying over all
/// samples turned a four-minute parked tail into "connection dropped" and
/// a red list entry (#3835). With per-sample engine-RUNNING flags the
/// envelope is the first..last running sample; the share and the reason
/// are computed there, and the head/tail are reported as what they are.
/// Without running flags (legacy callers) the envelope is the whole trip
/// and every number is exactly what it was before.
class Obd2EngineCoverage {
  const Obd2EngineCoverage({
    required this.engineSamples,
    required this.totalSamples,
    required this.share,
    required this.lastEngineAtShare,
    required this.reason,
    this.envelopeSamples,
    this.headOffSeconds = 0,
    this.tailOffSeconds = 0,
  });

  /// Samples that carried at least one engine PID, inside the envelope.
  final int engineSamples;

  /// All samples considered (the whole trip).
  final int totalSamples;

  /// `engineSamples / envelopeSamples`, 0..1 — the engine-data share while
  /// the engine ran (the whole trip when no envelope is known).
  final double share;

  /// Position (0..1 of the sample index range) of the LAST engine-bearing
  /// sample — the drop point when the link died mid-trip. 0 when no engine
  /// sample exists.
  final double lastEngineAtShare;

  final Obd2EngineCoverageReason reason;

  /// #3861 — samples inside the engine-running envelope; null when no
  /// running flags were supplied (legacy: the envelope is the whole trip).
  final int? envelopeSamples;

  /// #3861 — seconds of recording BEFORE the engine first ran (the
  /// engine-off start). 0 when the engine ran from the first sample or
  /// timestamps were not supplied.
  final double headOffSeconds;

  /// #3861 — seconds of recording AFTER the engine last ran (the
  /// engine-off tail). 0 when the engine ran to the last sample.
  final double tailOffSeconds;

  /// #3861 — true when the trip has a meaningful engine-off head or tail
  /// worth telling the driver about (≥ [kEnvelopeNoteFloorSeconds]).
  bool get hasEngineOffEdges =>
      headOffSeconds >= kEnvelopeNoteFloorSeconds ||
      tailOffSeconds >= kEnvelopeNoteFloorSeconds;

  /// Below this an engine-off head/tail is the normal start/stop shuffle
  /// (key on → engine start takes seconds), not worth a note.
  static const double kEnvelopeNoteFloorSeconds = 45;

  /// Share of samples above which the trip counts as fully covered.
  static const double fullShareFloor = 0.9;

  /// [lastEngineAtShare] below which a sub-full trip reads as a mid-trip
  /// drop (engine data ended in the first ~85% of the trip) rather than as
  /// generally-patchy coverage.
  static const double droppedCutoff = 0.85;

  /// Classify a trip from per-sample engine flags (index order = time
  /// order). Returns null for an empty trip — nothing to classify.
  ///
  /// #3861 — [isRunningBySample] (rpm at/above the running floor) and
  /// [timestamps] are optional: with them the classification runs inside
  /// the engine-running envelope and the head/tail durations are reported;
  /// without them the behaviour is the pre-#3861 whole-trip one.
  static Obd2EngineCoverage? fromFlags(
    List<bool> hasEngineBySample, {
    List<bool>? isRunningBySample,
    List<DateTime>? timestamps,
  }) {
    final n = hasEngineBySample.length;
    if (n == 0) return null;
    assert(isRunningBySample == null || isRunningBySample.length == n,
        'isRunningBySample must be parallel to hasEngineBySample');
    assert(timestamps == null || timestamps.length == n,
        'timestamps must be parallel to hasEngineBySample');

    // The envelope: first..last running sample, else the whole trip.
    var start = 0;
    var end = n - 1;
    if (isRunningBySample != null) {
      var first = -1;
      var last = -1;
      for (var i = 0; i < n; i++) {
        if (!isRunningBySample[i]) continue;
        if (first < 0) first = i;
        last = i;
      }
      if (first >= 0) {
        start = first;
        end = last;
      }
    }
    var engine = 0;
    var lastIdx = -1;
    for (var i = start; i <= end; i++) {
      if (hasEngineBySample[i]) {
        engine++;
        lastIdx = i;
      }
    }
    final span = end - start + 1;
    final share = engine / span;
    final lastAt = lastIdx < 0
        ? 0.0
        : (span == 1 ? 1.0 : (lastIdx - start) / (span - 1));
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
    var head = 0.0;
    var tail = 0.0;
    if (timestamps != null && isRunningBySample != null) {
      head = timestamps[start].difference(timestamps[0]).inMilliseconds / 1e3;
      tail = timestamps[n - 1].difference(timestamps[end]).inMilliseconds / 1e3;
      if (head < 0) head = 0;
      if (tail < 0) tail = 0;
    }
    return Obd2EngineCoverage(
      engineSamples: engine,
      totalSamples: n,
      share: share,
      lastEngineAtShare: lastAt,
      reason: reason,
      envelopeSamples: isRunningBySample == null ? null : span,
      headOffSeconds: head,
      tailOffSeconds: tail,
    );
  }

  /// The engine-bearing predicate — the SAME one `Obd2TripFeatures.fromSamples`
  /// uses (rpm / engine load / throttle / MEASURED fuel rate).
  static bool hasEngineData(TripSample s) =>
      s.rpm != null ||
      s.engineLoadPercent != null ||
      s.throttlePercent != null ||
      s.fuelRateLPerHour != null;

  /// #3861 — the engine-RUNNING predicate, the recorder's own floor.
  static bool isEngineRunning(TripSample s) =>
      (s.rpm ?? 0) >= TripRecorder.kEngineRunningRpmFloor;

  /// Convenience over the domain [TripSample] shape, envelope-aware.
  static Obd2EngineCoverage? fromTripSamples(List<TripSample> samples) =>
      fromFlags(
        [for (final s in samples) hasEngineData(s)],
        isRunningBySample: [for (final s in samples) isEngineRunning(s)],
        timestamps: [for (final s in samples) s.timestamp],
      );

  /// Export shape for the drivingAnalysis trace (#3499, schema v4;
  /// #3861 adds the envelope fields).
  Map<String, Object?> toJson() => {
        'engineSamples': engineSamples,
        'totalSamples': totalSamples,
        'engineSampleShare': double.parse(share.toStringAsFixed(3)),
        'lastEngineAtShare': double.parse(lastEngineAtShare.toStringAsFixed(3)),
        'reason': reason.name,
        if (envelopeSamples != null) 'envelopeSamples': envelopeSamples,
        if (headOffSeconds > 0)
          'headOffSeconds': double.parse(headOffSeconds.toStringAsFixed(1)),
        if (tailOffSeconds > 0)
          'tailOffSeconds': double.parse(tailOffSeconds.toStringAsFixed(1)),
      };
}
