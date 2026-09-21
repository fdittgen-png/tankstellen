// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The wire format of a recording phase in the active-trip WAL row
/// (#4243).
///
/// The snapshot stores its phase as a `String`, and before this file the
/// two ends did not share a vocabulary: the writer emitted an exhaustive
/// switch over [TripRecordingControllerState], while the reader compared
/// against `'stopped'` and `'saved'` — and `'saved'` has no producer in
/// any version of the app (`git log -S` finds it only in #3250, the same
/// change that added the comparison). A reader testing for a value the
/// writer cannot emit is one rename away from matching nothing at all,
/// which is precisely the failure #3250 exists to prevent: a missed
/// terminal phase resurrects an already-finalised trip and overwrites
/// the good history row with a gutted recovery summary.
///
/// ## Deliberately NOT a round trip
///
/// [recordingPhaseToWire] is lossy on purpose. #2565 — a GPS-only
/// degraded trip is still actively recording, so it persists as
/// `recording` and rehydrates as a live trip, never as a pause the user
/// has to resume. So `toWire(degradedGpsOnly) == 'recording'` and
/// `fromWire('recording') == recording`: the asymmetry is the behaviour,
/// not a bug to fix.
///
/// ## The WAL invariant (#4162)
///
/// **A WAL row exists ⟺ its trip is not yet in history.** The row is
/// cleared only once the trip's history write has landed, and that clear
/// is the ONLY terminal marker a recovery may trust: a row on disk after
/// a process death is a trip to hand back to the user, whatever phase it
/// names. No writer persists `'stopped'` any more (#4311: a flush once the
/// controller stopped is refused); [isTerminalRecordingPhase] still reads
/// it as terminal, for rows written by earlier versions.
library;

import '../../obd2/api.dart';

/// Wire value for [state] — the ONE place a phase becomes a string.
String recordingPhaseToWire(TripRecordingControllerState state) {
  switch (state) {
    case TripRecordingControllerState.idle:
      return 'idle';
    case TripRecordingControllerState.recording:
      return 'recording';
    case TripRecordingControllerState.paused:
      return 'paused';
    case TripRecordingControllerState.pausedDueToDrop:
      return 'pausedDueToDrop';
    // #2565 — see the asymmetry note above.
    case TripRecordingControllerState.degradedGpsOnly:
      return 'recording';
    case TripRecordingControllerState.stopped:
      return 'stopped';
  }
}

/// The state [wire] names, or null when it names none.
///
/// Null is the honest answer for an absent row, a value written by a
/// future version, and a corrupt payload alike — the caller decides what
/// to do with "I do not know", rather than inheriting a default that
/// silently means "live recording".
TripRecordingControllerState? recordingPhaseFromWire(String? wire) =>
    switch (wire) {
      'idle' => TripRecordingControllerState.idle,
      'recording' => TripRecordingControllerState.recording,
      'paused' => TripRecordingControllerState.paused,
      'pausedDueToDrop' => TripRecordingControllerState.pausedDueToDrop,
      'stopped' => TripRecordingControllerState.stopped,
      _ => null,
    };

/// Whether [wire] names a phase whose trip was already finalised (#3250).
///
/// An unknown value is NOT terminal: treating it as finalised would
/// silently discard a live trip written by a version this build does not
/// understand, and losing somebody's drive is the worse of the two
/// failures. It reaches the staleness check instead, which bounds the
/// damage to 24 h and logs the discard either way.
bool isTerminalRecordingPhase(String? wire) =>
    recordingPhaseFromWire(wire) == TripRecordingControllerState.stopped;

/// The phase a snapshot rehydrates as when its stored value is absent or
/// unrecognised (#4243).
///
/// `ActiveTripSnapshot.fromJson` used a bare `?? 'recording'`, which made
/// an unreadable phase indistinguishable from a healthy live recording.
/// The value is the same — a row on disk almost always belongs to a trip
/// that was recording — but it is now a named decision with a reason
/// rather than a fallback nobody chose.
const String kUnknownRecordingPhaseWire = 'recording';
