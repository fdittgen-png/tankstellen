// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/dark_mode_colors.dart';
import 'package:tankstellen/core/widgets/metric_delta_arrow.dart';

/// #3983 — one arrow for every metric delta; the three private copies it
/// replaces disagreed on thresholds, sizes and which direction was bad.
void main() {
  Future<BuildContext> pump(WidgetTester tester, Widget child) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return Scaffold(body: child);
      }),
    ));
    return ctx;
  }

  testWidgets('below flatBelow nothing renders', (tester) async {
    await pump(tester, const MetricDeltaArrow(delta: 0.001, flatBelow: 0.005));
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('lowerIsBetter: up is error-red, down is success-green',
      (tester) async {
    final ctx = await pump(tester, const MetricDeltaArrow(delta: 0.4));
    final up = tester.widget<Icon>(find.byIcon(Icons.arrow_upward));
    expect(up.color, Theme.of(ctx).colorScheme.error);

    await pump(tester, const MetricDeltaArrow(delta: -0.4));
    final down = tester.widget<Icon>(find.byIcon(Icons.arrow_downward));
    expect(down.color, DarkModeColors.success(ctx));
  });

  testWidgets('higherIsBetter flips the colours', (tester) async {
    final ctx = await pump(
        tester, const MetricDeltaArrow(delta: 0.4, lowerIsBetter: false));
    final up = tester.widget<Icon>(find.byIcon(Icons.arrow_upward));
    expect(up.color, DarkModeColors.success(ctx));
  });

  testWidgets('neutral mutes both directions and size is honoured',
      (tester) async {
    final ctx = await pump(
        tester, const MetricDeltaArrow(delta: 3, neutral: true, size: 14));
    final up = tester.widget<Icon>(find.byIcon(Icons.arrow_upward));
    expect(up.color, Theme.of(ctx).colorScheme.onSurfaceVariant);
    expect(up.size, 14);
  });
}
