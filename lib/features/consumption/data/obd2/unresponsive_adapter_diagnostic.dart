// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/logging/error_logger.dart';

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

  /// Feed the per-tick failure outcome. [backedOffCount] is how many PIDs
  /// are currently backed off; [error]/[stack] are the failure that
  /// triggered this tick (logged only on a fresh episode transition).
  void onFailure(int backedOffCount, Object error, StackTrace stack) {
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
}
