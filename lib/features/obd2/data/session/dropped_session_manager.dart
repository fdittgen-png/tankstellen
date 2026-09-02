// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/telemetry/collectors/breadcrumb_collector.dart';
import '../../../trips/api.dart';
import 'obd2_reattach_source.dart';
import 'obd2_service.dart';
import '../auto_record_trace_log.dart';
import '../obd2_comm_diagnostics.dart';
import '../obd2_session_diagnostic.dart';
import 'dropped_session_host.dart';
import 'dropped_session_repo_resolver.dart';
import '../paused_trip_repository.dart';

part 'dropped_session_manager_engine_off.dart';
part 'dropped_session_manager_reattach.dart';

/// Why a recording transitioned into the paused-due-to-drop state
/// (#1330 phase 3). Distinguishes the two failure modes that share the
/// pause-with-grace recovery path:
///
///  * [transportError] — repeated transport-level failures (BT link
///    dropped, three consecutive errors within the window, or a typed
///    `Obd2DisconnectedException`). User-visible surface: "OBD2
///    connection lost".
///  * [silentFailure] — adapter connected + answering, but every high-
///    priority PID parse returns null for the silent-failure threshold's
///    worth of consecutive ticks (ECU off, protocol mismatch, defective
///    adapter firmware).
///  * [engineOff] — #3859 (Epic #3855): the same silent bus, but the
///    vehicle power model says the car is asleep (alternator voltage
///    gone, no engine evidence). Nothing is broken — the driver switched
///    the engine off with the recording still running, or started the
///    recording before starting the engine. The reaction is the calm
///    one: keep recording on GPS, keep the link on a voltage watch, dial
///    nothing, and re-attach on the engine transition.
enum TripDropReason {
  transportError,
  silentFailure,
  engineOff,
}

/// Owns the connection-drop RECOVERY lifecycle for a single recording
/// session — the second slice of the #2167/#2188 god-class
/// decomposition of `TripRecordingController`.
///
/// Everything that happens AFTER the drop *detector* (#1679) decides
/// "this is a drop": the #1904 silent-reconnect window, the visible-drop
/// escalation, the #797 grace timer + auto-finalise, the reconnect-
/// scanner orchestration and the paused/history Hive persistence. The
/// emit loop, the scheduler, the drop detector and the trip-identity
/// fields stay on the controller; the manager reaches them through the
/// injected [DroppedSessionHost], so the recording loop and the recovery
/// state machine stay decoupled and every collaborator (clock, both Hive
/// repos, the scanner factory, the host) is injectable — a unit test
/// drives every branch with no real service, scheduler or wall clock.
class DroppedSessionManager {
  final DroppedSessionHost _host;
  final DateTime Function() _now;

  /// Grace window before a paused-due-to-drop session auto-finalises
  /// (#797 phase 1). Production default is 15 minutes; tests pass small
  /// values to exercise the auto-finalise path.
  final Duration _pauseGraceWindow;

  /// #1904 — how long a transport drop stays invisible while the
  /// reconnect scanner tries to get the adapter back. `Duration.zero`
  /// disables the silent window (every drop is visible at once).
  final Duration _silentReconnectWindow;

  /// Pinned adapter MAC the reconnect scanner searches for — resolved
  /// upstream by `resolveAdapterPin` (#3423: vehicle-profile MAC, else the
  /// last-good auto-pin). Null when NEITHER exists: scanner never starts.
  final String? _pinnedAdapterMac;

  /// Factory that builds the reconnect scanner from the pinned MAC + the
  /// on-reconnect callback. Null in production unit contexts that don't
  /// wire the BT scan layer.
  final Obd2ReattachSource? Function(
    String pinnedMac,
    VoidCallback onReconnect,
  )? _reconnectScannerFactory;

