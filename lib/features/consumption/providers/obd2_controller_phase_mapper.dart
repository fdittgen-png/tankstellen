// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../data/obd2/trip_recording_controller.dart';
import 'trip_recording_phase.dart';

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
    case TripRecordingControllerState.stopped:
      return TripRecordingPhase.finished;
  }
}
