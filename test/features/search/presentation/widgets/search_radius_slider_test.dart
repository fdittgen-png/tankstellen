// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_radius_slider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('SearchRadiusSlider', () {
    Future<void> pumpSlider(
      WidgetTester tester, {
      required double radius,
      required ValueChanged<double> onChanged,
      double minKm = 1,
      double maxKm = 25,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SearchRadiusSlider(
              radiusKm: radius,
              minKm: minKm,
              maxKm: maxKm,
              onChanged: onChanged,
            ),
          ),
        ),
      );
    }

    ChoiceChip chip(WidgetTester tester, String key) =>
        tester.widget<ChoiceChip>(find.byKey(ValueKey(key)));

    testWidgets('#4199 — a preset radius is shown ONCE: its chip, no slider',
        (tester) async {
      await pumpSlider(tester, radius: 10, onChanged: (_) {});

      expect(find.byType(Slider), findsNothing);
      expect(chip(tester, 'criteria-radius-preset-10').selected, isTrue);
      expect(chip(tester, 'criteria-radius-custom').selected, isFalse);
      expect(find.text('10 km'), findsOneWidget,
          reason: 'title value + drag bubble + chip used to triple it');
    });

    testWidgets('a non-preset radius opens the custom control with its value',
        (tester) async {
      await pumpSlider(tester, radius: 7.4, onChanged: (_) {});

      expect(find.byType(Slider), findsOneWidget);
      expect(chip(tester, 'criteria-radius-custom').selected, isTrue);
      expect(find.text('7 km'), findsOneWidget, reason: 'the title row');
      expect(tester.widget<Slider>(find.byType(Slider)).label, isNull,
          reason: 'no drag bubble repeating the title value');
    });

    testWidgets('Custom reveals the slider without changing the radius; a '
        'preset hides it again', (tester) async {
      final changes = <double>[];
      await pumpSlider(tester, radius: 10, onChanged: changes.add);

      await tester.tap(find.byKey(const ValueKey('criteria-radius-custom')));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsOneWidget);
      expect(changes, isEmpty);

      await tester.tap(find.byKey(const ValueKey('criteria-radius-preset-5')));
      await tester.pumpAndSettle();
      expect(changes, [5.0]);
    });

    testWidgets('the 50 km preset is not offered while the range ends at 25',
        (tester) async {
      await pumpSlider(tester, radius: 10, onChanged: (_) {});
      expect(find.byKey(const ValueKey('criteria-radius-preset-50')),
          findsNothing);
    });

    testWidgets('clamps the slider value into [minKm, maxKm]', (tester) async {
      await pumpSlider(tester, radius: 50, maxKm: 20, onChanged: (_) {});
      expect(tester.widget<Slider>(find.byType(Slider)).value, 20);
    });

    testWidgets('clamps below the minimum', (tester) async {
      await pumpSlider(tester, radius: -5, onChanged: (_) {});
      expect(tester.widget<Slider>(find.byType(Slider)).value, 1);
    });

    testWidgets('uses (max - min) divisions so each integer km is a tick', (
      tester,
    ) async {
      await pumpSlider(
        tester,
        radius: 7,
        minKm: 1,
        maxKm: 10,
        onChanged: (_) {},
      );
      expect(tester.widget<Slider>(find.byType(Slider)).divisions, 9);
    });

    testWidgets('forwards onChanged when the slider is dragged', (
      tester,
    ) async {
      double? captured;
      await pumpSlider(tester, radius: 7, onChanged: (v) => captured = v);
      await tester.tap(find.byType(Slider));
      await tester.pump();
      expect(captured, isNotNull);
    });
  });
}
