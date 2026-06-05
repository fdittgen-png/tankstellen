// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/dark_mode_colors.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/proximity_fill_bar.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('fillFor (#2899 — the closeness fraction)', () {
    test('0% at distance >= radius (empty at the edge)', () {
      expect(ProximityFillBar.fillFor(1000, 1000), 0.0);
    });

    test('~0.8 at 0.2 km inside a 1 km radius', () {
      expect(ProximityFillBar.fillFor(200, 1000), closeTo(0.8, 1e-9));
    });

    test('~0.9 at 0.1 km inside a 1 km radius', () {
      expect(ProximityFillBar.fillFor(100, 1000), closeTo(0.9, 1e-9));
    });

    test('100% at distance 0 (full at the station)', () {
      expect(ProximityFillBar.fillFor(0, 1000), 1.0);
    });

    test('clamps to 0 beyond the radius (no negative)', () {
      expect(ProximityFillBar.fillFor(2400, 1000), 0.0);
    });

    test('clamps to 1 at/under the station (no overflow)', () {
      expect(ProximityFillBar.fillFor(-50, 1000), 1.0);
    });

    test('0 for a non-positive radius (no divide-by-zero blow-up)', () {
      expect(ProximityFillBar.fillFor(100, 0), 0.0);
    });
  });

  testWidgets('the rendered fill width matches fillFor (live fraction)',
      (tester) async {
    // 0.2 km inside a 1 km radius → the FractionallySizedBox settles at 0.8.
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 200,
          child: ProximityFillBar(distanceMeters: 200, radiusMeters: 1000),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final box = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(box.widthFactor, closeTo(0.8, 1e-6));
  });

  testWidgets('fill is a two-colour green→accent gradient (#2808)',
      (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 200,
          child: ProximityFillBar(distanceMeters: 200, radiusMeters: 1000),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(ProximityFillBar));
    final green = DarkModeColors.brandGreen(context);
    final accent = DarkModeColors.proximityAccent(context);

    final decorated = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.gradient != null);
    final gradient = decorated.gradient! as LinearGradient;

    expect(gradient.colors, [green, accent],
        reason: 'two distinct colours — brand green and the blue-violet accent');
    expect(green, isNot(accent));
  });

  testWidgets('collapses when radius is null/non-positive', (tester) async {
    await tester.pumpWidget(
      _host(const ProximityFillBar(distanceMeters: 100, radiusMeters: null)),
    );
    expect(find.byType(DecoratedBox), findsNothing);
  });
}
