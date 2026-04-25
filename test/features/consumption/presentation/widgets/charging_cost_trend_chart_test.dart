import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/charging_cost_trend_chart.dart';

import '../../../../helpers/pump_app.dart';

/// The painter draws month labels and the max value directly onto the
/// canvas, so structural assertions stick to the [CustomPaint] widget
/// itself and to its painter's exposed runtimeType.
///
/// Filtering by `painter.runtimeType.toString().contains('CostTrend')`
/// keeps us isolated from the framework-supplied [CustomPaint]s that
/// [Material] / [Scaffold] mount around our subject.
Iterable<CustomPaint> _chartPaints(WidgetTester tester) =>
    tester.widgetList<CustomPaint>(find.byType(CustomPaint)).where(
          (p) => p.painter?.runtimeType.toString().contains('CostTrend') ?? false,
        );

void main() {
  group('ChargingCostTrendChart', () {
    testWidgets(
      'renders the localized empty placeholder when monthlyCost is empty',
      (tester) async {
        await pumpApp(
          tester,
          const ChargingCostTrendChart(monthlyCost: {}),
        );

        // English locale (pumpApp default) → chargingChartsEmpty.
        expect(find.text('Not enough data yet'), findsOneWidget);
        // Empty path uses Center+Text — no chart painter is mounted.
        expect(_chartPaints(tester), isEmpty);
      },
    );

    testWidgets(
      'renders the empty placeholder when every month value is 0.0',
      (tester) async {
        // The provider pads missing months with 0.0; six all-zero months
        // is the realistic "user has no charging logs yet" scenario.
        final monthlyCost = <DateTime, double>{
          DateTime(2026, 1): 0,
          DateTime(2026, 2): 0,
          DateTime(2026, 3): 0,
          DateTime(2026, 4): 0,
          DateTime(2026, 5): 0,
          DateTime(2026, 6): 0,
        };

        await pumpApp(
          tester,
          ChargingCostTrendChart(monthlyCost: monthlyCost),
        );

        expect(find.text('Not enough data yet'), findsOneWidget);
        expect(_chartPaints(tester), isEmpty);
      },
    );

    testWidgets(
      'falls back to the English string when AppLocalizations is absent',
      (tester) async {
        // Pump without localization delegates so .of(context) returns null.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChargingCostTrendChart(monthlyCost: {}),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Not enough data yet'), findsOneWidget);
      },
    );

    testWidgets(
      'paints a single chart painter when given one populated month',
      (tester) async {
        // Single-bar layout exercises the slot/barWidth math at minimum
        // count without tripping the empty-state branch.
        final monthlyCost = <DateTime, double>{
          DateTime(2026, 6): 42.5,
        };

        await pumpApp(
          tester,
          ChargingCostTrendChart(monthlyCost: monthlyCost),
        );

        expect(tester.takeException(), isNull);
        // Empty placeholder text must NOT be present in the populated path.
        expect(find.text('Not enough data yet'), findsNothing);
        expect(_chartPaints(tester), hasLength(1));
      },
    );

    testWidgets(
      'paints a chart when multiple months have non-zero values',
      (tester) async {
        final monthlyCost = <DateTime, double>{
          DateTime(2026, 1): 12.0,
          DateTime(2026, 2): 30.0,
          DateTime(2026, 3): 0.0, // mixed-zero is allowed; ANY > 0 wins
          DateTime(2026, 4): 18.0,
          DateTime(2026, 5): 25.5,
          DateTime(2026, 6): 9.75,
        };

        await pumpApp(
          tester,
          ChargingCostTrendChart(monthlyCost: monthlyCost),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Not enough data yet'), findsNothing);
        // At least one chart-owned painter is mounted.
        expect(_chartPaints(tester).length, greaterThan(0));
      },
    );

    testWidgets(
      'forwards an explicit color override into the painter',
      (tester) async {
        const probeColor = Color(0xFFAA1234);
        final monthlyCost = <DateTime, double>{
          DateTime(2026, 1): 50.0,
          DateTime(2026, 2): 80.0,
        };

        await pumpApp(
          tester,
          ChargingCostTrendChart(
            monthlyCost: monthlyCost,
            color: probeColor,
          ),
        );

        expect(tester.takeException(), isNull);

        final painter = _chartPaints(tester).first.painter;
        // Use dynamic dispatch to inspect the private painter's `color`
        // field — same approach as the carbon MonthlyBarChart precedent.
        // ignore: avoid_dynamic_calls
        final dynamic dyn = painter;
        // ignore: avoid_dynamic_calls
        expect(dyn.color, probeColor);
      },
    );

    testWidgets(
      'falls back to theme.colorScheme.primary when color is null',
      (tester) async {
        const themedPrimary = Color(0xFF00BCD4);
        final monthlyCost = <DateTime, double>{
          DateTime(2026, 5): 5.0,
        };

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: const ColorScheme.light(primary: themedPrimary),
            ),
            home: Scaffold(
              body: ChargingCostTrendChart(monthlyCost: monthlyCost),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((p) => p.painter)
            .firstWhere(
              (p) =>
                  p != null &&
                  p.runtimeType.toString().contains('CostTrend'),
            );

        // ignore: avoid_dynamic_calls
        final dynamic dyn = painter;
        // ignore: avoid_dynamic_calls
        expect(dyn.color, themedPrimary);
      },
    );

    testWidgets(
      'renders without throwing when only a single non-zero entry exists',
      (tester) async {
        // Edge case: provider has padded all months with 0 except one,
        // and the painter must avoid div-by-zero on max-value scaling.
        final monthlyCost = <DateTime, double>{
          DateTime(2026, 1): 0,
          DateTime(2026, 2): 0,
          DateTime(2026, 3): 99.99,
          DateTime(2026, 4): 0,
        };

        await pumpApp(
          tester,
          ChargingCostTrendChart(monthlyCost: monthlyCost),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Not enough data yet'), findsNothing);
        expect(_chartPaints(tester).length, greaterThan(0));
      },
    );
  });
}
