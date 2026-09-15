// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math' as math;

/// #4196 (Epic #4195) — a reattach is an ADOPTION, not a recovery.
///
/// The reattach source proves adoption with an `ATRV` round-trip
/// (#3915). The ELM chip answers that on its own, with the vehicle bus
/// dead, so it proves the adapter — never the car. Before #4196 the
/// drop manager cleared `degradedGpsOnly` and journaled `leftDegraded`
/// on that proof alone: the UI claimed full OBD2, and a bus that stayed
/// silent fell into drop → fresh instance → "recovered" → drop, with the
/// cycle breaker reset by every fresh instance.
///
/// This holds the verdict's state: after an adoption the trip stays
/// GPS-only while polling resumes, and only a fresh engine parse
/// ([verify]) completes the recovery. A link that delivers none within
/// the window fires the unverified callback so the manager hands it
/// back. The window stretches with each consecutive unverified adoption
/// (capped at 4×), so a bus that never answers costs one dial every few
/// minutes, never a storm.
class RecoveryVerifier {
  RecoveryVerifier({this.baseWindow = defaultWindow});

  /// Covers the 8 s reconnect grace, a ~17 s quiet-window protocol
  /// search and the 15 s staleness fence.
  static const Duration defaultWindow = Duration(seconds: 45);

  final Duration baseWindow;
  Timer? _timer;
  bool _awaiting = false;
  int _unverifiedStreak = 0;

  /// True between an adoption and its verdict.
  bool get awaiting => _awaiting;

  /// Consecutive adoptions that delivered no engine data.
  int get unverifiedStreak => _unverifiedStreak;

  /// The window the NEXT adoption gets.
  Duration get nextWindow =>
      baseWindow * (1 + math.min(_unverifiedStreak, 3));

  /// Arm a verdict for a fresh adoption; returns its window.
  Duration begin(void Function() onUnverified) {
    final window = nextWindow;
    cancel();
    _awaiting = true;
    _timer = Timer(window, () {
      _timer = null;
      if (!_awaiting) return;
      _awaiting = false;
      _unverifiedStreak++;
      onUnverified();
    });
    return window;
  }

  /// A fresh engine parse. True when it completed a pending verdict.
  bool verify() {
    if (!_awaiting) return false;
    cancel();
    _unverifiedStreak = 0;
    return true;
  }

  /// Drop any pending verdict (trip stopped / escalated).
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _awaiting = false;
  }
}
