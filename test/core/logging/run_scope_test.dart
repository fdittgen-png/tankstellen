// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/run_scope.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';

/// #3980 — the ADR 0021 runId is carried by the Zone, so it reaches a
/// failure any number of awaits deep without being threaded through
/// signatures — and breadcrumbs pick it up the same way.
void main() {
  setUp(() {
    RunScope.resetForTest();
    BreadcrumbCollector.clear();
  });

  test('no id outside a run', () {
    expect(RunScope.currentId, isNull);
  });

  test('the id survives awaits and names its kind', () async {
    String? seen;
    await RunScope.run('search', () async {
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      seen = RunScope.currentId;
    });
    expect(seen, startsWith('search-1-'));
    expect(RunScope.currentId, isNull, reason: 'the scope ends with the run');
  });

  test('nested and sibling runs get distinct ids', () async {
    String? outer, inner, sibling;
    await RunScope.run('background-scan', () async {
      outer = RunScope.currentId;
      await RunScope.run('search', () async => inner = RunScope.currentId);
    });
    await RunScope.run('export', () async => sibling = RunScope.currentId);
    expect({outer, inner, sibling}, hasLength(3));
  });

  test('a breadcrumb inside a run carries the runId, area and level',
      () async {
    await RunScope.run('ocr', () async {
      BreadcrumbCollector.add('OBD2 link drop', detail: 'x', level: 'warn');
    });
    final crumb = BreadcrumbCollector.snapshot().single;
    expect(crumb.runId, startsWith('ocr-'));
    expect(crumb.area, 'obd2');
    expect(crumb.level, 'warn');
  });

  test('area derives from the leading token unless given', () {
    expect(BreadcrumbCollector.areaOf('bt.teardown_fail'), 'bt');
    expect(BreadcrumbCollector.areaOf('trip tile action'), 'trip');
    expect(BreadcrumbCollector.areaOf('sync'), 'sync');
    BreadcrumbCollector.add('widget-launch-probe-timeout', area: 'home_widget');
    expect(BreadcrumbCollector.snapshot().single.area, 'home_widget');
    expect(BreadcrumbCollector.snapshot().single.level, 'info');
  });
}