  /// Resolves the paused-trips + history Hive repos (#2565 — extracted to
  /// [DroppedSessionRepoResolver] to keep this file under the 400-line
  /// cap). Production resolves lazily from the open box; tests inject
  /// in-memory repos through the constructor overrides.
  final DroppedSessionRepoResolver _repos;

  Timer? _graceTimer;
  Timer? _silentReconnectTimer;
  Obd2ReattachSource? _reconnectScanner;

  /// #1904 — true between a transport drop and either a silent
  /// reconnect or the escalation to the visible drop.
  bool _silentlyReconnecting = false;

  /// Reason the most recent drop fired. Null when no drop has occurred
  /// or after a resume / silent recovery cleared it.
  TripDropReason? _dropReason;

  /// #3915 — the re-adoption cycle breaker (see the reattach part).
  late final ReadoptionCycleBreaker _adoptionGate =
      ReadoptionCycleBreaker(now: _now);

  DroppedSessionManager({
    required this._host,
    required this._now,
    required this._pauseGraceWindow,
    required this._silentReconnectWindow,
    this._pinnedAdapterMac,
    this._reconnectScannerFactory,
    PausedTripRepository? pausedRepo,
    TripHistoryRepository? historyRepo,
  })  : _repos = DroppedSessionRepoResolver(
          pausedOverride: pausedRepo,
          historyOverride: historyRepo,
        );

  /// Why the session is in (or last entered) the paused-due-to-drop
  /// state (#1330 phase 3). Null when not in that state.
  TripDropReason? get dropReason => _dropReason;

  /// #1904 — true while inside the invisible reconnect window (a
  /// transport drop the scanner is trying to clear before the banner).
  bool get silentlyReconnecting => _silentlyReconnecting;

  /// The auto-reconnect scanner currently in flight, or null when none
  /// is wired / running. Exposed for the controller's
  /// `debugReconnectScanner` test hook.
  Obd2ReattachSource? get reconnectScanner => _reconnectScanner;

  /// #2767 — true while the reconnect scanner has given up active scanning
  /// and is passive-waiting for the adapter. Drives the calmer banner copy.
  bool get reconnectPassiveWaiting =>
      _reconnectScanner?.isPassiveWaiting ?? false;

  /// React to a detected connection drop (#797 / #1904). A `transportError`
  /// drop first enters the invisible reconnect window (scheduler stopped,
  /// scanner probing, host still `recording`); only if [_silentReconnectWindow]
  /// elapses with no reconnect does it escalate to visible. A `silentFailure`
  /// drop escalates straight to visible — a reconnect cannot revive a dead ECU.
  void handleDrop({
    TripDropReason reason = TripDropReason.transportError,
  }) {
    final degraded = _host.degradedGpsOnly; // #3776 — already handled
    if (_host.pausedDueToDrop || _silentlyReconnecting || degraded) return;
    // #3859 — the engine was switched off with GPS alive: not a drop to
    // recover from, a state to wait out. Everything below (tearing the
    // service down, the fallback marker, the reconnect scanner) is the
    // machinery for a BROKEN link, and it is exactly what turned a
    // parked car into dial storms and a "connection dropped" verdict.
    if (reason == TripDropReason.engineOff && _host.gpsAlive) {
      enterEngineOffWait();
      return;
    }
    // #1920 — trace every detected drop for the exportable OBD2 log.
    _trace(AutoRecordEventKind.dropDetected, detail: reason.name);
    _note(RecordingSessionEventKind.linkDrop, reason.name); // #3797
    _refuseIfReadoptionCycle(reason); // #3915
    // #2905 — record the connected→dropped transition (gated comm-health).
    Obd2CommDiagnostics.instance
        .noteSessionTransition(Obd2SessionState.dropped, detail: reason.name);
    _host.stopScheduler();
    // #2671 — also GATE dispatch (not just cancel the timer): if a later
    // path restarts the scheduler while the link is still flapping, a paused
    // tick must not write into the dead socket. Resumed only on a confirmed
    // reconnect (onScannerReconnect).
    _host.pauseScheduler();
    // #2524 — tear down the now-dead service so its channel closes + any
    // stranded `_pending` fails (else it later trips the concurrent guard).
    _host.disconnectDroppedService();
    _host.clearDropDetectorErrorWindow();
    _persistPausedSnapshot();
    // #2565 — OBD2 dropped but GPS is alive: keep recording GPS-only
    // instead of pausing. Outranks the silent window + visible pause for
    // BOTH drop reasons — a dead ECU (silentFailure) still leaves GPS
    // perfectly able to carry the trip. The grace timer stays DISABLED:
    // the trip is actively recording, so it must never auto-finalise.
    if (_host.gpsAlive) {
      _enterDegradedGpsOnly(reason);
      return;
    }
    if (reason == TripDropReason.transportError &&
        _silentReconnectWindow > Duration.zero) {
      _silentlyReconnecting = true;
      _dropReason = reason;
      // #1920 — record entry into the #1904 invisible reconnect window.
      _trace(AutoRecordEventKind.silentReconnectStarted);
      _startReconnectScanner();
      _silentReconnectTimer?.cancel();
      _silentReconnectTimer =
          Timer(_silentReconnectWindow, _escalateToVisibleDrop);
      // Deliberately no emitState() — an in-presence drop the scanner
      // is about to clear must stay invisible to the UI.
      return;
    }
    _enterVisibleDrop(reason);
  }

