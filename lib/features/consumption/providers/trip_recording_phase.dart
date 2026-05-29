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
enum TripRecordingPhase {
  idle,
  connecting,
  recording,
  paused,
  pausedDueToDrop,
  finished
}
