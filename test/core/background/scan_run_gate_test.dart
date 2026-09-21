// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/scan_run_gate.dart';
import 'package:tankstellen/core/background/scan_run_phase.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';

import '../../helpers/silence_error_logger.dart';

class _Sink implements ScanPhaseSink {
  _Sink({this.fail = false});
  final bool fail;
  final List<Object> seen = [];

  @override
  void onPhase(ScanRunPhase from, ScanRunPhase to) {
    if (fail) throw StateError('sink down');
    seen.add((from, to));
  }

  @override
  void onOutcome(ScanOutcome outcome, ScanRunPhase from) {
    if (fail) throw StateError('sink down');
    seen.add(outcome);
  }
}

/// #4162 — the door every scan-run phase change walks through.
void main() {
  silenceErrorLoggerSpool();

  setUp(BreadcrumbCollector.clear);
  tearDown(() => BreadcrumbCollector.onAdd = null);

  test('a documented change reaches the sink and records nothing', () {
    final sink = _Sink();
    final gate = ScanRunGate(sink: sink)
      ..change(ScanRunPhase.idle, ScanRunPhase.locking)
      ..end(ScanOutcome.skippedLock, ScanRunPhase.locking);
    expect(sink.seen,
        [(ScanRunPhase.idle, ScanRunPhase.locking), ScanOutcome.skippedLock]);
    expect(gate.debugViolations, isEmpty);
    expect(BreadcrumbCollector.snapshot(), isEmpty);
  });

  test('observe-only: an illegal change is recorded AND still reported', () {
    final sink = _Sink();
    final gate = ScanRunGate(sink: sink)
      ..change(ScanRunPhase.idle, ScanRunPhase.dispatching)
      ..end(ScanOutcome.completed, ScanRunPhase.collecting);
    expect(gate.debugViolations, [
      (from: ScanRunPhase.idle, to: ScanRunPhase.dispatching, outcome: null),
      (from: ScanRunPhase.collecting, to: null, outcome: ScanOutcome.completed),
    ]);
    expect(sink.seen, hasLength(2));
    expect(BreadcrumbCollector.snapshot().first.action,
        'scan phase: illegal idle→dispatching');
  });

  test('a change that keeps the phase is not reported', () {
    final sink = _Sink();
    ScanRunGate(sink: sink).change(ScanRunPhase.gated, ScanRunPhase.gated);
    expect(sink.seen, isEmpty);
  });

  test('the violation ring is bounded, newest kept', () {
    final gate = ScanRunGate();
    for (var i = 0; i < ScanRunGate.maxViolations + 5; i++) {
      gate.change(ScanRunPhase.stamping, ScanRunPhase.locking);
    }
    expect(gate.debugViolations, hasLength(ScanRunGate.maxViolations));
  });

  test('never throws — not with a failing sink, not with a failing '
      'breadcrumb sink, for any pair', () {
    BreadcrumbCollector.onAdd = () => throw StateError('persistence down');
    final gate = ScanRunGate(sink: _Sink(fail: true));
    for (final from in ScanRunPhase.values) {
      for (final to in ScanRunPhase.values) {
        expect(() => gate.change(from, to), returnsNormally,
            reason: '${from.name}→${to.name}');
      }
      for (final outcome in ScanOutcome.values) {
        expect(() => gate.end(outcome, from), returnsNormally);
      }
    }
  });
}
