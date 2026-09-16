// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Lifecycle phase of the app-wide OBD2 trip recording (#726).
///
/// #797 phase 1 adds [pausedDueToDrop] for the "Bluetooth link lost
/// mid-recording" case. Distinct from [paused] because the user did
/// not pause; the partial trip is auto-persisted to the paused-trips
/// Hive box and a grace timer ticks in the controller. Phase 2 wires
/// this into a banner + auto-reconnect scanner.
///
/// #2274 concern 2 adds [connecting] for the "start-now-connect-later"
/// push: the recording screen opens IMMEDIATELY in this transient phase
/// while the BLE connect + odometer prime run underneath, mirroring the
/// GPS-only path that already pushes at once. It is deliberately NOT an
/// active phase (see [TripRecordingState.isActive]) — no trip exists
/// yet, so the persistent recording banner must not surface. It
/// resolves into [recording] on a successful connect, or back to [idle]
/// if the connect fails / the user backs out.
///
/// #2548 adds [saving] as the symmetric stop-side bookend to
/// [connecting]: when the user taps Stop, the screen stays mounted in
/// this transient phase while the summary is finalised, written to Hive
/// history, and (when cloud sync is on) handed to the fire-and-forget
/// upload — so the ~300-700 ms save shows staged progress instead of a
/// frozen swap to the summary. Like [connecting] it is deliberately NOT
/// an active phase (see [TripRecordingState.isActive]) — the trip has
/// already left the live loop, so the persistent recording banner must
/// not resurface mid-save. It resolves into the summary view (or the
/// #2509 no-movement discard notice) the instant `stop()` returns.
///
/// #2565 adds [degradedGpsOnly] for the "OBD2 dropped mid-trip but GPS
/// is alive" case. Unlike [pausedDueToDrop], recording NEVER pauses: the
/// trip keeps capturing GPS-only samples (speed from the GPS latch, a
/// physics-derived L/100 km estimate) while the reconnect scanner tries
/// to re-attach the dongle. It is an ACTIVE sub-state (see
/// [TripRecordingState.isActive]) — a real trip is still being recorded,
/// so the recording banner stays up; only the contradictory "recording
/// paused" surface is swapped for a lightweight "GPS — OBD2 reconnecting"
/// notice. It resolves back into [recording] the instant the dongle
/// re-attaches, or escalates to [pausedDueToDrop] only if GPS ALSO dies.
///
/// The transitions between these phases are written down in
/// [kTripRecordingTransitions] (#4162).
enum TripRecordingPhase {
  idle,
  connecting,
  recording,
  paused,
  pausedDueToDrop,
  degradedGpsOnly,
  saving,
  finished
}

/// Every phase change the recording is allowed to make (#4162).
///
/// #3527 ended the OBD2 link's two-authority bugs by writing its state
/// machine down; this is the same discipline for the recording above
/// the link. Eight phases admit 56 changes; the ones below are the
/// changes some writer legitimately performs, and each is here because
/// of a named writer:
///
/// * `idle → connecting` — the recording screen opens before the adapter
///   answers (#2274). `idle → recording` — a start without that screen
///   (auto-record, GPS-only). `idle → pausedDueToDrop` — ONLY the
///   cold-start restore of a trip whose process died (#1303).
/// * `connecting → recording | idle` — the connect succeeded, or failed /
///   was abandoned.
/// * `recording → paused` (the user), `→ pausedDueToDrop` (the link died
///   and GPS with it), `→ degradedGpsOnly` (the link died, GPS lives,
///   #2565), `→ saving` (Stop), `→ finished` (a trip the controller ended
///   on its own).
/// * `paused → recording` (resume), `→ pausedDueToDrop` (the link died
///   under a user pause, #1904), `→ saving` (Stop).
/// * `pausedDueToDrop → recording` (the link returned, or Resume),
///   `→ saving` (Stop), `→ finished` (the #797 grace window expired, or
///   End on a restored trip), `→ idle` (a restored trip discarded).
/// * `degradedGpsOnly → recording` (the engine data came back, #4196),
///   `→ paused` (the user), `→ pausedDueToDrop` (GPS died too), `→ saving`
///   (Stop), `→ finished` (the parked auto-finalise, #3862).
/// * `saving → finished | idle` — the OBD2 and the GPS-only stop resolve
///   differently (#2548).
/// * `finished → idle | connecting | recording` — the summary was
///   consumed, or the next trip began without consuming it.
///
/// A write that keeps the phase is not a transition and is always
/// allowed: the live loop republishes `recording` on every reading.
///
/// ## Hidden sub-states (deliberately not phases)
///
/// Four situations share a phase with a healthier one, because the UI
/// must not tell them apart — but a reader of this table must:
///
/// * the #1904 silent reconnect window reads `recording` while the
///   scanner quietly redials (`DroppedSessionManager.silentlyReconnecting`);
/// * the #3859 engine-off wait reads `degradedGpsOnly`
///   (`TripRecordingState.awaitingEngine`);
/// * the #4196 recovery verification reads `degradedGpsOnly` while a
///   re-adopted link has not yet produced engine data;
/// * a trip recovered after its process died reads `pausedDueToDrop`
///   with no pipeline at all — the WAL snapshot is its only state.
const Map<TripRecordingPhase, Set<TripRecordingPhase>>
    kTripRecordingTransitions = {
  TripRecordingPhase.idle: {
    TripRecordingPhase.connecting,
    TripRecordingPhase.recording,
    TripRecordingPhase.pausedDueToDrop,
  },
  TripRecordingPhase.connecting: {
    TripRecordingPhase.recording,
    TripRecordingPhase.idle,
  },
  TripRecordingPhase.recording: {
    TripRecordingPhase.paused,
    TripRecordingPhase.pausedDueToDrop,
    TripRecordingPhase.degradedGpsOnly,
    TripRecordingPhase.saving,
    TripRecordingPhase.finished,
  },
  TripRecordingPhase.paused: {
    TripRecordingPhase.recording,
    TripRecordingPhase.pausedDueToDrop,
    TripRecordingPhase.saving,
  },
  TripRecordingPhase.pausedDueToDrop: {
    TripRecordingPhase.recording,
    TripRecordingPhase.saving,
    TripRecordingPhase.finished,
    TripRecordingPhase.idle,
  },
  TripRecordingPhase.degradedGpsOnly: {
    TripRecordingPhase.recording,
    TripRecordingPhase.paused,
    TripRecordingPhase.pausedDueToDrop,
    TripRecordingPhase.saving,
    TripRecordingPhase.finished,
  },
  TripRecordingPhase.saving: {
    TripRecordingPhase.finished,
    TripRecordingPhase.idle,
  },
  TripRecordingPhase.finished: {
    TripRecordingPhase.idle,
    TripRecordingPhase.connecting,
    TripRecordingPhase.recording,
  },
};

/// Whether moving from [from] to [to] is a documented transition — or no
/// transition at all.
bool isTripRecordingTransition(TripRecordingPhase from, TripRecordingPhase to) =>
    from == to || (kTripRecordingTransitions[from]?.contains(to) ?? false);
