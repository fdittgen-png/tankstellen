import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/charging_cost_trend_chart.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/charging_efficiency_chart.dart';

import '../../../../helpers/pump_app.dart';

/// #582 phase 3 — empty-state + data-bound rendering for the two new
/// charging charts. Both widgets sit above the logs list on the
/// Charging tab; they must render sensibly with zero, one, or six
/// months of data.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChargingCostTrendChart', () {
    testWidgets('renders the empty-state caption when all months are 0',
        (tester) async {
      final months = {
        for (int i = 5; i >= 0; i--)
          DateTime.utc(2026, 4 - i, 1): 0.0,
      };
      await pumpApp(
        tester,
        ChargingCostTrendChart(monthlyCost: months),
      );
      expect(find.text('Not enough data yet'), findsOneWidget);
    });

    testWidgets(
      'hides the empty-state caption when at least one month has data',
      (tester) async {
        final months = {
          DateTime.utc(2026, 1, 1): 0.0,
          DateTime.utc(2026, 2, 1): 10.0,
          DateTime.utc(2026, 3, 1): 20.0,
          DateTime.utc(2026, 4, 1): 30.0,
        };
        await pumpApp(
          tester,
          ChargingCostTrendChart(monthlyCost: months),
        );
        expect(find.text('Not enough data yet'), findsNothing);
        // A CustomPaint descendant of the chart widget proves the
        // painter was wired up. Scoping with `descendant` avoids
        // false positives from the Material chrome, which renders
        // its own CustomPaint nodes.
        expect(
          find.descendant(
            of: find.byType(ChargingCostTrendChart),
            matching: find.byType(CustomPaint),
          ),
          findsWidgets,
        );
      },
    );

    testWidgets('renders the empty-state caption when map is empty',
        (tester) async {
      await pumpApp(
        tester,
        const ChargingCostTrendChart(monthlyCost: {}),
      );
      expect(find.text('Not enough data yet'), findsOneWidget);
    });
  });

  group('ChargingEfficiencyChart', () {
    testWidgets('renders the empty-state caption when every month is null',
        (tester) async {
      final months = {
        for (int i = 5; i >= 0; i--)
          DateTime.utc(2026, 4 - i, 1): null,
      };
      await pumpApp(
        tester,
        ChargingEfficiencyChart(monthlyEfficiency: months),
      );
      expect(find.text('Not enough data yet'), findsOneWidget);
    });

    testWidgets(
      'hides the empty-state caption when at least one month has a value',
      (tester) async {
        final months = {
          DateTime.utc(2026, 1, 1): null,
          DateTime.utc(2026, 2, 1): 15.0,
          DateTime.utc(2026, 3, 1): 18.0,
          DateTime.utc(2026, 4, 1): 14.5,
        };
        await pumpApp(
          tester,
          ChargingEfficiencyChart(monthlyEfficiency: months),
        );
        expect(find.text('Not enough data yet'), findsNothing);
        expect(
          find.descendant(
            of: find.byType(ChargingEfficiencyChart),
            matching: find.byType(CustomPaint),
          ),
          findsWidgets,
        );
      },
    );

    testWidgets('renders the empty-state caption when map is empty',
        (tester) async {
      await pumpApp(
        tester,
        const ChargingEfficiencyChart(monthlyEfficiency: {}),
      );
      expect(find.text('Not enough data yet'), findsOneWidget);
    });
  });
}
