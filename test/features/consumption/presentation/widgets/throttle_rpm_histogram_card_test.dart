import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/services/throttle_rpm_histogram_calculator.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/throttle_rpm_histogram_card.dart';

import '../../../../helpers/pump_app.dart';

/// Widget-level coverage for [ThrottleRpmHistogramCard] (#1041 phase
/// 3a — Card C).
///
/// Locks down:
///   * the localized title + section labels
///   * the four throttle quartile labels and four RPM band labels
///   * the trailing percent label formatting (`12%`)
///   * the per-axis empty-state caption (legacy trip with RPM but no
///     throttle data)
///   * the card-level empty-state caption (no samples on either axis)
///   * proportional bar widths — bars with larger time-share render
///     more `Flexible` flex than bars with smaller time-share
///
/// The maths-heavy bucketing logic stays in
/// `throttle_rpm_histogram_calculator_test.dart`; here we feed
/// pre-built histograms so the widget test stays focused on rendering.
void main() {
  group('ThrottleRpmHistogramCard — title + sections', () {
    testWidgets('renders the localized "How you used the engine" title',
        (tester) async {
      const histogram = ThrottleRpmHistogram(
        throttleQuartiles: [0.4, 0.3, 0.2, 0.1],
        rpmBands: [0.1, 0.5, 0.3, 0.1],
      );

      await pumpApp(
        tester,
        const ThrottleRpmHistogramCard(histogram: histogram),
      );

      expect(find.text('How you used the engine'), findsOneWidget);
    });

    testWidgets('renders both axis section labels', (tester) async {
      const histogram = ThrottleRpmHistogram(
        throttleQuartiles: [0.4, 0.3, 0.2, 0.1],
        rpmBands: [0.1, 0.5, 0.3, 0.1],
      );

      await pumpApp(
        tester,
        const ThrottleRpmHistogramCard(histogram: histogram),
      );

      expect(find.text('Throttle position'), findsOneWidget);
      expect(find.text('Engine RPM'), findsOneWidget);
    });
  });

  group('ThrottleRpmHistogramCard — bucket labels', () {
    testWidgets('renders all four throttle quartile labels', (tester) async {
      const histogram = ThrottleRpmHistogram(
        throttleQuartiles: [0.4, 0.3, 0.2, 0.1],
        rpmBands: [0.1, 0.5, 0.3, 0.1],
      );

      await pumpApp(
        tester,
        const ThrottleRpmHistogramCard(histogram: histogram),
      );

      expect(find.text('Coast (0–25%)'), findsOneWidget);
      expect(find.text('Light (25–50%)'), findsOneWidget);
      expect(find.text('Firm (50–75%)'), findsOneWidget);
      expect(find.text('Wide-open (75–100%)'), findsOneWidget);
    });

    testWidgets('renders all four RPM band labels', (tester) async {
      const histogram = ThrottleRpmHistogram(
        throttleQuartiles: [0.4, 0.3, 0.2, 0.1],
        rpmBands: [0.1, 0.5, 0.3, 0.1],
      );

      await pumpApp(
        tester,
        const ThrottleRpmHistogramCard(histogram: histogram),
      );

      expect(find.text('Idle (≤900)'), findsOneWidget);
      expect(find.text('Cruise (901–2000)'), findsOneWidget);
      expect(find.text('Spirited (2001–3000)'), findsOneWidget);
      expect(find.text('Hard (>3000)'), findsOneWidget);
    });
  });

  group('ThrottleRpmHistogramCard — trailing percent label', () {
    testWidgets('formats share as whole-number percent — "40%" not "40.0%"',
        (tester) async {
      const histogram = ThrottleRpmHistogram(
        throttleQuartiles: [0.40, 0.30, 0.20, 0.10],
        rpmBands: [0.10, 0.50, 0.30, 0.10],
      );

      await pumpApp(
        tester,
        const ThrottleRpmHistogramCard(histogram: histogram),
      );

      expect(find.text('40%'), findsOneWidget); // throttle bucket 0
      expect(find.text('50%'), findsOneWidget); // rpm band 1
      // No decimal leak.
      expect(find.textContaining('40.0%'), findsNothing);
    });

    testWidgets('rounds 0.234 to "23%"', (tester) async {
      const histogram = ThrottleRpmHistogram(
        throttleQuartiles: [0.234, 0.234, 0.266, 0.266],
        rpmBands: [0.234, 0.234, 0.266, 0.266],
      );

      await pumpApp(
        tester,
        const ThrottleRpmHistogramCard(histogram: histogram),
      );

      expect(find.text('23%'), findsWidgets);
      expect(find.text('27%'), findsWidgets);
    });
  });

  group('ThrottleRpmHistogramCard — empty states', () {
    testWidgets('renders card-level empty caption when no axis has data',
        (tester) async {
      const histogram = ThrottleRpmHistogram.empty;

      await pumpApp(
        tester,
        const ThrottleRpmHistogramCard(histogram: histogram),
      );

      expect(
        find.text('No throttle or RPM samples in this trip.'),
        findsOneWidget,
      );
      // Section labels should NOT render in the card-level empty path —
      // they only make sense when at least one axis has data.
      expect(find.text('Throttle position'), findsNothing);
      expect(find.text('Engine RPM'), findsNothing);
    });

    testWidgets(
        'renders RPM bars and a per-axis empty caption when only throttle is empty',
        (tester) async {
      // Legacy trip path — RPM bars render, throttle row falls back
      // to a single caption inside the throttle group.
      const histogram = ThrottleRpmHistogram(
        throttleQuartiles: [0.0, 0.0, 0.0, 0.0],
        rpmBands: [0.1, 0.5, 0.3, 0.1],
      );

      await pumpApp(
        tester,
        const ThrottleRpmHistogramCard(histogram: histogram),
      );

      // Both section labels render — the card has data overall.
      expect(find.text('Throttle position'), findsOneWidget);
      expect(find.text('Engine RPM'), findsOneWidget);

      // RPM band labels are visible (RPM has data).
      expect(find.text('Cruise (901–2000)'), findsOneWidget);
      // Throttle band labels do NOT render — that group dropped to its
      // own empty caption.
      expect(find.text('Coast (0–25%)'), findsNothing);

      // The empty caption appears once (inside the throttle group).
      expect(
        find.text('No throttle or RPM samples in this trip.'),
        findsOneWidget,
      );
    });
  });

  group('ThrottleRpmHistogramCard — proportional bar flex', () {
    testWidgets(
        'wider bars get more Flexible flex than narrower bars (throttle)',
        (tester) async {
      // Bucket 0 = 50 %, bucket 3 = 10 %. The first bar's flex must
      // exceed the fourth bar's flex — that's how the user reads
      // "more time was spent here".
      const histogram = ThrottleRpmHistogram(
        throttleQuartiles: [0.5, 0.2, 0.2, 0.1],
        rpmBands: [0.0, 0.0, 0.0, 0.0],
      );

      await pumpApp(
        tester,
        const ThrottleRpmHistogramCard(histogram: histogram),
      );

      // Locate the throttle band label rows by their text, then walk
      // up to the enclosing Row → grab the filled Container's flex.
      final flex0 = _filledFlex(tester, 'Coast (0–25%)');
      final flex3 = _filledFlex(tester, 'Wide-open (75–100%)');
      expect(flex0, greaterThan(flex3),
          reason:
              'A 50 %-share bar must occupy more flex than a 10 %-share '
              'bar — that is the histogram\'s entire visual signal.');
    });

    testWidgets('100 %-share bar has zero empty flex (no whitespace track)',
        (tester) async {
      const histogram = ThrottleRpmHistogram(
        throttleQuartiles: [1.0, 0.0, 0.0, 0.0],
        rpmBands: [0.0, 0.0, 0.0, 0.0],
      );

      await pumpApp(
        tester,
        const ThrottleRpmHistogramCard(histogram: histogram),
      );

      // The 100 %-share row has filled = 1000, empty = 0 — only one
      // Flexible inside the bar track. We assert by counting all
      // Flexible widgets inside the Row whose Text matches the label.
      final flexFor100 = _allFlexInBarRow(tester, 'Coast (0–25%)');
      expect(flexFor100, hasLength(1));
      expect(flexFor100.first, equals(1000));
    });
  });
}

