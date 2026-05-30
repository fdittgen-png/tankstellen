// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/price_history/domain/entities/fill_up_guidance.dart';
import 'package:tankstellen/features/price_history/presentation/widgets/fill_up_guidance_card.dart';
import 'package:tankstellen/features/price_history/providers/fill_up_guidance_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('FillUpGuidanceCard', () {
    setUp(() => PriceFormatter.setCountry('GB'));
    tearDown(() => PriceFormatter.setCountry('FR'));

    // Override the gated provider directly so the widget test doesn't
    // depend on feature-flag plumbing or storage (covered elsewhere).
    Object overrideGuidance(FillUpGuidance? value) =>
        fillUpGuidanceProvider('s1', FuelType.e10).overrideWithValue(value);

    testWidgets('renders nothing when the provider returns null '
        '(gate off / thin data)', (tester) async {
      await pumpApp(
        tester,
        const FillUpGuidanceCard(stationId: 's1', fuelType: FuelType.e10),
        overrides: [overrideGuidance(null)],
      );

      expect(find.byType(Card), findsNothing);
      expect(find.text('Best time to fill up'), findsNothing);
    });

    testWidgets('renders the goodTimeNow guidance + sample note',
        (tester) async {
      await pumpApp(
        tester,
        const FillUpGuidanceCard(stationId: 's1', fuelType: FuelType.e10),
        overrides: [
          overrideGuidance(const FillUpGuidance(
            kind: FillUpGuidanceKind.goodTimeNow,
            currentPercentile: 10,
            trend: FillUpTrend.flat,
            sampleCount: 24,
            windowDays: 30,
          )),
        ],
      );

      expect(find.text('Best time to fill up'), findsOneWidget);
      expect(find.textContaining('good time to fill up'), findsOneWidget);
      expect(find.textContaining('24'), findsOneWidget); // sample note
      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
    });

    testWidgets('renders the waitCheaperWindow guidance with a composed '
        'day+part window phrase and saving line', (tester) async {
      await pumpApp(
        tester,
        const FillUpGuidanceCard(stationId: 's1', fuelType: FuelType.e10),
        overrides: [
          overrideGuidance(const FillUpGuidance(
            kind: FillUpGuidanceKind.waitCheaperWindow,
            currentPercentile: 90,
            trend: FillUpTrend.flat,
            cheapestDayOfWeek: 2, // Tuesday
            cheapestDayPart: DayPart.morning,
            potentialSavingPerLitre: 0.05,
            sampleCount: 18,
            windowDays: 30,
          )),
        ],
      );

      // Composed window phrase "Tuesdays mornings".
      expect(find.textContaining('Tuesdays'), findsOneWidget);
      expect(find.textContaining('mornings'), findsOneWidget);
      // Saving line is shown (GB locale formats with a dot decimal).
      expect(find.textContaining('save'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('renders the fillSoonRising guidance', (tester) async {
      await pumpApp(
        tester,
        const FillUpGuidanceCard(stationId: 's1', fuelType: FuelType.e10),
        overrides: [
          overrideGuidance(const FillUpGuidance(
            kind: FillUpGuidanceKind.fillSoonRising,
            currentPercentile: 60,
            trend: FillUpTrend.rising,
            sampleCount: 15,
            windowDays: 30,
          )),
        ],
      );

      expect(find.textContaining('trending up'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('renders the neutral guidance with no saving line',
        (tester) async {
      await pumpApp(
        tester,
        const FillUpGuidanceCard(stationId: 's1', fuelType: FuelType.e10),
        overrides: [
          overrideGuidance(const FillUpGuidance(
            kind: FillUpGuidanceKind.neutral,
            currentPercentile: 50,
            trend: FillUpTrend.flat,
            sampleCount: 20,
            windowDays: 30,
          )),
        ],
      );

      expect(find.textContaining('average'), findsOneWidget);
      expect(find.textContaining('save'), findsNothing);
    });
  });
}
