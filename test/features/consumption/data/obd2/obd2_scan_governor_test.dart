// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connect_trace.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connect_trace_log.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_scan_governor.dart';

/// #3185 — token-bucket tests for the process-wide scan governor. Fake clock
/// + injected wait, so nothing sleeps for real.
void main() {
  setUp(Obd2ConnectTraceLog.clear);
  tearDown(Obd2ConnectTraceLog.clear);

  ({
    Obd2ScanGovernor governor,
    List<Duration> waits,
    void Function(Duration) advance,
  }) build() {
    var now = DateTime(2026, 6, 10, 12);
    final waits = <Duration>[];
    final governor = Obd2ScanGovernor(
      now: () => now,
      wait: (d) async {
        waits.add(d);
        now = now.add(d); // the wall clock advances while we wait
      },
    );
    return (
      governor: governor,
      waits: waits,
      advance: (d) => now = now.add(d),
    );
  }

  test('the first 4 scan starts in a window are admitted without waiting',
      () async {
    final h = build();
    for (var i = 0; i < 4; i++) {
      await h.governor.admitScanStart(reason: 'test');
    }
    expect(h.waits, isEmpty);
    expect(h.governor.debugStartCount, 4);
    expect(h.governor.startsInWindow, 4);
  });

  test('the 5th start inside the window is DELAYED until the oldest token '
      'ages out (the Android 5-scans/30s throttle headroom)', () async {
    final h = build();
    await h.governor.admitScanStart(reason: 'seed');
    h.advance(const Duration(seconds: 5));
    for (var i = 0; i < 3; i++) {
      await h.governor.admitScanStart(reason: 'scan-$i');
    }
    expect(h.waits, isEmpty);

    await h.governor.admitScanStart(reason: 'user-retry');
    // The oldest token is 5 s old → the 5th start waits the remaining 25 s.
    expect(h.waits, [const Duration(seconds: 25)]);
    expect(h.governor.debugStartCount, 5);
  });

  test('tokens age out: after the window has fully passed, the bucket is '
      'fresh and nothing waits', () async {
    final h = build();
    for (var i = 0; i < 4; i++) {
      await h.governor.admitScanStart(reason: 'burst');
    }
    h.advance(const Duration(seconds: 31));
    for (var i = 0; i < 4; i++) {
      await h.governor.admitScanStart(reason: 'later');
    }
    expect(h.waits, isEmpty);
    expect(h.governor.startsInWindow, 4);
  });

  test('a throttled start stamps a scan-throttle step (with the reason) on '
      'the ACTIVE connect trace — throttle suspicion is visible in the field '
      'export', () async {
    final h = build();
    for (var i = 0; i < 4; i++) {
      await h.governor.admitScanStart(reason: 'burst');
    }
    final trace = Obd2ConnectTraceLog.beginTrace(
        origin: Obd2ConnectOrigin.firstConnect, mac: 'aa:bb');
    await h.governor.admitScanStart(reason: 'service-scan');
    trace.setOutcome(Obd2ConnectOutcome.success);
    Obd2ConnectTraceLog.endTrace(trace);

    final recorded = Obd2ConnectTraceLog.snapshot().first;
    final step =
        recorded.steps.firstWhere((s) => s.label == 'scan-throttle');
    expect(step.status, Obd2ConnectStepStatus.timeout);
    expect(step.detail, contains('service-scan'));
    expect(step.detail, contains('#3185'));
  });

  test('an UN-throttled start stamps nothing', () async {
    final h = build();
    final trace = Obd2ConnectTraceLog.beginTrace(
        origin: Obd2ConnectOrigin.firstConnect, mac: 'aa:bb');
    await h.governor.admitScanStart(reason: 'solo');
    trace.setOutcome(Obd2ConnectOutcome.success);
    Obd2ConnectTraceLog.endTrace(trace);
    final recorded = Obd2ConnectTraceLog.snapshot().first;
    expect(recorded.steps.where((s) => s.label == 'scan-throttle'), isEmpty);
  });

  test('FAULT INJECTION — a throwing wait seam fails OPEN: admitScanStart '
      'returns normally and the scan proceeds (never throws, #1103)',
      () async {
    final now = DateTime(2026, 6, 10, 12);
    final governor = Obd2ScanGovernor(
      now: () => now,
      wait: (_) async => throw StateError('injected wait fault'),
    );
    for (var i = 0; i < 4; i++) {
      await governor.admitScanStart(reason: 'burst');
    }
    // The 5th would wait — the wait throws — the governor must fail open.
    await expectLater(
        governor.admitScanStart(reason: 'throttled'), completes);
  });

  test('FAULT INJECTION — a throwing CLOCK seam also fails open', () async {
    final governor = Obd2ScanGovernor(
      now: () => throw StateError('injected clock fault'),
    );
    await expectLater(governor.admitScanStart(reason: 'any'), completes);
  });
}
