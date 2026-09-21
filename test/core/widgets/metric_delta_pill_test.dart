// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/dark_mode_colors.dart';
import 'package:tankstellen/core/widgets/metric_delta_pill.dart';

/// #4175 — the change as a tinted pill instead of a bare arrow.
///
/// The rules it must keep are `MetricDeltaArrow`'s, because the two
/// appear on the same screens and a metric that reads as an improvement
/// in one place must not read as a regression in the other.
void main() {
  late BuildContext ctx;

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (c) {
          ctx = c;
          return child;
        }),
      ),
    ));
  }

  Color tint(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(MetricDeltaPill),
        matching: find.byType(DecoratedBox),
      ),
    );
    return (box.decoration as BoxDecoration).color!;
  }

  Color textColor(WidgetTester tester) =>
      tester.widget<Text>(find.text('+12%')).style!.color!;

  testWidgets('noise renders nothing at all', (tester) async {
    // A displayed-equal pair must never sprout a coloured badge.
    await pump(
      tester,
      const MetricDeltaPill(
          delta: 0.001, percentText: '+0%', flatBelow: 0.005),
    );
    expect(find.byType(DecoratedBox), findsNothing);
  });

  testWidgets('up is bad when lower is better', (tester) async {
    await pump(tester,
        const MetricDeltaPill(delta: 0.4, percentText: '+12%'));
    expect(textColor(tester), Theme.of(ctx).colorScheme.error);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  testWidgets('down is good when lower is better', (tester) async {
    await pump(tester,
        const MetricDeltaPill(delta: -0.4, percentText: '+12%'));
    expect(textColor(tester), DarkModeColors.success(ctx));
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
  });

  testWidgets('the sentiment inverts when higher is better',
      (tester) async {
    await pump(
      tester,
      const MetricDeltaPill(
          delta: 0.4, percentText: '+12%', lowerIsBetter: false),
    );
    expect(textColor(tester), DarkModeColors.success(ctx));
  });

  testWidgets('a neutral metric is muted in both directions',
      (tester) async {
    await pump(
      tester,
      const MetricDeltaPill(delta: 3, percentText: '+12%', neutral: true),
    );
    expect(textColor(tester), Theme.of(ctx).colorScheme.onSurfaceVariant);
  });

  testWidgets('the tint is the text colour, faded — one hue, two roles',
      (tester) async {
    await pump(tester,
        const MetricDeltaPill(delta: 0.4, percentText: '+12%'));
    final scheme = Theme.of(ctx).colorScheme;
    expect(tint(tester), scheme.error.withValues(alpha: 0.12));
  });

  testWidgets('no percentage still shows the direction', (tester) async {
    // The previous figure was zero, so a percentage would be
    // meaningless — but the direction is still known and still useful.
    await pump(tester, const MetricDeltaPill(delta: 0.4, percentText: null));
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('compact drops the glyph, never the number', (tester) async {
    // At the narrowest widths the colour carries the direction; a
    // truncated number would carry nothing.
    await pump(
      tester,
      const MetricDeltaPill(
          delta: 0.4, percentText: '+12%', compact: true),
    );
    expect(find.byIcon(Icons.arrow_upward), findsNothing);
    expect(find.text('+12%'), findsOneWidget);
  });
}
