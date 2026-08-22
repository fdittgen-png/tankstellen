// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Stage surfaced while the OBD2 adapter is being reached and the
/// recorder is warming up. Drives the inline [TripStartProgress] card.
///
/// Lives in the domain layer (rather than alongside the presentation
/// widget) since #2274 concern 2 — start-now-connect-later — moved the
/// connect to run WHILE the recording screen is mounted, so the
/// [TripRecordingState] now carries the current stage and the
/// presentation widget renders it. Keeping the enum here avoids a
/// provider→presentation import.
enum TripStartStage {
  /// Pinned-MAC connect over Bluetooth (or the picker hasn't returned yet).
  connectingAdapter,

  /// Recorder is reading the odometer / VIN and priming the polling loop.
  readingVehicleData,

  /// Final beat before the live recording stream takes over.
  startingRecording,
}
