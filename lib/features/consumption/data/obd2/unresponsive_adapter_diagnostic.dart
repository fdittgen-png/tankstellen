// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/logging/error_logger.dart';
import 'obd2_connection_errors.dart';

/// Owns the "OBD2 adapter broadly unresponsive" diagnostic decision for
/// the [PidScheduler] (#2379 / #2524), extracted so the scheduler's
/// selection core stays under the 400-line cap (mirrors the
/// `PidSchedulerCommDiagnostics` split precedent).
///
/// The reclassification this enforces (#2524, matching the #2424/#2428
/// precedent): a known-unresponsive adapter must NOT spool a per-tick
/// ERROR. At most ONE real `errorLogger.log` ERROR is logged on the
/// TRANSITION into an unresponsive *episode* ([backoffThreshold]+ PIDs
/// backed off), gated by the episode latch AND a [window] rate limit.
/// While the episode persists every qualifying tick emits only a
/// `debugPrint` breadcrumb. The latch clears the moment enough PIDs
/// recover (the backed-off count drops below the threshold), so a
/// genuinely new outage logs a fresh ERROR.
class UnresponsiveAdapterDiagnostic {
  UnresponsiveAdapterDiagnostic({
    required int backoffThreshold,
    required Duration window,
    required DateTime Function() clock,
  })  : _backoffThreshold = backoffThreshold,
        _window = window,
        _clock = clock;

  final int _backoffThreshold;
  final Duration _window;
  final DateTime Function() _clock;

  bool _inEpisode = false;
  DateTime? _lastLoggedAt;

  /// Reset the episode latch + rate-limit window so a fresh outage can log a
  /// fresh ERROR. Called by [PidScheduler.resume] on reconnect (#2671): the
  /// pre-drop episode state must not suppress the diagnostic for a genuinely
  /// new outage on the recovered link.
  void reset() {
    _inEpisode = false;
    _lastLoggedAt = null;
  }

  /// Feed the per-tick failure outcome. [backedOffCount] is how many PIDs
  /// are currently backed off; [error]/[stack] are the failure that
  /// triggered this tick (logged only on a fresh episode transition).
  void onFailure(int backedOffCount, Object error, StackTrace stack) {
    // #2671 — a typed disconnect / not-connected error IS the drop itself,
    // not an "adapter unresponsive" episode. On a Classic-SPP flap every
    // write threw `PlatformException(state, not connected)` (category
    // `platform`) — exactly the field error. Logging it here spooled that
    // ERROR per drop. The drop is handled by the pause/reconnect path
    // (PidScheduler.pause + DroppedSessionManager), so skip it entirely and
    // do NOT touch the episode latch (a real timeout outage must still log).
    if (_isRecoverableDisconnect(error)) {
      debugPrint('UnresponsiveAdapterDiagnostic: skipping a recoverable '
          'disconnect — handled by the drop/reconnect path (#2671): $error');
      return;
    }
    if (backedOffCount < _backoffThreshold) {
      _inEpisode = false; // recovered — re-arm for the next outage
      return;
    }
    final msg = 'PidScheduler: OBD2 adapter unresponsive — '
        '$backedOffCount PIDs timing out';
    // Inside this episode → breadcrumb only, never a per-tick ERROR.
    if (_inEpisode) {
      debugPrint('$msg (still down)');
      return;
    }
    // Transition INTO the episode: one ERROR (rate-limited) for triage.
    _inEpisode = true;
    final now = _clock();
    final last = _lastLoggedAt;
    if (last != null && now.difference(last) < _window) {
      debugPrint('$msg (within diagnostic window; breadcrumb only)');
      return;
    }
    _lastLoggedAt = now;
    unawaited(errorLogger.log(ErrorLayer.other, error, stack,
        context: {'where': msg, 'backedOffPids': backedOffCount}));
  }

  /// True for an error that means "the link dropped" rather than "the
  /// adapter is broadly unresponsive" — the typed [Obd2DisconnectedException]
  /// the channels now raise, or a raw not-connected platform/state error
  /// (matched by message so this stays decoupled from `package:flutter`'s
  /// services library, mirroring `TripDropDetector._isTypedDisconnect`).
  static bool _isRecoverableDisconnect(Object error) {
    if (error is Obd2DisconnectedException) return true;
    final msg = error.toString().toLowerCase();
    return msg.contains('not connected') || msg.contains('transport closed');
  }
}