/// Walk up from the [label] text to the enclosing `_BarRow` and return
/// the `flex` value of the FIRST `Flexible` (the filled portion) in the
/// bar's inner Row.
int _filledFlex(WidgetTester tester, String label) {
  final flexFlex = _allFlexInBarRow(tester, label);
  return flexFlex.first;
}

/// Return the flex values of every `Flexible` widget inside the `_BarRow`
/// associated with [label]. The row carries 1–2 Flexibles depending on
/// whether the empty remainder is non-zero.
List<int> _allFlexInBarRow(WidgetTester tester, String label) {
  final textFinder = find.text(label);
  expect(
    textFinder,
    findsOneWidget,
    reason: 'Expected the bar row labelled `$label` to be on screen.',
  );
  // Walk up to the enclosing _BarRow (Padding ancestor).
  final paddingFinder = find.ancestor(
    of: textFinder,
    matching: find.byType(Padding),
  );
  expect(paddingFinder, findsWidgets);

  // The _BarRow wraps everything in a Padding → Row → [SizedBox(label),
  // SizedBox(width:8), Expanded(SizedBox.height:12 → Row(Flexible…)),
  // SizedBox(width:8), SizedBox(label)]. Find the Flexibles inside any
  // Row that descends from the bar's enclosing Padding.
  final allFlexibles = find.descendant(
    of: paddingFinder.first,
    matching: find.byType(Flexible),
  );
  final widgets = tester.widgetList<Flexible>(allFlexibles).toList();
  return widgets.map((f) => f.flex).toList();
}
