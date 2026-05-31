// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/calculator/presentation/widgets/calculator_result_card.dart';
import 'package:tankstellen/features/calculator/providers/calculator_provider.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('CalculatorResultCard', () {
    tearDown(() => PriceFormatter.setCountry('FR'));

    testWidgets('shows -- placeholders before all inputs are entered',
        (tester) async {
      // Distance + consumption set, but no price → not yet calculable.
      const state = CalculatorState(distanceKm: 100, pricePerLiter: 0);

      await pumpApp(tester, const CalculatorResultCard(state: state));

      expect(find.text('Trip Cost'), findsOneWidget);
      // The hero total and every breakdown tile read `--`.
      expect(find.text('--'), findsWidgets);
      // The one-line helper appears in the empty state.
      expect(
        find.text(
          'Fill in distance, consumption and price to see your trip cost',
        ),
        findsOneWidget,
      );
    });

    testWidgets('fills live once all three inputs are present',
        (tester) async {
      PriceFormatter.setCountry('FR');
      const state = CalculatorState(
        distanceKm: 100,
        consumptionPer100Km: 7,
        pricePerLiter: 2,
      );

      await pumpApp(tester, const CalculatorResultCard(state: state));

      // 100 km * 7 L/100km = 7 L (FR comma decimal).
      expect(find.text('7,0 L'), findsOneWidget);
      // 7 L * 2 €/L = 14.00 € via formatTotal.
      expect(find.text('14,00 €'), findsOneWidget);
      // No placeholder helper once filled.
      expect(
        find.text(
          'Fill in distance, consumption and price to see your trip cost',
        ),
        findsNothing,
      );
    });

    testWidgets('round-trip doubles the hero total', (tester) async {
      PriceFormatter.setCountry('FR');
      const oneWay = CalculatorState(
        distanceKm: 100,
        consumptionPer100Km: 7,
        pricePerLiter: 2,
      );
      const roundTrip = CalculatorState(
        distanceKm: 100,
        consumptionPer100Km: 7,
        pricePerLiter: 2,
        roundTrip: true,
      );

      await pumpApp(tester, const CalculatorResultCard(state: oneWay));
      expect(find.text('14,00 €'), findsOneWidget);

      await pumpApp(tester, const CalculatorResultCard(state: roundTrip));
      // Doubled: 28,00 € shows for both the hero and the round-trip tile.
      expect(find.text('28,00 €'), findsWidgets);
    });

    testWidgets('total uses formatTotal — zero-decimal currency (KRW)',
        (tester) async {
      // The #2491 path: a KRW total must render whole (no `.00`).
      PriceFormatter.setCountry('KR');
      const state = CalculatorState(
        distanceKm: 100,
        consumptionPer100Km: 7,
        pricePerLiter: 1500,
      );

      await pumpApp(tester, const CalculatorResultCard(state: state));

      // 7 L * 1500 ₩ = 10500 ₩ → zero-decimal, grouped.
      expect(find.text('10,500 ₩'), findsOneWidget);
      // The broken raw `toStringAsFixed(2)` form must NOT appear.
      expect(find.text('10500.00 ₩'), findsNothing);
    });
  });
}
