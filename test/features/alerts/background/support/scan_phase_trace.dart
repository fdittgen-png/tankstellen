// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/scan_run_phase.dart';
import 'package:tankstellen/features/alerts/background/alert_schedule_reconciler.dart';

/// One observed phase change of a scan run.
typedef ScanEdge = (ScanRunPhase from, ScanRunPhase to);

/// A lifecycle defect a scan run can show that is not a single illegal
/// edge (#4162).
enum ScanAnomaly {
  /// B3 (#4333) — a second isolate of the same process acquired the Hive
  /// lock while a scan held it.
  concurrentScan,

  /// B4 (#4333) — a run that started left no journal row after a kill.
  unjournaledRun,
}

/// Scan phase changes the app is KNOWN to make although
/// [kScanRunTransitions] forbids them. None today: every writer is the
/// coordinator, and the table was written from it.
const Set<ScanEdge> kKnownIllegalScanEdges = {};

/// Scan-run defects that reproduce today, each a filed issue. The fix
/// removes its entry, and [kKnownScanAnomaliesCeiling] goes down with it.
const Set<ScanAnomaly> kKnownScanAnomalies = {
  ScanAnomaly.concurrentScan, // #4333 B3
  ScanAnomaly.unjournaledRun, // #4333 B4
};

/// The size [kKnownScanAnomalies] may never exceed. Lower it with every fix.
const int kKnownScanAnomaliesCeiling = 2;

/// Schedule applies that break the reconciler's invariant today, each a
/// filed issue (#4162). The fix removes its entry.
const Set<ScheduleViolation> kKnownScheduleViolations = {
  ScheduleViolation.bootRearmWithoutGate, // #4331 B1
  ScheduleViolation.staleArmAfterCancel, // #4332 B2
};

/// The size [kKnownScheduleViolations] may never exceed.
const int kKnownScheduleViolationsCeiling = 2;

/// Records every phase change and outcome of the runs it is the sink of,
/// and lets a test act at an exact edge.
class ScanPhaseTrace implements ScanPhaseSink {
  ScanPhaseTrace({this.onEdge});

  /// Called after each recorded change — where a kill test captures.
  final void Function(ScanEdge edge)? onEdge;

  final List<ScanEdge> edges = [];
  final List<(ScanOutcome, ScanRunPhase)> outcomes = [];

  @override
  void onPhase(ScanRunPhase from, ScanRunPhase to) {
    edges.add((from, to));
    onEdge?.call((from, to));
  }

  @override
  void onOutcome(ScanOutcome outcome, ScanRunPhase from) =>
      outcomes.add((outcome, from));

  /// The phases visited, in order, starting from `idle`.
  List<ScanRunPhase> get path => [
        if (edges.isNotEmpty) edges.first.$1,
        for (final e in edges) e.$2,
      ];

  /// Every observed change the table does not allow.
  List<ScanEdge> get illegal => [
        for (final e in edges)
          if (!isScanRunTransition(e.$1, e.$2)) e,
      ];

  /// Fails on any illegal change or outcome that is not a known defect.
  void expectLawful() {
    final unexplained = [
      for (final e in illegal)
        if (!kKnownIllegalScanEdges.contains(e)) e,
    ];
    expect(unexplained, isEmpty,
        reason: 'scan phase changes outside kScanRunTransitions: '
            '${unexplained.map((e) => '${e.$1.name}→${e.$2.name}').join(', ')}'
            ' (path: ${path.map((p) => p.name).join('→')})');
    for (final (outcome, from) in outcomes) {
      expect(isScanOutcomeFrom(outcome, from), isTrue,
          reason: '${outcome.name} recorded from ${from.name}');
    }
  }
}

/// Fails when [observed] holds an anomaly that is not a known defect.
void expectOnlyKnownAnomalies(Iterable<ScanAnomaly> observed) {
  final unexplained = observed.toSet().difference(kKnownScanAnomalies);
  expect(unexplained, isEmpty,
      reason: 'scan anomalies that are not a filed, known defect');
}

/// Fails when [observed] holds a schedule violation that is not a known
/// defect.
void expectOnlyKnownScheduleViolations(Iterable<ScheduleViolation> observed) {
  final unexplained = observed.toSet().difference(kKnownScheduleViolations);
  expect(unexplained, isEmpty,
      reason: 'schedule violations that are not a filed, known defect');
}
