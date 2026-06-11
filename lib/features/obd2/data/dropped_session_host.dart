// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../consumption/domain/entities/gps_sample_diagnostic.dart';
import '../../consumption/domain/trip_recorder.dart';

/// Seam the `DroppedSessionManager` uses to read and drive the
/// recording session it is recovering, without owning the recording
/// loop itself (#2188).
///
/// The manager owns the *reaction* to a connection drop — the silent-
/// reconnect window, the visible-drop escalation, the grace timer, the
/// reconnect scanner and the paused/history Hive persistence. But the
/// emit loop, the scheduler, the drop *detector* and the trip-identity
/// fields stay on the controller. This interface is the narrow set of
/// callbacks + getters the reaction needs from its host so the two
/// halves stay decoupled and the manager is unit-testable against a
/// fake host (no real `Obd2Service` / scheduler required).
abstract class DroppedSessionHost {
  /// Stop the PID polling loop — called the instant a drop is detected
  /// so no further transport chatter happens while we recover.
  void stopScheduler();

  /// #2671 — gate PID dispatch the instant a drop is detected, WITHOUT
  /// tearing the scheduler down. Belt-and-braces with [stopScheduler]: even
  /// if the timer is later restarted while the link is still flapping, a
  /// paused tick will not write into the dead/reconnecting socket (which
  /// threw `PlatformException(state, not connected)` 4× in the field log).
  void pauseScheduler();

  /// #2671 — re-open PID dispatch once the link has genuinely recovered.
  /// Also resets the per-PID failure/backoff streaks + the unresponsive
  /// diagnostic so the reconnected adapter starts clean. Called only on a
  /// confirmed reconnect, never while still flapping.
  void resumeScheduler();

  /// Tear down the CURRENT (now-dead) OBD2 service the instant a drop is
  /// detected (#2524). Closes its transport channel and fails any command
  /// stranded in the transport's `_pending` via `_failPending`, so the
  /// abandoned half-dead instance can't later trip the
  /// concurrent-sendCommand guard. Best-effort + fire-and-forget — the
  /// link is already gone, so a disconnect error here is expected and must
  /// not derail the recovery state machine.
  void disconnectDroppedService();

  /// Resume the PID polling loop after a silent reconnect inside the
  /// #1904 window. Production gates this on "not paused / not stopped"
  /// itself; the manager just asks.
  void startScheduler();

  /// Clear the drop *detector*'s sliding window + silent-failure latch
  /// so a fresh post-recovery stretch can fire again.
  void resetDropDetector();

  /// Re-arm only the transport-error sliding window (NOT the silent-
  /// failure latch) — done when a drop fires so a burst of trailing
  /// errors from the same outage doesn't immediately re-trigger.
  void clearDropDetectorErrorWindow();

  /// Re-publish the recording state on the controller's state stream.
  void emitState();

  /// Drive the controller's ordinary resume path — cancels the grace
  /// timer, clears the paused row, flips back to recording. Called by
  /// the reconnect scanner when the adapter comes back AFTER the drop
  /// went visible.
  void resumeFromReconnect();

  /// Build the in-flight [TripSummary] for the paused-trip snapshot.
  TripSummary buildInProgressSummary();

  /// Build the FINAL [TripSummary] (distance provenance, gear coaching,
  /// VE) for grace-window auto-finalisation.
  TripSummary buildFinalSummary();

  // --- Lifecycle flags (read + write) ---------------------------------

  bool get pausedDueToDrop;
  set pausedDueToDrop(bool value);

  /// #2565 — true while the trip is recording GPS-only because OBD2
  /// dropped on a live-GPS drive. The manager sets this (instead of the
  /// silent/visible pause path) when [gpsAlive] holds at drop time, and
  /// clears it on a scanner reconnect; the controller's emit loop reads
  /// it to switch to GPS-only sample construction.
  bool get degradedGpsOnly;
  set degradedGpsOnly(bool value);

  // --- GPS liveness (read-only) ---------------------------------------

  /// #2565 — whether a real GPS fix landed recently enough that an OBD2
  /// drop should degrade to GPS-only recording instead of pausing.
  /// Derived on the controller from its last-GPS-fix timestamp + clock;
  /// no geolocator coupling reaches the manager.
  bool get gpsAlive;

  bool get stopped;
  set stopped(bool value);

  bool get started;
  set started(bool value);

  /// True while the user has tapped pause — read so a silent reconnect
  /// respects a pause that landed during the window.
  bool get paused;

  // --- Trip identity / snapshot payload (read-only) -------------------

  String? get sessionId;
  String? get vehicleId;
  String? get vin;
  double? get odometerStartKm;
  double? get odometerLatestKm;
  bool get automatic;

  /// The per-tick recording profile captured so far (#2291). The buffer
  /// is still live in memory when the grace timer fires (it is never
  /// cleared by the finalise-summary path), so the grace-window
  /// auto-finalise can persist the same charts a normal stop would.
  List<TripSample> get capturedSamples;

  /// The per-fix GPS cadence diagnostics captured so far (#2291).
  /// Persisted alongside [capturedSamples] so a grace-finalised trip
  /// carries the same diagnostics payload as a normally-stopped one.
  List<GpsSampleDiagnostic> get capturedGpsSampleDiagnostics;
}