  /// Flip into the visible pause-with-grace state: stop is already done
  /// by [handleDrop]; this starts the grace timer, ensures a reconnect
  /// scanner is running, and emits so the pause banner appears.
  void _enterVisibleDrop(TripDropReason reason) {
    _host.pausedDueToDrop = true;
    _note(RecordingSessionEventKind.pausedDueToDrop, reason.name);
    _dropReason = reason;
    _graceTimer?.cancel();
    _graceTimer = Timer(_pauseGraceWindow, _onGraceWindowElapsed);
    // The scanner may already be running from the silent window.
    if (_reconnectScanner == null) _startReconnectScanner();
    _host.emitState();
  }

  /// #1904 — the silent reconnect window elapsed without the adapter
  /// coming back; surface the drop to the user.
  void _escalateToVisibleDrop() {
    _silentReconnectTimer = null;
    if (!_silentlyReconnecting || _host.pausedDueToDrop || _host.stopped) {
      return;
    }
    _silentlyReconnecting = false;
    // #1920 — record the escalation: the silent window elapsed without
    // the adapter coming back, so the drop is now visible to the user.
    _trace(AutoRecordEventKind.dropEscalatedToVisible);
    _enterVisibleDrop(_dropReason ?? TripDropReason.transportError);
  }

  /// Reaction when the reconnect scanner finds the adapter again. The
  /// scanner self-stops before firing this callback.
  void onScannerReconnect() {
    _reconnectScanner = null;
    if (_host.degradedGpsOnly) {
      // #2565 — OBD2 re-attached while recording GPS-only: drop back to full
      // OBD2 recording. The trip never paused, so there is no grace timer to
      // cancel and no pause-banner teardown; clear the degrade flag then
      // resume polling cleanly. The drop-window samples stay honestly GPS-only.
      _host.degradedGpsOnly = false;
      _note(RecordingSessionEventKind.leftDegraded);
      _resumePollingAfterSilentReconnect();
      return;
    }
    if (_silentlyReconnecting) {
      // #1904 — reconnected inside the silent window: resume polling without
      // the user ever having seen a pause. Mirrors the drop-recovery half of
      // resume() but skips the pausedDueToDrop teardown (it was never set) and
      // the emitState pause-banner churn — the state was `recording`.
      _silentReconnectTimer?.cancel();
      _silentReconnectTimer = null;
      _silentlyReconnecting = false;
      _resumePollingAfterSilentReconnect();
      return;
    }
    // Reconnected after the drop went visible — the ordinary resume() path
    // cancels the grace timer and clears the paused-trips row.
    if (_host.pausedDueToDrop) {
      // #1920 — record the visible-path recovery: the adapter came back after
      // the pause banner had already been shown.
      _trace(AutoRecordEventKind.reconnectSucceeded);
      _host.resumeFromReconnect();
    }
  }

