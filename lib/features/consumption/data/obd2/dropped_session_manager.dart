// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../../core/logging/error_logger.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../trip_history_repository.dart';
import 'adapter_reconnect_scanner.dart';
import 'auto_record_trace_log.dart';
import 'dropped_session_host.dart';
import 'paused_trip_repository.dart';

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
enum TripDropReason {
  transportError,
  silentFailure,
}

/// Owns the connection-drop RECOVERY lifecycle for a single recording
/// session — the second slice of the #2167/#2188 god-class
/// decomposition of `TripRecordingController`.
///
/// Everything that happens AFTER the drop *detector* (#1679) decides
/// "this is a drop": the #1904 silent-reconnect window, the visible-drop
/// escalation, the #797 grace timer + auto-finalise, the reconnect-
/// scanner orchestration (#797 phase 3) and the paused/history Hive
/// persistence. The emit loop, the scheduler, the drop detector and the
/// trip-identity fields stay on the controller; the manager reaches them
/// through the injected [DroppedSessionHost] so the recording loop and
/// the recovery state machine stay decoupled — mirroring the pure,
/// dependency-light collaborator style of `TripDistanceResolver` (#2187)
/// and `TripDropDetector` (#1679).
///
/// Every collaborator is injected (the clock, both Hive repo overrides,
/// the scanner factory, the host seam) so a unit test can wire a fake
/// host + in-memory repos + a hand-driven scanner and exercise every
/// branch deterministically without a real `Obd2Service`, scheduler, or
/// wall-clock timer.
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

  /// Pinned adapter MAC the reconnect scanner searches for. Null when
  /// the vehicle profile carries no adapter pairing — the scanner is
  /// then never started and the grace window is the sole recovery path.
  final String? _pinnedAdapterMac;

  /// Factory that builds the reconnect scanner from the pinned MAC + the
  /// on-reconnect callback. Null in production unit contexts that don't
  /// wire the BT scan layer.
  final AdapterReconnectScanner? Function(
    String pinnedMac,
    VoidCallback onReconnect,
  )? _reconnectScannerFactory;

  /// Test overrides — in-memory repos. Production passes null and both
  /// are resolved lazily from the open Hive box on use.
  final PausedTripRepository? _pausedRepoOverride;
  final TripHistoryRepository? _historyRepoOverride;

  Timer? _graceTimer;
  Timer? _silentReconnectTimer;
  AdapterReconnectScanner? _reconnectScanner;

  /// #1904 — true between a transport drop and either a silent
  /// reconnect or the escalation to the visible drop.
  bool _silentlyReconnecting = false;

  /// Reason the most recent drop fired. Null when no drop has occurred
  /// or after a resume / silent recovery cleared it.
  TripDropReason? _dropReason;

  DroppedSessionManager({
    required DroppedSessionHost host,
    required DateTime Function() now,
    required Duration pauseGraceWindow,
    required Duration silentReconnectWindow,
    String? pinnedAdapterMac,
    AdapterReconnectScanner? Function(
      String pinnedMac,
      VoidCallback onReconnect,
    )? reconnectScannerFactory,
    PausedTripRepository? pausedRepo,
    TripHistoryRepository? historyRepo,
  })  : _host = host,
        _now = now,
        _pauseGraceWindow = pauseGraceWindow,
        _silentReconnectWindow = silentReconnectWindow,
        _pinnedAdapterMac = pinnedAdapterMac,
        _reconnectScannerFactory = reconnectScannerFactory,
        _pausedRepoOverride = pausedRepo,
        _historyRepoOverride = historyRepo;

  /// Why the session is in (or last entered) the paused-due-to-drop
  /// state (#1330 phase 3). Null when not in that state.
  TripDropReason? get dropReason => _dropReason;

  /// #1904 — true while inside the invisible reconnect window (a
  /// transport drop the scanner is trying to clear before the banner).
  bool get silentlyReconnecting => _silentlyReconnecting;

  /// The auto-reconnect scanner currently in flight, or null when none
  /// is wired / running. Exposed for the controller's
  /// `debugReconnectScanner` test hook.
  AdapterReconnectScanner? get reconnectScanner => _reconnectScanner;

  /// React to a detected connection drop (#797 / #1904). A
  /// `transportError` drop first enters the invisible reconnect window
  /// (scheduler stopped, scanner probing, host still reporting
  /// `recording`); only if [_silentReconnectWindow] elapses with no
  /// reconnect does it escalate to the visible state. A `silentFailure`
  /// drop escalates straight to visible — reconnecting the Bluetooth
  /// link cannot revive a dead ECU.
  void handleDrop({
    TripDropReason reason = TripDropReason.transportError,
  }) {
    if (_host.pausedDueToDrop || _silentlyReconnecting) return;
    // #1920 — trace every detected drop so a failed recording session
    // can be analysed from the exportable OBD2 diagnostic log.
    AutoRecordTraceLog.add(
      AutoRecordEventKind.dropDetected,
      mac: _pinnedAdapterMac,
      detail: reason.name,
    );
    _host.stopScheduler();
    _host.clearDropDetectorErrorWindow();
    _persistPausedSnapshot();
    if (reason == TripDropReason.transportError &&
        _silentReconnectWindow > Duration.zero) {
      _silentlyReconnecting = true;
      _dropReason = reason;
      // #1920 — record entry into the #1904 invisible reconnect window.
      AutoRecordTraceLog.add(
        AutoRecordEventKind.silentReconnectStarted,
        mac: _pinnedAdapterMac,
      );
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
    AutoRecordTraceLog.add(
      AutoRecordEventKind.dropEscalatedToVisible,
      mac: _pinnedAdapterMac,
    );
    _enterVisibleDrop(_dropReason ?? TripDropReason.transportError);
  }

  /// Kick off the auto-reconnect scanner (#797 phase 3) if both a
  /// pinned adapter MAC AND a scanner factory are wired. No-op
  /// otherwise — the grace timer remains the sole recovery path then.
  void _startReconnectScanner() {
    final mac = _pinnedAdapterMac;
    final factory = _reconnectScannerFactory;
    if (mac == null || factory == null) return;
    final scanner = factory(mac, onScannerReconnect);
    if (scanner == null) return;
    _reconnectScanner = scanner;
    // Fire-and-forget — start() is an async scheduler boot that
    // shouldn't block the drop handler. Errors inside the scanner are
    // already caught internally.
    unawaited(scanner.start());
  }

  /// Reaction when the reconnect scanner finds the adapter again. The
  /// scanner self-stops before firing this callback.
  void onScannerReconnect() {
    _reconnectScanner = null;
    if (_silentlyReconnecting) {
      // #1904 — reconnected inside the silent window: resume polling
      // without the user ever having seen a pause. Mirrors the
      // drop-recovery half of resume() but skips the pausedDueToDrop
      // teardown (it was never set) and the emitState pause-banner
      // churn — the state was `recording` throughout.
      _silentReconnectTimer?.cancel();
      _silentReconnectTimer = null;
      _silentlyReconnecting = false;
      _dropReason = null;
      _host.resetDropDetector();
      clearPausedTripRow();
      // #1920 — record the silent-path recovery: the adapter came back
      // inside the #1904 window and the user never saw a pause.
      AutoRecordTraceLog.add(
        AutoRecordEventKind.silentReconnectSucceeded,
        mac: _pinnedAdapterMac,
      );
      // Respect a user pause that landed during the silent window.
      if (!_host.paused && !_host.stopped) _host.startScheduler();
      _host.emitState();
      return;
    }
    // Reconnected after the drop went visible — the ordinary resume()
    // path cancels the grace timer and clears the paused-trips row.
    if (_host.pausedDueToDrop) {
      // #1920 — record the visible-path recovery: the adapter came back
      // after the pause banner had already been shown.
      AutoRecordTraceLog.add(
        AutoRecordEventKind.reconnectSucceeded,
        mac: _pinnedAdapterMac,
      );
      _host.resumeFromReconnect();
    }
  }

  /// Tear down the in-flight reconnect scanner. Best-effort; safe to
  /// call when none is running.
  Future<void> stopReconnectScanner() async {
    final scanner = _reconnectScanner;
    if (scanner == null) return;
    _reconnectScanner = null;
    try {
      await scanner.stop();
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {
            'where': 'DroppedSessionManager stop reconnect scanner'
          }));
    }
  }

  /// Persist the in-progress trip snapshot to the paused-trips box on
  /// drop (#797 phase 1). Fire-and-forget; Hive errors are logged by
  /// the repo and must not throw back into the scheduler callback.
  void _persistPausedSnapshot() {
    final repo = _resolvePausedRepo();
    final id = _host.sessionId;
    if (repo == null || id == null) return;
    final summary = _host.buildInProgressSummary();
    final entry = PausedTripEntry(
      id: id,
      vehicleId: _host.vehicleId,
      vin: _host.vin,
      summary: summary,
      odometerStartKm: _host.odometerStartKm,
      odometerLatestKm: _host.odometerLatestKm,
      pausedAt: _now(),
      // #1004 phase 4-WAL — flag persists so the launch-time recovery
      // service knows whether to bump the launcher-icon badge if the app
      // is killed before the grace timer fires.
      automatic: _host.automatic,
    );
    repo.save(entry);
  }

  /// Delete this session's row from the paused-trips box — the session
  /// is live again, so leaving the partial behind would let a later
  /// pause stomp the in-memory state. Best-effort.
  void clearPausedTripRow() {
    final id = _host.sessionId;
    if (id == null) return;
    _resolvePausedRepo()?.delete(id);
  }

  /// Grace-window auto-finalise (#797). Stops the scanner first so a
  /// late reconnect can't race an already-finalised trip, finalises the
  /// partial into the trip-history box, deletes the paused row, then
  /// flips the host into the stopped state.
  Future<void> _onGraceWindowElapsed() async {
    if (!_host.pausedDueToDrop) return;
    // Stop the scanner before finalising — otherwise a late reconnect
    // would race against an already-finalised trip.
    await stopReconnectScanner();
    final id = _host.sessionId;
    final repo = _resolvePausedRepo();
    final historyRepo = _resolveHistoryRepo();
    final summary = _host.buildFinalSummary();
    if (historyRepo != null && id != null) {
      try {
        await historyRepo.save(TripHistoryEntry(
          id: id,
          vehicleId: _host.vehicleId,
          summary: summary,
        ));
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.storage, e, st,
            context: const {
              'where': 'DroppedSessionManager grace finalise failed'
            }));
      }
    }
    if (repo != null && id != null) {
      await repo.delete(id);
    }
    _host.pausedDueToDrop = false;
    _host.stopped = true;
    _host.started = false;
    _graceTimer = null;
    _host.emitState();
  }

  PausedTripRepository? _resolvePausedRepo() {
    final override = _pausedRepoOverride;
    if (override != null) return override;
    if (!Hive.isBoxOpen(HiveBoxes.obd2PausedTrips)) return null;
    try {
      return PausedTripRepository(
        box: Hive.box<String>(HiveBoxes.obd2PausedTrips),
      );
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'DroppedSessionManager paused repo'}));
      return null;
    }
  }

  TripHistoryRepository? _resolveHistoryRepo() {
    final override = _historyRepoOverride;
    if (override != null) return override;
    if (!Hive.isBoxOpen(TripHistoryRepository.boxName)) return null;
    try {
      return TripHistoryRepository(
        box: Hive.box<String>(TripHistoryRepository.boxName),
      );
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'DroppedSessionManager history repo'}));
      return null;
    }
  }

  /// Cancel the grace timer + clear the drop reason — called by the
  /// controller's resume() before it clears the paused row and re-arms
  /// the detector. Scanner teardown stays the caller's job.
  void cancelGrace() {
    _graceTimer?.cancel();
    _graceTimer = null;
    _dropReason = null;
  }

  /// Tear down every pending timer + the silent-reconnect flag — called
  /// by the controller's stop(). Scanner teardown is awaited separately
  /// by stop() via [stopReconnectScanner].
  void cancelAllTimers() {
    _graceTimer?.cancel();
    _graceTimer = null;
    _silentReconnectTimer?.cancel();
    _silentReconnectTimer = null;
    _silentlyReconnecting = false;
  }

  /// Test seam: synchronously drive the grace-window finalisation path
  /// without waiting for the real timer. Plain (not `@visibleForTesting`)
  /// because the controller's own test-only `debugExpireGraceWindow`
  /// hook delegates here — mirroring `TripDistanceResolver`'s seam style.
  Future<void> expireGraceWindowNow() async {
    _graceTimer?.cancel();
    await _onGraceWindowElapsed();
  }
}
