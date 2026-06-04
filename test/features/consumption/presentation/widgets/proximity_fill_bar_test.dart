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