  /// Shared tail of the two no-pause reconnect paths (#2565 GPS-degrade +
  /// #1904 silent window): the adapter came back without the user ever
  /// seeing a pause, so clear the drop reason, re-arm the detector, drop the
  /// paused row, trace the silent recovery, and resume polling (#2671 — re-open
  /// dispatch + reset failure streaks first). Respects a user pause that
  /// landed during the window.
  void _resumePollingAfterSilentReconnect() {
    _dropReason = null;
    _host.resetDropDetector();
    clearPausedTripRow();
    _trace(AutoRecordEventKind.silentReconnectSucceeded);
    _host.resumeScheduler();
    if (!_host.paused && !_host.stopped) _host.startScheduler();
    _host.emitState();
  }

  /// Persist the in-progress trip snapshot to the paused-trips box on
  /// drop (#797). Delegates to [DroppedSessionRepoResolver] (#2565).
  void _persistPausedSnapshot() =>
      _repos.savePausedSnapshot(_host, at: _now());

  /// Delete this session's row from the paused-trips box — the session is
  /// live again, so leaving the partial behind would let a later pause
  /// stomp the in-memory state. Best-effort.
  void clearPausedTripRow() => _repos.deletePausedRow(_host.sessionId);

  /// Append one auto-record trace event for this drop episode (#1920),
  /// always tagged with the pinned adapter MAC. A thin wrapper that keeps the
  /// eight call sites one-liners.
  void _trace(AutoRecordEventKind kind, {String? detail}) =>
      AutoRecordTraceLog.add(kind, mac: _pinnedAdapterMac, detail: detail);

  /// #3797 — one lifecycle event onto the trip's session timeline.
  void _note(RecordingSessionEventKind kind, [String? detail]) =>
      _host.noteSessionEvent(kind, detail: detail);

  /// Grace-window auto-finalise (#797). Stops the scanner first (so a late
  /// reconnect can't race an already-finalised trip), finalises the partial
  /// into trip-history + deletes the paused row (#2565 — persistence in the
  /// resolver), then stops the host.
  Future<void> _onGraceWindowElapsed() async {
    if (!_host.pausedDueToDrop) return;
    await stopReconnectScanner();
    _note(RecordingSessionEventKind.ended, 'graceWindowExpiry'); // #3795
    await _repos.finaliseToHistory(_host, dropReason: _dropReason?.name);
    _host.pausedDueToDrop = false;
    _host.stopped = true;
    _host.started = false;
    _graceTimer = null;
    _host.emitState();
  }

  /// Cancel the grace timer + clear the drop reason — called by the
  /// controller's resume() before it clears the paused row and re-arms the
  /// detector. Scanner teardown stays the caller's job.
  void cancelGrace() {
    _graceTimer?.cancel();
    _graceTimer = null;
    _dropReason = null;
  }

  /// Tear down every pending timer + the silent-reconnect flag — called by
  /// the controller's stop(). Scanner teardown is awaited separately by
  /// stop() via [stopReconnectScanner].
  void cancelAllTimers() {
    _graceTimer?.cancel();
    _graceTimer = null;
    _silentReconnectTimer?.cancel();
    _silentReconnectTimer = null;
    _silentlyReconnecting = false;
  }

  /// Test seam: synchronously drive the grace-window finalisation path
  /// without waiting for the real timer. Plain (not `@visibleForTesting`)
  /// because the controller's `debugExpireGraceWindow` hook delegates here.
  Future<void> expireGraceWindowNow() async {
    _graceTimer?.cancel();
    await _onGraceWindowElapsed();
  }
}
