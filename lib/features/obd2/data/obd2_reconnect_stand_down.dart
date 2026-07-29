// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' show Random;

/// #3603 — stand-down accounting for THE one reconnect owner
/// ([Obd2LinkSupervisor]).
///
/// Two field failure shapes motivated this, both from the 2026-07
/// connect-trace exports:
///
///  * **Identical-signature storms** — 20 consecutive liveReconnect
///    rfcommOpenFail ladder timeouts over 21 minutes at ~70 s cadence
///    (2026-07-24). The per-attempt bound (#3421) held, but nothing
///    above it stood down: N misses that fail the SAME way predict the
///    next attempt fails the same way too.
///  * **Success-flaps** (#3625's blind spot) — a dial that "succeeds"
///    but drops again within seconds proves nothing, yet it reset the
///    escalation forever; the corpse loop recorded a whole trip with
///    zero engine data at a ~4.7 s dial→adopt→drop cadence.
///
/// Once either streak reaches [threshold], the supervisor holds its
/// storm cadence instead of the fast ladder. The #3527 no-dead-end
/// invariant is untouched — the loop never self-terminates; it just
/// stops hammering a link that keeps failing identically. Positive
/// signals (user intent, wake, engine-off park, a signature change, a
/// ready that survives [flapWindow]) restore the fast ladder.
class ReconnectStandDown {
  ReconnectStandDown({required DateTime Function() now}) : _now = now;

  /// Consecutive identical failures (or flaps) before the loop stands
  /// down to the storm cadence.
  static const int threshold = 3;

  /// A ready that drops again within this window is a FLAP, not a
  /// recovery: it must not reset the escalation.
  static const Duration flapWindow = Duration(seconds: 30);

  final DateTime Function() _now;
  String? _lastMissSignature;
  int _missStreak = 0;
  DateTime? _readyAt;
  int _flapStreak = 0;

  /// True while either streak holds the loop at the storm cadence.
  bool get active =>
      _missStreak >= threshold || _flapStreak >= threshold;

  /// Breadcrumb payload naming WHY the loop stood down.
  String get detail => _flapStreak >= threshold
      ? 'flap x$_flapStreak'
      : '$_lastMissSignature x$_missStreak';

  /// A dial miss: `null` result or a fault. Identical signatures
  /// (failure runtime type; plain misses count as their own kind)
  /// accumulate; a change of signature restarts the streak at 1.
  void noteMiss(Object? failure) {
    final signature =
        failure == null ? 'miss' : failure.runtimeType.toString();
    if (signature == _lastMissSignature) {
      _missStreak++;
    } else {
      _lastMissSignature = signature;
      _missStreak = 1;
    }
  }

  /// A fresh ready: clears the miss streak and stamps the flap clock.
  /// The flap streak is deliberately NOT cleared here — a success that
  /// proves nothing must not reset the escalation; it clears when a
  /// ready SURVIVES [flapWindow] (checked at the next drop) or on a
  /// positive signal ([reset]).
  void noteReady() {
    _lastMissSignature = null;
    _missStreak = 0;
    _readyAt = _now();
  }

  /// A drop: flap accounting. A ready that died within [flapWindow] is
  /// a flap; one that survived the window proves the link works and
  /// clears the streak. Drops with no prior ready leave the streak
  /// unchanged (the miss streak owns that shape).
  void noteDrop() {
    final readyAt = _readyAt;
    _readyAt = null;
    if (readyAt == null) return;
    if (_now().difference(readyAt) < flapWindow) {
      _flapStreak++;
    } else {
      _flapStreak = 0;
    }
  }

  /// Positive signal (user intent, wake, park): back to the fast ladder.
  void reset() {
    _lastMissSignature = null;
    _missStreak = 0;
    _flapStreak = 0;
    _readyAt = null;
  }
}

/// The supervisor's retry cadence (#3527 ladder + #3603 storm hold):
/// doubling from [initial] to the [max] cap while healthy; a stand-down
/// jumps straight to [storm]. Jitter (0-12.5%) de-syncs the cadence
/// from the adapter's own advertising/settling rhythm (#3014).
class ReconnectBackoff {
  ReconnectBackoff({
    required this.initial,
    required this.max,
    required this.storm,
    required Random jitter,
  }) : _jitter = jitter;

  final Duration initial;
  final Duration max;
  final Duration storm;
  final Random _jitter;
  Duration _current = Duration.zero;
  bool _enteredStorm = false;
  int _stormAdvances = 0;

  /// #3642 — each consecutive storm-cadence advance means the previous
  /// held attempt STILL failed identically, so the hold lengthens:
  /// storm ×1 → ×3 → ×12 (5 → 15 → 60 min at the default). A parked car
  /// (adapter powered, ignition off, permanently in range) otherwise
  /// keeps a ~18% duty cycle of doomed ~67 s Bluetooth ladders running
  /// all day — the field shape behind the 2026-07-29 `[EXCESSIVE CPU
  /// USAGE]` process kill. Any positive signal ([reset], or a healthy
  /// ladder advance) restores the fast cadence.
  static const List<int> stormEscalation = [1, 3, 12];

  int get currentMs => _current.inMilliseconds;
  bool get atCap => _current >= max;

  /// True when the LAST [advance] crossed from the ladder into the
  /// storm hold — the caller breadcrumbs stand-down entry exactly once.
  bool get enteredStorm => _enteredStorm;

  void reset() {
    _current = Duration.zero;
    _stormAdvances = 0;
  }

  /// Grows the cadence and returns the wait including jitter.
  Duration advance({required bool standDown}) {
    _enteredStorm = standDown && _stormAdvances == 0;
    if (standDown) {
      final step = _stormAdvances >= stormEscalation.length
          ? stormEscalation.last
          : stormEscalation[_stormAdvances];
      _stormAdvances++;
      _current = storm * step;
    } else {
      _stormAdvances = 0;
      _current = _current == Duration.zero
          ? initial
          : _current * 2 > max
              ? max
              : _current * 2;
    }
    final jitterMs = _jitter.nextInt(1 + _current.inMilliseconds ~/ 8);
    return _current + Duration(milliseconds: jitterMs);
  }
}
