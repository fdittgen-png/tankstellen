// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logging/error_logger.dart';
import 'tanksync_init.dart';

/// #3450 — background retries for a failed / timed-out TankSync launch
/// init.
///
/// The launch flow gives Supabase 8 seconds and then paints on without
/// sync — previously *for the rest of the app session*: a flaky-network
/// cold start silently ran offline until the next process launch. This
/// scheduler retries in the background (30 s → 5 min backoff, max
/// [maxAttempts]) and also fires on app resume (the free execution window
/// the #3447 resume hook already owns). A late success runs [onReady] —
/// the launch pull pass — so the session heals without user action.
///
/// Terminal outcomes stop the ladder: `ready` (run [onReady]),
/// `relinkRequired` (run [onRelinkRequired] — retrying can never conjure
/// a session, #3449) and `notConfigured`.
class TankSyncInitRetry {
  TankSyncInitRetry._();

  /// App-wide singleton, mirroring the other core-sync coordinators.
  static final TankSyncInitRetry instance = TankSyncInitRetry._();

  /// Backoff ladder: 30 s → 5 min, five attempts total (#3450).
  static const List<Duration> backoff = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
    Duration(minutes: 4),
    Duration(minutes: 5),
  ];

  static int get maxAttempts => backoff.length;

  Future<TankSyncInitOutcome> Function()? _attempt;
  Future<void> Function()? _onReady;
  void Function()? _onRelinkRequired;
  Timer? _timer;
  int _attemptsMade = 0;
  bool _firing = false;

  /// Whether a retry is still armed (timer pending or attempts left).
  bool get pending => _attempt != null;

  @visibleForTesting
  int get attemptsMade => _attemptsMade;

  /// Arm the ladder after a failed/timed-out launch init. [attempt] re-runs
  /// the init (bounded by its own timeout); [onReady] runs the launch pull
  /// pass on a late success; [onRelinkRequired] surfaces the #3449 state if
  /// a retry discovers it. Re-arming resets the ladder.
  void arm({
    required Future<TankSyncInitOutcome> Function() attempt,
    required Future<void> Function() onReady,
    void Function()? onRelinkRequired,
  }) {
    _timer?.cancel();
    _attempt = attempt;
    _onReady = onReady;
    _onRelinkRequired = onRelinkRequired;
    _attemptsMade = 0;
    _scheduleNext();
  }

  /// App-resume hook (#3447/#3450): if a retry is pending, fire it NOW
  /// instead of waiting out the backoff — the user just gave us a live
  /// foreground window, likely with network back.
  Future<void> retryNowIfPending() async {
    if (!pending) return;
    _timer?.cancel();
    await _fire();
  }

  /// Cancel everything — used on terminal outcomes and by tests.
  void disarm() {
    _timer?.cancel();
    _timer = null;
    _attempt = null;
    _onReady = null;
    _onRelinkRequired = null;
    _attemptsMade = 0;
    _firing = false;
  }

  void _scheduleNext() {
    if (_attemptsMade >= maxAttempts) {
      disarm();
      return;
    }
    _timer?.cancel();
    _timer = Timer(backoff[_attemptsMade], () => unawaited(_fire()));
  }

  Future<void> _fire() async {
    final attempt = _attempt;
    if (attempt == null || _firing) return;
    _firing = true;
    _attemptsMade++;
    try {
      final outcome = await attempt();
      switch (outcome) {
        case TankSyncInitOutcome.ready:
          final onReady = _onReady;
          disarm();
          if (onReady != null) await onReady();
        case TankSyncInitOutcome.relinkRequired:
          final onRelink = _onRelinkRequired;
          disarm();
          onRelink?.call();
        case TankSyncInitOutcome.notConfigured:
          disarm();
        case TankSyncInitOutcome.failed:
          _firing = false;
          _scheduleNext();
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.sync, e, st, context: {
        'where': 'TankSyncInitRetry attempt failed',
        'attempt': _attemptsMade,
      }));
      _firing = false;
      _scheduleNext();
    } finally {
      _firing = false;
    }
  }
}
