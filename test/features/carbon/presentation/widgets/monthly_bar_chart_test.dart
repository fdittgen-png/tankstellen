import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/carbon/domain/monthly_summary.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/monthly_bar_chart.dart';

import '../../../../helpers/pump_app.dart';

/// Builds a minimal [MonthlySummary] with sane defaults; only the fields
/// relevant to the chart's external contract are configurable.
MonthlySummary _summary({
  required DateTime month,
  double cost = 0,
  double liters = 0,
  double co2 = 0,
  int count = 0,
}) =>
    MonthlySummary(
      month: month,
      totalCost: cost,
      totalLiters: liters,
      totalCo2Kg: co2,
      fillUpCount: count,
    );

double _co2(MonthlySummary s) => s.totalCo2Kg;
double _cost(MonthlySummary s) => s.totalCost;

/// The chart paints its labels directly onto the canvas (no Text widgets),
/// so structural assertions stick to the [CustomPaint] widget itself and
/// to the painter's exposed fields.
void main() {
  group('MonthlyBarChart', () {
    testWidgets(
      'renders the localized empty placeholder when summaries is empty',
      (tester) async {
        await pumpApp(
          tester,
          const MonthlyBarChart(
            summaries: [],
            valueOf: _co2,
            color: Colors.green,
            unitLabel: 'kg',
          ),
        );

        // English locale (pumpApp default) → noDataAvailable == 'No data'.
        expect(find.text('No data'), findsOneWidget);
        // The placeholder is built around a Center + Text, NOT a CustomPaint.
        // Filter out the Material framework-supplied CustomPaints by asserting
        // there is no painter whose chart bars would have been drawn.
        final paints = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .where((p) => p.painter.runtimeType.toString().contains('BarChart'))
            .toList();
        expect(paints, isEmpty);
      },
    );

    testWidgets(
      'falls back to "No data" when AppLocalizations is absent',
      (tester) async {
        // Pump without localization delegates so .of(context) returns null.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MonthlyBarChart(
                summaries: [],
                valueOf: _co2,
                color: Colors.green,
                unitLabel: 'kg',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No data'), findsOneWidget);
      },
    );

    testWidgets(
      'uses the French translation for the empty placeholder',
      (tester) async {
        await pumpApp(
          tester,
          const MonthlyBarChart(
            summaries: [],
            valueOf: _co2,
            color: Colors.green,
            unitLabel: 'kg',
          ),
          locale: const Locale('fr'),
        );

        expect(find.text('Pas de données'), findsOneWidget);
      },
    );

    testWidgets(
      'renders a single CustomPaint with a painter when summaries are present',
      (tester) async {
        final summaries = [
          _summary(month: DateTime(2026, 1), co2: 12),
          _summary(month: DateTime(2026, 2), co2: 30),
          _summary(month: DateTime(2026, 3), co2: 18),
        ];

        await pumpApp(
          tester,
          MonthlyBarChart(
            summaries: summaries,
            valueOf: _co2,
            color: Colors.green,
            unitLabel: 'kg',
          ),
        );

        // Empty placeholder text must NOT be present in the populated path.
        expect(find.text('No data'), findsNothing);

        // Exactly one chart-owned painter is mounted (a private subclass of
        // CustomPainter — match by runtimeType name to avoid leaking it).
        final painters = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((p) => p.painter)
            .where((p) => p != null && p.runtimeType.toString().contains('BarChart'))
            .toList();
        expect(painters, hasLength(1));
      },
    );

    testWidgets(
      'forwards color and unitLabel into the painter',
      (tester) async {
        const probeColor = Color(0xFF112233);
        const probeUnit = '€';
        final summaries = [
          _summary(month: DateTime(2026, 1), cost: 50),
          _summary(month: DateTime(2026, 2), cost: 80),
        ];

        await pumpApp(
          tester,
          MonthlyBarChart(
            summaries: summaries,
            valueOf: _cost,
            color: probeColor,
            unitLabel: probeUnit,
          ),
        );

        final painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((p) => p.painter)
            .firstWhere(
              (p) => p != null && p.runtimeType.toString().contains('BarChart'),
            );

        // Use dynamic dispatch to inspect the private painter's public fields.
        // ignore: avoid_dynamic_calls
        final dynamic dyn = painter;
        // ignore: avoid_dynamic_calls
        expect(dyn.color, probeColor);
        // ignore: avoid_dynamic_calls
        expect(dyn.unitLabel, probeUnit);
        // ignore: avoid_dynamic_calls
        expect((dyn.summaries as List).length, summaries.length);
      },
    );

    testWidgets(
      'invokes valueOf for every summary when painted',
      (tester) async {
        var calls = 0;
        double counting(MonthlySummary s) {
          calls++;
          return s.totalCo2Kg;
        }

        final summaries = [
          _summary(month: DateTime(2026, 1), co2: 5),
          _summary(month: DateTime(2026, 2), co2: 7),
          _summary(month: DateTime(2026, 3), co2: 9),
          _summary(month: DateTime(2026, 4), co2: 11),
        ];

        await pumpApp(
          tester,
          MonthlyBarChart(
            summaries: summaries,
            valueOf: counting,
            color: Colors.blue,
            unitLabel: 'kg',
          ),
        );

        // Painter calls valueOf once per summary inside its `paint` method;
        // a single layout/paint cycle must hit every entry at least once.
        expect(
          calls,
          greaterThanOrEqualTo(summaries.length),
          reason: 'painter must call valueOf at least once per summary',
        );
      },
    );

    testWidgets(
      'renders without throwing when every value is zero',
      (tester) async {
        final summaries = [
          _summary(month: DateTime(2026, 1), co2: 0),
          _summary(month: DateTime(2026, 2), co2: 0),
          _summary(month: DateTime(2026, 3), co2: 0),
        ];

        await pumpApp(
          tester,
          MonthlyBarChart(
            summaries: summaries,
            valueOf: _co2,
            color: Colors.red,
            unitLabel: 'kg',
          ),
        );

        // No exceptions surface to the test binding when all values are 0.
        expect(tester.takeException(), isNull);

        // Painter is still mounted (we don't fall back to the empty path).
        final painters = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((p) => p.painter)
            .where((p) => p != null && p.runtimeType.toString().contains('BarChart'))
            .toList();
        expect(painters, hasLength(1));
      },
    );

    testWidgets(
      'renders without throwing when only one summary is provided',
      (tester) async {
        // Single-bar layout exercises the slot/barWidth math at minimum count.
        final summaries = [
          _summary(month: DateTime(2026, 6), co2: 42),
        ];

        await pumpApp(
          tester,
          MonthlyBarChart(
            summaries: summaries,
            valueOf: _co2,
            color: Colors.orange,
            unitLabel: 'kg',
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('No data'), findsNothing);
      },
    );

    testWidgets(
      'fixed 180dp height is preserved regardless of available space',
      (tester) async {
        await pumpApp(
          tester,
          MonthlyBarChart(
            summaries: [
              _summary(month: DateTime(2026, 1), co2: 1),
              _summary(month: DateTime(2026, 2), co2: 2),
            ],
            valueOf: _co2,
            color: Colors.teal,
            unitLabel: 'kg',
          ),
        );

        final size = tester.getSize(find.byType(MonthlyBarChart));
        expect(size.height, 180.0);
      },
    );

    testWidgets(
      'empty-state placeholder also uses the 180dp height contract',
      (tester) async {
        await pumpApp(
          tester,
          const MonthlyBarChart(
            summaries: [],
            valueOf: _co2,
            color: Colors.teal,
            unitLabel: 'kg',
          ),
        );

        final size = tester.getSize(find.byType(MonthlyBarChart));
        expect(size.height, 180.0);
      },
    );

    testWidgets(
      'rebuilds with new props when summaries reference changes',
      (tester) async {
        final initial = [
          _summary(month: DateTime(2026, 1), co2: 5),
          _summary(month: DateTime(2026, 2), co2: 10),
        ];
        final next = [
          _summary(month: DateTime(2026, 3), co2: 7),
          _summary(month: DateTime(2026, 4), co2: 14),
          _summary(month: DateTime(2026, 5), co2: 21),
        ];

        await pumpApp(
          tester,
          MonthlyBarChart(
            summaries: initial,
            valueOf: _co2,
            color: Colors.purple,
            unitLabel: 'kg',
          ),
        );

        // ignore: avoid_dynamic_calls
        var painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((p) => p.painter)
            .firstWhere(
              (p) => p != null && p.runtimeType.toString().contains('BarChart'),
            );
        // ignore: avoid_dynamic_calls
        expect(((painter as dynamic).summaries as List).length, 2);

        // Re-pump with a different summaries list — same widget type, new data.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MonthlyBarChart(
                summaries: next,
                valueOf: _co2,
                color: Colors.purple,
                unitLabel: 'kg',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((p) => p.painter)
            .firstWhere(
              (p) => p != null && p.runtimeType.toString().contains('BarChart'),
            );
        // ignore: avoid_dynamic_calls
        expect(((painter as dynamic).summaries as List).length, 3);
      },
    );
  });
}
