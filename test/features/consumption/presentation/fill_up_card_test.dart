import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/entities/consumption_stats.dart';
import 'package:tankstellen/features/consumption/domain/entities/eco_score.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/consumption_stats_card.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/eco_score_badge.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_card.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('FillUpCard shows station name, liters, cost and price/L',
      (tester) async {
    final fillUp = FillUp(
      id: 'test',
      date: DateTime(2026, 3, 15),
      liters: 50.0,
      totalCost: 80.0,
      odometerKm: 12345,
      fuelType: FuelType.diesel,
      stationId: 's1',
      stationName: 'Shell Berlin',
    );

    await pumpApp(tester, FillUpCard(fillUp: fillUp));

    expect(find.text('Shell Berlin'), findsOneWidget);
    // Now goes through UnitFormatter — FR locale uses comma decimal,
    // price-per-litre gets its suffix from the country config.
    expect(find.textContaining('50,0 L'), findsOneWidget);
    expect(find.textContaining('1,600 \u20ac/L'), findsOneWidget);
    // Odometer goes through formatDistance — large integer, one
    // decimal: "12345,0 km" in FR locale.
    expect(find.textContaining('km'), findsOneWidget);
    expect(find.textContaining('12'), findsOneWidget);
  });

  testWidgets('FillUpCard falls back to fuel type when no station name',
      (tester) async {
    final fillUp = FillUp(
      id: 'test',
      date: DateTime(2026, 3, 15),
      liters: 40,
      totalCost: 60,
      odometerKm: 1000,
      fuelType: FuelType.e10,
    );

    await pumpApp(tester, FillUpCard(fillUp: fillUp));

    expect(find.text('E10'), findsWidgets);
  });

  testWidgets('FillUpCard omits the eco-score badge when no score is provided',
      (tester) async {
    final fillUp = FillUp(
      id: 'test',
      date: DateTime(2026, 3, 15),
      liters: 40,
      totalCost: 60,
      odometerKm: 1000,
      fuelType: FuelType.e10,
      stationName: 'Test',
    );
    await pumpApp(tester, FillUpCard(fillUp: fillUp));
    expect(find.byType(EcoScoreBadge), findsNothing);
  });

  testWidgets('FillUpCard shows the eco-score badge when a score is provided',
      (tester) async {
    final fillUp = FillUp(
      id: 'test',
      date: DateTime(2026, 3, 15),
      liters: 40,
      totalCost: 60,
      odometerKm: 1000,
      fuelType: FuelType.e10,
      stationName: 'Test',
    );
    const score = EcoScore(
      litersPer100Km: 5.4,
      rollingAverage: 6.0,
      deltaPercent: -10,
      direction: EcoScoreDirection.improving,
    );
    await pumpApp(tester, FillUpCard(fillUp: fillUp, ecoScore: score));
    expect(find.byType(EcoScoreBadge), findsOneWidget);
    // The delta text surfaces from inside the badge.
    expect(find.textContaining('-10%'), findsOneWidget);
  });

  testWidgets('FillUpCard calls onTap when tapped', (tester) async {
    var tapped = false;
    final fillUp = FillUp(
      id: 'test',
      date: DateTime(2026, 3, 15),
      liters: 40,
      totalCost: 60,
      odometerKm: 1000,
      fuelType: FuelType.e10,
      stationName: 'Test',
    );

    await pumpApp(
      tester,
      FillUpCard(fillUp: fillUp, onTap: () => tapped = true),
    );
    await tester.tap(find.byType(ListTile));
    expect(tapped, true);
  });

  // #1361 phase 2b — orange treatment for correction fill-ups.
  group('correction fill-up styling (#1361)', () {
    testWidgets(
        'isCorrection=true renders the orange auto-fix icon and label',
        (tester) async {
      final fillUp = FillUp(
        id: 'correction_p1',
        date: DateTime(2026, 4, 15),
        liters: 3.5,
        totalCost: 0,
        odometerKm: 12000,
        fuelType: FuelType.e10,
        isCorrection: true,
      );
      await pumpApp(tester, FillUpCard(fillUp: fillUp));

      // Auto-fix-high icon is the leading icon for corrections.
      expect(find.byIcon(Icons.auto_fix_high), findsOneWidget,
          reason: 'leading should be auto_fix_high for corrections');
      expect(find.byIcon(Icons.local_gas_station), findsNothing,
          reason: 'gas-station icon must not appear on corrections');

      // Inline label calls out the auto-correction nature.
      expect(
        find.text('Auto-correction — tap to edit'),
        findsOneWidget,
        reason: 'fillUpCorrectionLabel must render under the cost line',
      );

      // The card must paint a 4 px orange border via Card.shape.
      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape;
      expect(shape, isA<RoundedRectangleBorder>());
      final border = (shape! as RoundedRectangleBorder).side;
      expect(border.color, Colors.orange.shade700);
      expect(border.width, 4);
    });

    testWidgets(
        'isCorrection=false keeps the gas-station icon and no correction '
        'label', (tester) async {
      final fillUp = FillUp(
        id: 'normal',
        date: DateTime(2026, 4, 15),
        liters: 40,
        totalCost: 60,
        odometerKm: 12000,
        fuelType: FuelType.e10,
      );
      await pumpApp(tester, FillUpCard(fillUp: fillUp));

      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
      expect(find.byIcon(Icons.auto_fix_high), findsNothing);
      expect(find.text('Auto-correction — tap to edit'), findsNothing);

      // No orange-bordered shape when not a correction.
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.shape, isNull,
          reason: 'normal cards must not carry the correction shape');
    });

    testWidgets('correction card still fires onTap (used by the editor sheet)',
        (tester) async {
      var tapped = false;
      final fillUp = FillUp(
        id: 'correction_p1',
        date: DateTime(2026, 4, 15),
        liters: 3.5,
        totalCost: 0,
        odometerKm: 12000,
        fuelType: FuelType.e10,
        isCorrection: true,
      );
      await pumpApp(
        tester,
        FillUpCard(fillUp: fillUp, onTap: () => tapped = true),
      );
      await tester.tap(find.byType(ListTile));
      expect(tapped, true);
    });
  });

  testWidgets('ConsumptionStatsCard renders totals and avg values',
      (tester) async {
    const stats = ConsumptionStats(
      fillUpCount: 3,
      totalLiters: 120,
      totalSpent: 180,
      totalDistanceKm: 1500,
      avgConsumptionL100km: 8.0,
      avgCostPerKm: 0.12,
      avgPricePerLiter: 1.5,
    );

    await pumpApp(tester, const ConsumptionStatsCard(stats: stats));

    expect(find.text('8.00'), findsOneWidget); // avg L/100km
    expect(find.text('0.120'), findsOneWidget); // avg cost/km
    expect(find.text('120.0'), findsOneWidget); // total liters
    expect(find.text('180.00'), findsOneWidget); // total spent
    expect(find.textContaining('3'), findsWidgets); // fill up count
  });

  testWidgets('ConsumptionStatsCard shows dashes when no avg data',
      (tester) async {
    await pumpApp(
      tester,
      const ConsumptionStatsCard(stats: ConsumptionStats.empty),
    );
    expect(find.text('—'), findsWidgets);
  });
}
