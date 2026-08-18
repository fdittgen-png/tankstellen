// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;

/// #3421 — post-close COOLDOWN for Classic RFCOMM re-opens (the #3404
/// micro-lever).
///
/// An ELM327 adapter's single SPP channel is not released the instant the
/// socket closes: a connect dialled back-to-back after a close/drop lands on
/// the still-held channel and either blocks (the #3346 hang the per-rung
/// watchdog now aborts) or burns a doomed ladder rung. Field evidence
/// (#3415): `ble.connect.attempts` hit 1479 in one day with connect traces
/// 0–1 ms apart. A 1.5 s minimum gap between a close/drop and the next
/// connect to the SAME mac gives the adapter time to release its channel.
///
/// Ownership: `ClassicElmChannel` stamps [noteClosed] on every deliberate
/// `close()` of a live link and on every unexpected drop edge, and awaits
/// [awaitReadyToConnect] at the top of `open()` — reducing the native
/// connect budget by the time waited, so the cooldown is counted INSIDE the
/// #3421 whole-ladder budget. State is per-mac and lives in the process-wide
/// [instance] because reconnect episodes create a fresh short-lived channel
/// object per attempt; the cooldown must survive across them.
class ClassicConnectCooldown {
  ClassicConnectCooldown({
    this.gap = const Duration(milliseconds: 1500),
    DateTime Function()? now,
    Future<void> Function(Duration)? wait,
  })  : _now = now ?? DateTime.now,
        _wait = wait ?? _realWait;

  static Future<void> _realWait(Duration d) => Future<void>.delayed(d);

  /// The single process-wide instance production wires (see the class doc:
  /// per-mac state must outlive the short-lived channel objects). Tests
  /// inject fresh instances with a fake clock + wait so nothing sleeps.
  static final ClassicConnectCooldown instance = ClassicConnectCooldown();

  /// Minimum gap between a close/drop and the next connect to the same mac.
  /// 1.5 s sits inside the 1–2 s window #3421 specifies: long enough for a
  /// clone to release its RFCOMM channel, short enough that a healthy
  /// close→reopen (user retry, transport open-retry) is barely delayed.
  final Duration gap;

  final DateTime Function() _now;
  final Future<void> Function(Duration) _wait;

  final Map<String, DateTime> _lastClosedAt = {};

  /// Stamp "the socket to [mac] just closed/dropped". Later stamps win.
  void noteClosed(String mac) {
    _lastClosedAt[_key(mac)] = _now();
  }

  /// Test-only: drop every per-mac stamp, so a suite exercising the REAL
  /// channels against the shared [instance] doesn't inherit a prior test's
  /// close stamp (and its up-to-1.5 s real-clock wait) across test cases.
  @visibleForTesting
  void debugClear() => _lastClosedAt.clear();

  /// Wait out whatever remains of [gap] since the last [noteClosed] for
  /// [mac]. Returns the duration actually waited (zero when no close is on
  /// record, the gap already elapsed, or the clock went backwards) so the
  /// caller can subtract it from the native connect budget. Never throws —
  /// cooldown bookkeeping (the injected clock/wait seams) failing must never
  /// abort a connect that would otherwise run; it fails open to
  /// [Duration.zero].
  Future<Duration> awaitReadyToConnect(String mac) async {
    try {
      final last = _lastClosedAt[_key(mac)];
      if (last == null) return Duration.zero;
      final since = _now().difference(last);
      // A negative delta means the clock jumped backwards — treat it as
      // "gap elapsed" rather than sleeping for a bogus long remainder.
      if (since.isNegative || since >= gap) return Duration.zero;
      final remaining = gap - since;
      await _wait(remaining);
      return remaining;
    } catch (e, st) {
      // Fail OPEN (see the never-throws contract above): the connect
      // proceeds without the cooldown at worst — exactly the pre-#3421
      // behaviour.
      debugPrint('ClassicConnectCooldown: awaitReadyToConnect failed open '
          '(connect proceeds): $e\n$st');
      return Duration.zero;
    }
  }

  static String _key(String mac) => mac.toUpperCase();
}
