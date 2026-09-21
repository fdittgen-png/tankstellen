// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:collection';

import '../logging/app_log.dart';
import '../logging/error_logger.dart';
import '../telemetry/collectors/breadcrumb_collector.dart';
import 'scan_run_phase.dart';

/// One phase change or outcome [ScanRunGate] saw that [kScanRunTransitions]
/// or [kScanOutcomeFrom] does not allow (#4162). [outcome] is null for a
/// phase change.
typedef ScanRunViolation = ({
  ScanRunPhase from,
  ScanRunPhase? to,
  ScanOutcome? outcome,
});

/// The single door every scan-run phase change walks through (#4162).
///
/// Owned by `BackgroundAlertScanCoordinator`, which holds the current
/// phase; the gate only compares each change with the written-down
/// tables. Same discipline as the trip recording's phase gate:
///
/// * **Observe-only.** A change the tables forbid is recorded in
///   [debugViolations] (bounded) and left as a breadcrumb, and the scan
///   goes on. Refusing an edge nobody has watched in the field would turn
///   a surprising sequence into a scan that never finishes.
/// * **Observers are told after the check.** The optional
///   [ScanPhaseSink] receives every change, legal or not; a sink that
///   throws is logged and ignored.
///
/// Never throws: it sits on the path of every phase change, and a scan
/// that cannot report its phase must still release its lock.
class ScanRunGate {
  ScanRunGate({this._sink});

  final ScanPhaseSink? _sink;

  /// How many violations [debugViolations] keeps (newest win).
  static const int maxViolations = 16;

  final Queue<ScanRunViolation> _violations = Queue<ScanRunViolation>();

  /// The most recent illegal changes, oldest first.
  List<ScanRunViolation> get debugViolations =>
      List<ScanRunViolation>.unmodifiable(_violations);

  /// Report the change [from] → [to]. A change that keeps the phase is not
  /// reported.
  void change(ScanRunPhase from, ScanRunPhase to) {
    if (from == to) return;
    if (!isScanRunTransition(from, to)) {
      _record((from: from, to: to, outcome: null));
    }
    _notify(() => _sink?.onPhase(from, to));
  }

  /// Report that the run in [from] ended with [outcome].
  void end(ScanOutcome outcome, ScanRunPhase from) {
    if (!isScanOutcomeFrom(outcome, from)) {
      _record((from: from, to: null, outcome: outcome));
    }
    _notify(() => _sink?.onOutcome(outcome, from));
  }

  void _notify(void Function() call) {
    try {
      call();
    } catch (e, st) {
      log.warn('ScanRunGate: phase sink failed',
          error: e, stack: st, layer: ErrorLayer.background);
    }
  }

  void _record(ScanRunViolation violation) {
    _violations.addLast(violation);
    while (_violations.length > maxViolations) {
      _violations.removeFirst();
    }
    try {
      final edge = violation.to?.name ?? violation.outcome?.name;
      BreadcrumbCollector.add(
          'scan phase: illegal ${violation.from.name}→$edge');
    } catch (e, st) {
      // The breadcrumb is a courtesy to the next export; the violation is
      // already in the ring above, and the scan must go on.
      log.warn('ScanRunGate: breadcrumb failed',
          error: e, stack: st, layer: ErrorLayer.background);
    }
  }
}
