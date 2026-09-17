// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/background_price_fetcher.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/features/alerts/background/alert_schedule_reconciler.dart';
import 'package:tankstellen/features/alerts/background/slc_wake_monitor.dart';

import '../../../helpers/silence_error_logger.dart';
import 'support/scan_phase_trace.dart';

class _Fetcher implements BackgroundPriceFetcher {
  _Fetcher({this.fail = false});
  final bool fail;
  final List<String> calls = [];

  @override
  Future<void> init() async {
    calls.add('init');
    if (fail) throw StateError('workmanager down');
  }

  @override
  Future<void> cancelAll() async {
    calls.add('cancelAll');
    if (fail) throw StateError('workmanager down');
  }

  @override
  Future<void> scheduleOpportunisticScan() async {}
}

class _Slc implements SlcWakeMonitor {
  final List<bool> calls = [];
  @override
  Future<void> setEnabled(bool enabled) async => calls.add(enabled);
}

/// #4162 — the one owner of the background schedule.
void main() {
  silenceErrorLoggerSpool();

  late _Fetcher fetcher;
  late _Slc slc;
  late List<String> order;

  setUp(() {
    fetcher = _Fetcher();
    slc = _Slc();
    order = [];
    BreadcrumbCollector.clear();
  });

  AlertScheduleReconciler build({
    required Future<bool> Function() gate,
    BackgroundPriceFetcher? withFetcher,
  }) =>
      AlertScheduleReconciler(
        gate: () {
          order.add('gate');
          return gate();
        },
        fetcher: () => withFetcher ?? fetcher,
        slc: () => slc,
        persistTemplates: () async => order.add('templates'),
      );

  test('the table: every phase has a row; unknown is left for good', () {
    expect(kAlertScheduleTransitions.keys.toSet(),
        AlertSchedulePhase.values.toSet());
    for (final e in kAlertScheduleTransitions.entries) {
      expect(e.value, isNot(contains(AlertSchedulePhase.unknown)),
          reason: '${e.key.name} → unknown');
    }
    expect(isAlertScheduleTransition(
            AlertSchedulePhase.armed, AlertSchedulePhase.armed),
        isTrue, reason: 're-arming is not a transition');
  });

  test('active: templates before register, then SLC on — the order '
      'BackgroundService.reconcile always had', () async {
    final schedule = build(gate: () async => true);
    await schedule.reconcile();
    expect(order, ['gate', 'templates']);
    expect(fetcher.calls, ['init']);
    expect(slc.calls, [true]);
    expect(schedule.phase, AlertSchedulePhase.armed);
    expect(schedule.debugApplies.single,
        (generation: 1, gate: ScheduleGateReading.active,
            result: AlertSchedulePhase.armed, cause: 'reconcile'));
  });

  test('inactive: cancel, SLC off, no templates', () async {
    final schedule = build(gate: () async => false);
    await schedule.reconcile();
    expect(order, ['gate']);
    expect(fetcher.calls, ['cancelAll']);
    expect(slc.calls, [false]);
    expect(schedule.phase, AlertSchedulePhase.cancelled);
  });

  test('sequential arm → cancel → arm is lawful', () async {
    var active = true;
    final schedule = build(gate: () async => active);
    await schedule.reconcile();
    active = false;
    await schedule.reconcile();
    active = true;
    await schedule.reconcile();
    expect(fetcher.calls, ['init', 'cancelAll', 'init']);
    expect(schedule.debugViolations, isEmpty);
  });

  test('boot re-arm reads the gate like every other apply (#4331)',
      () async {
    var active = false;
    final schedule = build(gate: () async => active);
    await schedule.bootRearm();
    active = true;
    await schedule.bootRearm();
    expect(fetcher.calls, ['cancelAll', 'init']);
    expect(order, ['gate', 'gate'],
        reason: 'no templates: the boot isolate has no settings box open');
    expect(slc.calls, isEmpty);
    expect(schedule.debugViolations, isEmpty);
    expect(BreadcrumbCollector.snapshot(), isEmpty);
  });

  test('boot re-arm prefers the isolate gate when one is given', () async {
    final seen = <String>[];
    final schedule = AlertScheduleReconciler(
      gate: () async => fail('the foreground gate needs open boxes'),
      bootGate: () async {
        seen.add('boot gate');
        return false;
      },
      fetcher: () => fetcher,
      slc: () => slc,
      persistTemplates: () async {},
    );
    await schedule.bootRearm();
    expect(seen, ['boot gate']);
    expect(fetcher.calls, ['cancelAll']);
  });

  test('the known-violation set stays within its ceiling', () {
    expect(kKnownScheduleViolations.length,
        lessThanOrEqualTo(kKnownScheduleViolationsCeiling));
  });

  test('never throws — a faulting gate, fetcher or boot register completes',
      () async {
    final faulty = build(gate: () async => throw StateError('box closed'));
    await expectLater(faulty.reconcile(), completes);
    expect(faulty.debugApplies.single.gate, ScheduleGateReading.unreadable);

    final brokenFetcher = _Fetcher(fail: true);
    final schedule =
        build(gate: () async => true, withFetcher: brokenFetcher);
    await expectLater(schedule.reconcile(), completes);
    await expectLater(schedule.bootRearm(), completes);
    expect(schedule.phase, AlertSchedulePhase.unknown,
        reason: 'nothing landed');
  });
}
