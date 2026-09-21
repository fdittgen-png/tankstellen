// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/scan_run_phase.dart';

/// #4162 — the scan run's written-down lifecycle.
void main() {
  test('every phase has a row in the transition table', () {
    expect(kScanRunTransitions.keys.toSet(), ScanRunPhase.values.toSet());
  });

  test('idle is reachable from every phase — the finally always runs', () {
    for (final phase in ScanRunPhase.values) {
      if (phase == ScanRunPhase.idle) continue;
      expect(isScanRunTransition(phase, ScanRunPhase.idle), isTrue,
          reason: '${phase.name} → idle');
    }
  });

  test('every phase is reachable from idle', () {
    final seen = {ScanRunPhase.idle};
    final frontier = [ScanRunPhase.idle];
    while (frontier.isNotEmpty) {
      for (final next in kScanRunTransitions[frontier.removeLast()]!) {
        if (seen.add(next)) frontier.add(next);
      }
    }
    expect(seen, ScanRunPhase.values.toSet());
  });

  test('every outcome has the phases it may end from, never idle', () {
    expect(kScanOutcomeFrom.keys.toSet(), ScanOutcome.values.toSet());
    for (final e in kScanOutcomeFrom.entries) {
      expect(e.value, isNotEmpty, reason: e.key.name);
      expect(e.value, isNot(contains(ScanRunPhase.idle)),
          reason: 'an outcome ends a RUN; idle has none');
    }
    expect(isScanOutcomeFrom(ScanOutcome.completed, ScanRunPhase.stamping),
        isTrue);
    expect(isScanOutcomeFrom(ScanOutcome.completed, ScanRunPhase.dispatching),
        isFalse,
        reason: 'a run is completed only once its cooldown is stamped');
  });

  test('the happy path is a chain of documented edges', () {
    const path = [
      ScanRunPhase.idle,
      ScanRunPhase.locking,
      ScanRunPhase.opening,
      ScanRunPhase.gated,
      ScanRunPhase.collecting,
      ScanRunPhase.dispatching,
      ScanRunPhase.refreshingWidgets,
      ScanRunPhase.stamping,
      ScanRunPhase.idle,
    ];
    for (var i = 1; i < path.length; i++) {
      expect(isScanRunTransition(path[i - 1], path[i]), isTrue,
          reason: '${path[i - 1].name} → ${path[i].name}');
    }
    expect(isScanRunTransition(ScanRunPhase.idle, ScanRunPhase.collecting),
        isFalse, reason: 'no scan body runs without the lock');
  });
}
