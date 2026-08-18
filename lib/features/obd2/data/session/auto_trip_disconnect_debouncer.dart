// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import '../../../../core/logging/error_logger.dart';
import '../auto_record_trace_log.dart';

/// Disconnect-debounce/save tail of the auto-record state machine
/// (#3727 — extracted from `AutoTripCoordinator`, zero behavior
/// change).
///
/// Owns the disconnect-save `Timer` end-to-end: arming it on
/// `AdapterDisconnected`, cancelling it on reconnect, and — when it
/// fires with a trip still active — invoking the automatic stop-and-
/// save bridge. The coordinator keeps the trip-active flag and reaches
/// it through callbacks (primitives and closures only, per the
/// feature-boundary rule).
class AutoTripDisconnectDebouncer {
  /// MAC address of the paired adapter — `AutoRecordConfig.mac`,
  /// threaded into every trace event.
  final String mac;

  /// Debounce window before a disconnect triggers `stopAndSave` —
  /// `AutoRecordConfig.disconnectSaveDelay`.
  final Duration disconnectSaveDelay;

  /// Bridge to `TripRecording.stopAndSaveAutomatic` — the
  /// coordinator's field of the same name, passed through unchanged.
  final Future<void> Function() stopAndSaveAutomatic;

  /// Clock seam — the coordinator's injected `now`.
  final DateTime Function() now;

  /// Reads the coordinator's trip-active flag when the timer fires.
  final bool Function() isTripActive;

  /// Clears the coordinator's trip-active flag just before the
  /// automatic save is invoked.
  final void Function() clearTripActive;

  Timer? _timer;

  AutoTripDisconnectDebouncer({
    required this.mac,
    required this.disconnectSaveDelay,
    required this.stopAndSaveAutomatic,
    required this.now,
    required this.isTripActive,
    required this.clearTripActive,
  });

  /// Whether the disconnect-save timer is currently armed.
  bool get isPending => _timer?.isActive ?? false;

  /// Arm the debounce. A reconnect within `disconnectSaveDelay`
  /// cancels it and the trip carries on; otherwise the timer fires
  /// and we save.
  void arm() {
    _timer?.cancel();
    _timer = Timer(disconnectSaveDelay, _onSaveTimerFired);
    AutoRecordTraceLog.add(
      AutoRecordEventKind.disconnectTimerStarted,
      mac: mac,
      detail: 'delaySec=${disconnectSaveDelay.inSeconds} '
          'delayMs=${disconnectSaveDelay.inMilliseconds}',
    );
  }

  /// Reconnect within the disconnect-save window: cancel the timer
  /// and let the existing trip continue (traced). No-op when no timer
  /// is pending.
  void cancelIfPending() {
    if (_timer?.isActive ?? false) {
      _timer!.cancel();
      _timer = null;
      AutoRecordTraceLog.add(
        AutoRecordEventKind.disconnectTimerCancelled,
        mac: mac,
      );
    }
  }

  /// Silent cancel for coordinator tear-down (`stop()`) — no trace,
  /// matching the original inline `_disconnectTimer?.cancel()`.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void _onSaveTimerFired() {
    final firedAt = now();
    _timer = null;
    AutoRecordTraceLog.add(
      AutoRecordEventKind.disconnectTimerFired,
      mac: mac,
      detail: 'tripActive=${isTripActive()}',
    );
    if (!isTripActive()) {
      // Edge case: connect, no movement detected, disconnect, timer
      // fires. Nothing to save. Stay idle and let the next connect
      // start the cycle over.
      return;
    }
    clearTripActive();
    unawaited(_invokeStopAndSave(firedAt));
  }

  Future<void> _invokeStopAndSave(DateTime firedAt) async {
    try {
      await stopAndSaveAutomatic();
      AutoRecordTraceLog.add(
        AutoRecordEventKind.tripSavedAuto,
        mac: mac,
        detail: 'firedAt=${firedAt.toIso8601String()}',
      );
    } catch (e, st) {
      AutoRecordTraceLog.add(
        AutoRecordEventKind.tripSaveFailed,
        mac: mac,
        detail: 'exception=$e',
      );
      await errorLogger.log(
        ErrorLayer.background,
        e,
        st,
        context: <String, Object?>{
          'phase': 'AutoTripCoordinator.stopAndSaveAutomatic',
          'mac': mac,
          'firedAt': firedAt.toIso8601String(),
        },
      );
    }
  }
}
