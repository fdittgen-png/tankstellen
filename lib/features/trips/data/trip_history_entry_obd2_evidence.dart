// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_history_entry.dart';

/// #3824 — what this trip proves about its OBD2 session, independent of
/// whether per-PID communication was instrumented.
///
/// [obd2Diagnostic] answers "was per-PID polling recorded", which is a much
/// narrower question than "did this trip have OBD2". Treating the first as
/// the second made the trip-detail card announce *"No OBD2 session
/// recorded"* for a trip with 324 engine samples at 99.7% coverage.
///
/// Lives here rather than in a new file because this one already imports
/// `obd2/api.dart`: `feature_boundary_test` counts cross-feature imports
/// per file against an exact baseline, so a new trips->obd2 file would read
/// as a regression.
extension Obd2EvidenceX on TripHistoryEntry {
  /// Null when the trip has no samples to judge.
  Obd2TripEvidence? obd2Evidence(List<TripSample> tripSamples) {
    // The SAME engine predicate the fuel pipeline uses, so this can never
    // disagree with the fuel chart rendered beside it.
    final coverage = Obd2EngineCoverage.fromTripSamples(tripSamples);
    if (coverage == null) return null;

    // Last verdict wins: a reconnect can re-establish the protocol, and the
    // final state is the one that describes the session.
    String? verdict;
    for (final e in sessionJournal?.events ??
        const <RecordingSessionEvent>[]) {
      if (e.kind == RecordingSessionEventKind.protocolVerdict) {
        verdict = e.detail ?? verdict;
      }
    }

    final started = summary.startedAt;
    final ended = summary.endedAt;

    return Obd2TripEvidence(
      engineSamples: coverage.engineSamples,
      totalSamples: coverage.totalSamples,
      coverageShare: coverage.share,
      adapterName: adapterName,
      adapterMac: adapterMac,
      protocolVerdict: verdict,
      terminationReason: termination?.reason.name,
      duration: (started != null && ended != null)
          ? ended.difference(started)
          : null,
      fuelMeasured: Obd2TripFeatures.fromSamples(tripSamples)?.fuelSource ==
          Obd2FuelSource.measured,
    );
  }
}
