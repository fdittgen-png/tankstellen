// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../domain/entities/gps_sample_diagnostic.dart';
import '../../domain/trip_recorder.dart';

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
