// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/gps_sample_diagnostic.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/gps_diagnostics_card.dart';

import '../../../../helpers/pump_app.dart';

/// Coverage for the GPS sample diagnostics inspector card
/// (#1458 phase 2.5).
///
/// Splits into three groups:
///   * `computeGpsDiagnosticsSummary` — the pure-function helper that
///     does all the math, exercised directly so the assertions don't
///     have to pump a widget tree.
///   * `GpsDiagnosticsCard — collapsed` — what the card looks like in
///     its default (collapsed) state.
///   * `GpsDiagnosticsCard — expansion` — tap the tile, the body
///     content appears.
void main() {
  // Helper to build a list of diagnostics with a fixed cadence + a
  // single optional inserted gap. Keeps each test's setup short.
  List<GpsSampleDiagnostic> buildDiagnostics({
    required int count,
    required Duration interval,
    String lifecycle = 'resumed',
    Duration? injectedGapAt2,
  }) {
    final start = DateTime.utc(2026, 1, 1, 12);
    final list = <GpsSampleDiagnostic>[];
    var t = start;
    for (var i = 0; i < count; i++) {
      list.add(
        GpsSampleDiagnostic(timestamp: t, lifecycleState: lifecycle, index: i),
      );
      // After the second sample is appended, optionally inject the gap
      // before computing the next timestamp.
      if (injectedGapAt2 != null && i == 1) {
        t = t.add(injectedGapAt2);
      } else {
        t = t.add(interval);
      }
    }
    return list;
  }

  group('computeGpsDiagnosticsSummary', () {
    test('empty input returns the empty summary', () {
      expect(
        computeGpsDiagnosticsSummary(const []),
        equals(GpsDiagnosticsSummary.empty),
      );
    });

    test('single sample reports zero span and 100% lifecycle', () {
      final summary = computeGpsDiagnosticsSummary([
        GpsSampleDiagnostic(
          timestamp: DateTime.utc(2026, 1, 1),
          lifecycleState: 'resumed',
          index: 0,
        ),
      ]);

      expect(summary.sampleCount, 1);
      expect(summary.timeSpan, Duration.zero);
      expect(summary.gapCount, 0);
      expect(summary.lifecyclePercent, equals({'resumed': 100}));
    });

    test('reports sample count and time span for a steady 1 Hz cadence', () {
      // 11 samples at 1000 ms each → 10 s span, no gaps.
      final diagnostics = buildDiagnostics(
        count: 11,
        interval: const Duration(milliseconds: 1000),
      );
      final summary = computeGpsDiagnosticsSummary(diagnostics);

      expect(summary.sampleCount, 11);
      expect(summary.timeSpan, const Duration(seconds: 10));
      expect(summary.medianIntervalMs, 1000);
      expect(summary.gapCount, 0);
      expect(summary.largestGap, const Duration(seconds: 1));
    });

    test('rounds the median to the nearest 100 ms', () {
      // 5 samples at 1023 ms each → median 1023 ms → rounds to 1000 ms.
      final diagnostics = buildDiagnostics(
        count: 5,
        interval: const Duration(milliseconds: 1023),
      );
      final summary = computeGpsDiagnosticsSummary(diagnostics);

      expect(summary.medianIntervalMs, 1000);
    });

    test('lifecycle breakdown uses correct percentages', () {
      // 10 samples: 8 'resumed', 2 'paused' → 80% / 20%.
      final start = DateTime.utc(2026, 1, 1);
      final diagnostics = <GpsSampleDiagnostic>[];
      for (var i = 0; i < 10; i++) {
        diagnostics.add(GpsSampleDiagnostic(
          timestamp: start.add(Duration(seconds: i)),
          lifecycleState: i < 8 ? 'resumed' : 'paused',
          index: i,
        ));
      }

      final summary = computeGpsDiagnosticsSummary(diagnostics);

      expect(summary.lifecyclePercent['resumed'], 80);
      expect(summary.lifecyclePercent['paused'], 20);
      // Dominant state renders first when iterated.
      expect(summary.lifecyclePercent.keys.first, 'resumed');
    });

    test('detects gaps when an interval is at least 3x the median', () {
      // 6 samples at 1000 ms with a 5000 ms gap injected after sample 2.
      // Intervals: [1000, 5000, 1000, 1000, 1000] → median 1000, gap
      // count 1, largest 5000 ms.
      final diagnostics = buildDiagnostics(
        count: 6,
        interval: const Duration(milliseconds: 1000),
        injectedGapAt2: const Duration(milliseconds: 5000),
      );
      final summary = computeGpsDiagnosticsSummary(diagnostics);

      expect(summary.medianIntervalMs, 1000);
      expect(summary.gapCount, 1);
      expect(summary.largestGap, const Duration(milliseconds: 5000));
    });

    test('returns 0 gap count when median is 0 (degenerate input)', () {
      // Three samples on the SAME ms — median is 0, so the >= 3x rule
      // is meaningless and we report no gaps.
      final t = DateTime.utc(2026, 1, 1);
      final diagnostics = [
        GpsSampleDiagnostic(timestamp: t, lifecycleState: 'resumed', index: 0),
        GpsSampleDiagnostic(timestamp: t, lifecycleState: 'resumed', index: 1),
        GpsSampleDiagnostic(timestamp: t, lifecycleState: 'resumed', index: 2),
      ];

      final summary = computeGpsDiagnosticsSummary(diagnostics);
      expect(summary.gapCount, 0);
      expect(summary.medianIntervalMs, 0);
    });
  });

  group('GpsDiagnosticsCard — collapsed', () {
    testWidgets('renders the localized title', (tester) async {
      final diagnostics = buildDiagnostics(
        count: 5,
        interval: const Duration(seconds: 1),
      );

      await pumpApp(tester, GpsDiagnosticsCard(diagnostics: diagnostics));

      expect(find.text('GPS sampling diagnostics'), findsOneWidget);
    });

    testWidgets('shows sample count and time span in the header line',
        (tester) async {
      // 13 samples at 60 s each → 12 min span.
      final diagnostics = buildDiagnostics(
        count: 13,
        interval: const Duration(minutes: 1),
      );

      await pumpApp(tester, GpsDiagnosticsCard(diagnostics: diagnostics));

      expect(find.textContaining('13 samples'), findsOneWidget);
      expect(find.textContaining('12min'), findsOneWidget);
      expect(find.textContaining('no gaps'), findsOneWidget);
    });

    testWidgets('expansion body content is hidden by default', (tester) async {
      final diagnostics = buildDiagnostics(
        count: 5,
        interval: const Duration(seconds: 1),
      );

      await pumpApp(tester, GpsDiagnosticsCard(diagnostics: diagnostics));

      // The cadence + explanation lines are inside the collapsed
      // ExpansionTile — they're not yet built into the tree.
      expect(find.textContaining('Median interval'), findsNothing);
      expect(
        find.textContaining('Captured during recording'),
        findsNothing,
      );
    });
  });

  group('GpsDiagnosticsCard — expansion', () {
    testWidgets('tapping the tile reveals the cadence + explanation lines',
        (tester) async {
      final diagnostics = buildDiagnostics(
        count: 11,
        interval: const Duration(milliseconds: 1000),
      );

      await pumpApp(tester, GpsDiagnosticsCard(diagnostics: diagnostics));

      // Tap the tile to expand.
      await tester.tap(find.byKey(const Key('gps_diagnostics_tile')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Median interval: 1000 ms'), findsOneWidget);
      expect(find.textContaining('resumed 100%'), findsOneWidget);
      expect(find.textContaining('Largest gap'), findsOneWidget);
      expect(
        find.textContaining('Captured during recording'),
        findsOneWidget,
      );
    });
  });
}
