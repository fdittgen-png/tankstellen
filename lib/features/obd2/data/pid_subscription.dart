// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'scheduled_pid.dart';

/// One subscribed PID in the [PidScheduler] rotation (#814 / #2379).
///
/// Extracted from `pid_scheduler.dart` so the scheduler's selection core
/// stays under the 400-line cap (#2671), mirroring the
/// `UnresponsiveAdapterDiagnostic` / `PidSchedulerCommDiagnostics` splits.
/// Pure data + the [isBackedOff] derivation; the scheduler owns all timing.
class PidSubscription {
  PidSubscription({
    required this.command,
    required this.config,
    required this.onResult,
    required this.order,
    required this.maxConsecutiveFailures,
  });

  /// The OBD-II command this subscription polls (e.g. `'010C'`). Kept so
  /// the governor can address demotions by command without a reverse map.
  final String command;

  final ScheduledPid config;
  final void Function(String response) onResult;

  /// Monotonic subscription index used for FIFO tie-breaking.
  final int order;

  /// Consecutive failures before the PID is considered backed off (#2379).
  final int maxConsecutiveFailures;

  /// Consecutive transport failures since the last successful read. Reset
  /// to 0 on any success. Drives the [isBackedOff] state (#2379).
  int consecutiveFailures = 0;

  /// True once this PID has failed [maxConsecutiveFailures] times in a row —
  /// it is then selected at the slow backoff rate until it next answers.
  bool get isBackedOff => consecutiveFailures >= maxConsecutiveFailures;
}
