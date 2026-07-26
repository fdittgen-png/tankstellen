// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

/// Trailing-edge debouncer (#3614) — replaces the hand-rolled
/// `Timer? _debounce; _debounce?.cancel(); _debounce = Timer(…)` pattern
/// the type-ahead / validation widgets each copied.
///
/// [call] (re)schedules [action] to run after [duration]; a call while a
/// previous action is still pending cancels the pending one, so only the
/// last action within a burst fires. [cancel] drops any pending action;
/// [dispose] is an alias for use in `State.dispose`.
///
/// No `mounted` handling — callers guard inside their action exactly as
/// they did with the raw Timer.
class Debouncer {
  Debouncer({required this.duration});

  /// The quiet window an action must survive before it runs.
  final Duration duration;

  Timer? _timer;

  /// Whether an action is scheduled and has not fired yet.
  bool get isPending => _timer?.isActive ?? false;

  /// Schedule [action] to run after [duration], cancelling any pending
  /// action from a previous call.
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Drop the pending action, if any.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Cancel any pending action. Call from `State.dispose`.
  void dispose() => cancel();
}
