// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../data/session/trip_recording_controller.dart';
import '../../trips/api.dart';

/// Maps the [TripRecordingController]'s lifecycle enum onto the
/// provider-facing [TripRecordingPhase]. Extracted from
/// [Obd2RecordingPipeline] (#2548 — to keep that file under the
/// file-length cap); pure, so it lives as a free function rather than
/// a method. Mirrors the notifier's former inline `_phaseFor`.
TripRecordingPhase phaseForController(TripRecordingController ctl) {
  switch (ctl.currentState) {
    case TripRecordingControllerState.idle:
      return TripRecordingPhase.idle;
    case TripRecordingControllerState.recording:
      return TripRecordingPhase.recording;
    case TripRecordingControllerState.paused:
      return TripRecordingPhase.paused;
    case TripRecordingControllerState.pausedDueToDrop:
      return TripRecordingPhase.pausedDueToDrop;
    case TripRecordingControllerState.degradedGpsOnly:
      return TripRecordingPhase.degradedGpsOnly;
    case TripRecordingControllerState.stopped:
      return TripRecordingPhase.finished;
  }
}

/// The recording state after the controller announced a state change —
/// the pipeline's state-listener body, extracted (#4311) so the pipeline
/// stays under its file-length cap. Pure: [current] plus the controller's
/// reads in, the next state out.
TripRecordingState stateAfterControllerChange(
  TripRecordingState current,
  TripRecordingController ctl,
) {
  final newPhase = phaseForController(ctl);
  final dropping = newPhase == TripRecordingPhase.pausedDueToDrop ||
      newPhase == TripRecordingPhase.degradedGpsOnly;
  // #2767 — surface whether the reconnect scanner has given up active
  // scanning and is passive-waiting, so the GPS-degraded banner can swap
  // its copy. Only meaningful while a drop is being recovered; false in
  // every other phase so a fresh recording / save never inherits a stale
  // flag.
  final passiveWaiting = dropping && ctl.reconnectPassiveWaiting;
  // #4385 — and whether the ONE owner is parked rather than dialing;
  // same scoping rule, so a fresh recording never inherits it.
  final ownerParked = dropping && ctl.linkOwnerParked;
  // #1330 phase 3 — surface the controller's drop reason. Cleared when
  // leaving the drop state (#3859: the GPS-degraded phase too).
  return dropping
      ? current.copyWith(
          phase: newPhase,
          dropReason: ctl.dropReason,
          reconnectPassiveWaiting: passiveWaiting,
          linkOwnerParked: ownerParked,
          parkedPromptDue: ctl.parkedPromptDue, // #3862
        )
      : current.copyWith(
          phase: newPhase,
          clearDropReason: true,
          reconnectPassiveWaiting: passiveWaiting,
          linkOwnerParked: ownerParked,
          parkedPromptDue: false,
        );
}
