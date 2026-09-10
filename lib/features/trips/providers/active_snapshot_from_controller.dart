// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../obd2/api.dart';
import '../domain/trip_recorder.dart';

// The two pure reads the WAL snapshot takes off a live recording
// controller: the phase string it persists, and the running summary it
// carries so recovery can render a preview. #4036 (epic #4032): both were
// methods on a `part` mixin of the recording notifier, and neither touched
// notifier state — they are functions of the controller alone, so they are
// a library of their own and testable without building a notifier.

String phaseStringForController(TripRecordingController ctl) {
  switch (ctl.currentState) {
    case TripRecordingControllerState.idle:
      return 'idle';
    case TripRecordingControllerState.recording:
      return 'recording';
    case TripRecordingControllerState.paused:
      return 'paused';
    case TripRecordingControllerState.pausedDueToDrop:
      return 'pausedDueToDrop';
    // #2565 — a GPS-only degraded trip is still actively recording, so
    // the WAL snapshot persists it as 'recording' (it rehydrates as a
    // live trip on relaunch, never as a pause that needs resuming).
    case TripRecordingControllerState.degradedGpsOnly:
      return 'recording';
    case TripRecordingControllerState.stopped:
      return 'stopped';
  }
}

/// Pull the recorder's running summary; lets the snapshot carry
/// the latest distance / fuel / harsh counts without forcing the
/// controller to expose more debug surface than [capturedSamples].
/// [samples] is the buffer view the caller read for this flush (#3741).
TripSummary summaryFromController(TripRecordingController ctl) {
  // The controller has no public mid-trip summary accessor; rather
  // than reach into its recorder we use the captured buffer's O(1)
  // facts — the post-debounce 1 Hz feed, plenty for the staleness /
  // preview rendering recovery does. A perfect mid-trip summary
  // (idle/harsh counters) would need the controller to expose its own
  // recorder snapshot; deferred until recovery acquires a richer preview.
  final first = ctl.firstCapturedAt;
  final last = ctl.latestSample?.timestamp;
  if (first == null || last == null) {
    return const TripSummary(
      distanceKm: 0,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
    );
  }
  // #3741 — incremental running max; the old whole-buffer loop was
  // O(n) per 5 s flush (O(n²) over a drive) on the gauge isolate.
  final maxRpm = ctl.maxCapturedRpm;
  // #3251 — use the controller's OWN gap-capped distance + provenance, not a
  // re-integration of the raw buffer. Re-integrating bridged dropout gaps and
  // fabricated ~10 km across a 20-min hole (the #1927 bug on the recovery
  // path); `currentDistanceKm` already applies `maxIntegrationGapSeconds`, and
  // `distanceSource` keeps the real provenance instead of defaulting 'virtual'.
  return TripSummary(
    distanceKm: ctl.currentDistanceKm,
    maxRpm: maxRpm,
    highRpmSeconds: 0,
    idleSeconds: 0,
    harshBrakes: 0,
    harshAccelerations: 0,
    startedAt: first,
    endedAt: last,
    distanceSource: ctl.distanceSource,
  );
}
