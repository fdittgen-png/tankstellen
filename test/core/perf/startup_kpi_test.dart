// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/perf/perf_budgets.dart';
import 'package:tankstellen/core/perf/startup_kpi.dart';
import 'package:tankstellen/core/perf/startup_timer.dart';

/// #4140 — the time-to-useful-map KPI.
///
/// The interesting assertions here are the ones about ABSENCE. A launch
/// that never puts a price on screen has no KPI, and the two ways to get
/// that wrong (report `0`, or report a number anchored to a timer that
/// never started) both produce a trace that reads as a fast launch.
void main() {
  setUp(() {
    StartupKpi.reset();
    StartupTimer.instance.reset();
  });

  tearDown(() {
    StartupKpi.reset();
    StartupTimer.instance.reset();
  });

  testWidgets('unknown before a price-bearing frame has painted',
      (tester) async {
    StartupTimer.instance.start();
    expect(StartupKpi.value,
        const DataValue<Duration>.unknown(
            reason: DataUnknownReason.notMeasuredYet));
    expect(StartupKpi.isWithinBudget.isKnown, isFalse,
        reason: 'a launch with no price on screen has neither met the '
            'budget nor missed it');
  });

  testWidgets('declines to record when no launch was ever timed',
      (tester) async {
    // No StartupTimer.start() — a widget test, a background isolate, any
    // binding that did not come up through AppInitializer.
    await tester.pumpWidget(const _MarksOnBuild());
    expect(StartupKpi.value.isKnown, isFalse,
        reason: 'anchoring to a timer that never started would report a '
            'launch that never happened, and it would report it as fast');
    expect(StartupTimer.instance.spans, isEmpty);
  });

  testWidgets('records once a frame has painted, and publishes the span',
      (tester) async {
    StartupTimer.instance.start();
    await tester.pumpWidget(const _MarksOnBuild());

    expect(_MarksOnBuild.knownDuringBuild, isFalse,
        reason: 'the caller is still BUILDING the frame; the KPI is '
            'about the frame being on screen');

    final recorded = StartupKpi.value;
    expect(recorded, isA<Measured<Duration>>());
    expect(recorded.valueOrNull!.inMilliseconds, greaterThanOrEqualTo(0));

    final spans = StartupTimer.instance.spans;
    expect(spans.map((s) => s.name), contains(StartupKpi.spanName));
    final span = spans.firstWhere((s) => s.name == StartupKpi.spanName);
    expect(span.startMs, 0,
        reason: 'the KPI is measured from launch, so its span starts at '
            'the origin of the same timeline the phases are on');
    expect(span.endMs, recorded.valueOrNull!.inMilliseconds);
  });

  testWidgets('survives finish() — the KPI lands AFTER the first frame',
      (tester) async {
    // This is the whole reason the KPI is not a milestone: `mark()` is a
    // no-op once the stopwatch stops, and it stops at `first_frame`.
    StartupTimer.instance.start();
    StartupTimer.instance.mark('first_frame');
    StartupTimer.instance.finish();

    StartupTimer.instance.mark('useful_map_as_a_milestone');
    expect(StartupTimer.instance.milestones.map((m) => m.name),
        isNot(contains('useful_map_as_a_milestone')),
        reason: 'if this ever starts passing, mark() became usable after '
            'finish() and the KPI could be a plain milestone again');

    await tester.pumpWidget(const _MarksOnBuild());
    expect(StartupKpi.value.isKnown, isTrue);
  });

  testWidgets('idempotent — a later frame does not move the number',
      (tester) async {
    StartupTimer.instance.start();
    await tester.pumpWidget(const _MarksOnBuild());
    final first = StartupKpi.value.valueOrNull;

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const _MarksOnBuild(rebuild: true));

    expect(_MarksOnBuild.knownDuringBuild, isTrue,
        reason: 'the second build must actually have RUN — otherwise '
            'this test asserts idempotency of a call that never happened');
    expect(StartupKpi.value.valueOrNull, first);
    expect(
        StartupTimer.instance.spans
            .where((s) => s.name == StartupKpi.spanName)
            .length,
        1);
  });

  group('budget', () {
    test('the ceiling is inclusive', () {
      final limit = kColdStartBudget.limit!.toInt();
      expect(StartupKpi.withinBudget(Duration(milliseconds: limit)), isTrue,
          reason: 'a budget is the worst acceptable number, not the '
              'first unacceptable one');
      expect(StartupKpi.withinBudget(Duration(milliseconds: limit + 1)),
          isFalse);
    });

    test('the KPI does not restate the ceiling', () {
      // One place, so a revised budget cannot disagree with itself.
      final source =
          File('lib/core/perf/startup_kpi.dart').readAsStringSync();
      expect(source, isNot(contains('2500')));
      expect(source, contains('kColdStartBudget'));
    });
  });

  group('export row', () {
    test('states the absence rather than filling it with a zero', () {
      final row = StartupKpi.exportRow();
      expect(row['ms'], isNull);
      expect(row.containsKey('ms'), isFalse,
          reason: 'omitted, not null-filled — the same rule slowestBoxOpen '
              'follows');
      expect(row['unknownReason'], DataUnknownReason.notMeasuredYet.name);
      expect(row.containsKey('withinBudget'), isFalse);
      expect(row['budgetMs'], kColdStartBudget.limit,
          reason: 'the ceiling travels with the measurement even when '
              'there is no measurement');
      expect(row['definition'], StartupKpi.definition);
    });

    testWidgets('carries the number and the verdict once known',
        (tester) async {
      StartupTimer.instance.start();
      await tester.pumpWidget(const _MarksOnBuild());

      final row = StartupKpi.exportRow();
      expect(row['ms'], StartupKpi.value.valueOrNull!.inMilliseconds);
      expect(row['withinBudget'], isTrue);
      expect(row.containsKey('unknownReason'), isFalse);
    });
  });
}

/// The real call shape: a widget that marks the KPI while BUILDING the
/// frame that carries the price. Calling [StartupKpi.markUsefulMap] from
/// a bare test body would not reproduce it — `addPostFrameCallback` does
/// not schedule a frame, so nothing would ever run the callback.
class _MarksOnBuild extends StatelessWidget {
  const _MarksOnBuild({this.rebuild = false});

  /// Distinguishes the second pump from the first so `pumpWidget` sees a
  /// changed configuration and rebuilds rather than short-circuiting.
  final bool rebuild;

  /// What the KPI looked like at build time — the frame is not on screen
  /// yet, so it must still be unknown.
  static bool knownDuringBuild = false;

  @override
  Widget build(BuildContext context) {
    knownDuringBuild = StartupKpi.value.isKnown;
    StartupKpi.markUsefulMap();
    return const SizedBox.shrink();
  }
}
