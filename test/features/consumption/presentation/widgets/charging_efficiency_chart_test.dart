import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/charging_efficiency_chart.dart';

import '../../../../helpers/pump_app.dart';

/// The chart paints lines and dots directly onto the canvas (no Text widgets
/// for the data series), so structural assertions stick to the [CustomPaint]
/// widget itself plus the empty-state caption.
///
/// Companion to [MonthlyBarChart] tests; covers the Charging-tab efficiency
/// line chart added in #582 phase 3 (lib/features/consumption/presentation/
/// widgets/charging_efficiency_chart.dart).
void main() {
  group('ChargingEfficiencyChart', () {
    testWidgets(
      'renders the localized empty caption when monthlyEfficiency is empty',
      (tester) async {
        await pumpApp(
          tester,
          const ChargingEfficiencyChart(monthlyEfficiency: {}),
        );

        // English locale (pumpApp default) → chargingChartsEmpty.
        expect(find.text('Not enough data yet'), findsOneWidget);

        // No data-series painter is mounted on the empty path.
        final paints = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .where(
              (p) => p.painter.runtimeType.toString().contains('Efficiency'),
            )
            .toList();
        expect(paints, isEmpty);
      },
    );

    testWidgets(
      'renders the empty caption when every value in the map is null',
      (tester) async {
        // Even with non-empty entries, an all-null map must take the same
        // empty branch — `points.isEmpty` short-circuits the painter.
        final allNull = <DateTime, double?>{
          DateTime(2026, 1): null,
          DateTime(2026, 2): null,
          DateTime(2026, 3): null,
        };

        await pumpApp(
          tester,
          ChargingEfficiencyChart(monthlyEfficiency: allNull),
        );

        expect(find.text('Not enough data yet'), findsOneWidget);

        final paints = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .where(
              (p) => p.painter.runtimeType.toString().contains('Efficiency'),
            )
            .toList();
        expect(paints, isEmpty);
      },
    );

    testWidgets(
      'falls back to "Not enough data yet" when AppLocalizations is absent',
      (tester) async {
        // No localization delegates → AppLocalizations.of(context) is null,
        // so the widget must use its hard-coded English fallback string.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChargingEfficiencyChart(monthlyEfficiency: {}),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Not enough data yet'), findsOneWidget);
      },
    );

    testWidgets(
      'uses the German translation for the empty caption',
      (tester) async {
        await pumpApp(
          tester,
          const ChargingEfficiencyChart(monthlyEfficiency: {}),
          locale: const Locale('de'),
        );

        expect(find.text('Noch nicht genügend Daten'), findsOneWidget);
      },
    );

    testWidgets(
      'renders a CustomPaint with a painter when one non-null month exists',
      (tester) async {
        // Single-point layout exercises the entries.length == 1 branch
        // inside `xForIndex` (centre of chart instead of normalised stride).
        final data = <DateTime, double?>{
          DateTime(2026, 6): 17.5,
        };

        await pumpApp(
          tester,
          ChargingEfficiencyChart(monthlyEfficiency: data),
        );

        // Must not fall back to the empty-state text on a non-null sample.
        expect(find.text('Not enough data yet'), findsNothing);
        expect(tester.takeException(), isNull);

        final painters = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((p) => p.painter)
            .where(
              (p) =>
                  p != null && p.runtimeType.toString().contains('Efficiency'),
            )
            .toList();
        expect(painters, hasLength(1));
      },
    );

    testWidgets(
      'renders without throwing for multiple months with mixed nulls',
      (tester) async {
        // The line bridges null months: the painter still iterates every
        // entry but only moves the path / draws dots for non-null values.
        final data = <DateTime, double?>{
          DateTime(2025, 11): 18.2,
          DateTime(2025, 12): null,
          DateTime(2026, 1): 19.1,
          DateTime(2026, 2): 17.4,
          DateTime(2026, 3): null,
          DateTime(2026, 4): 16.9,
        };

        await pumpApp(
          tester,
          ChargingEfficiencyChart(monthlyEfficiency: data),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Not enough data yet'), findsNothing);

        final painters = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((p) => p.painter)
            .where(
              (p) =>
                  p != null && p.runtimeType.toString().contains('Efficiency'),
            )
            .toList();
        expect(painters, hasLength(1));
      },
    );

    testWidgets(
      'forwards an explicit color override into the painter',
      (tester) async {
        const probeColor = Color(0xFF00C0AA);
        final data = <DateTime, double?>{
          DateTime(2026, 1): 15.0,
          DateTime(2026, 2): 17.0,
          DateTime(2026, 3): 14.5,
        };

        await pumpApp(
          tester,
          ChargingEfficiencyChart(
            monthlyEfficiency: data,
            color: probeColor,
          ),
        );

        expect(tester.takeException(), isNull);

        final painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((p) => p.painter)
            .firstWhere(
              (p) =>
                  p != null && p.runtimeType.toString().contains('Efficiency'),
            );

        // Inspect the private painter's exposed `color` field via dynamic
        // dispatch — the painter type is intentionally library-private.
        // ignore: avoid_dynamic_calls
        final dynamic dyn = painter;
        // ignore: avoid_dynamic_calls
        expect(dyn.color, probeColor);
        // ignore: avoid_dynamic_calls
        expect((dyn.entries as List).length, data.length);
      },
    );

    testWidgets(
      'falls back to theme.colorScheme.primary when no color is provided',
      (tester) async {
        const themePrimary = Color(0xFF8844EE);
        final data = <DateTime, double?>{
          DateTime(2026, 1): 12.0,
          DateTime(2026, 2): 13.5,
        };

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              colorScheme: const ColorScheme.light(primary: themePrimary),
            ),
            home: Scaffold(
              body: ChargingEfficiencyChart(monthlyEfficiency: data),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((p) => p.painter)
            .firstWhere(
              (p) =>
                  p != null && p.runtimeType.toString().contains('Efficiency'),
            );

        // ignore: avoid_dynamic_calls
        expect((painter as dynamic).color, themePrimary);
      },
    );

    testWidgets(
      'handles unsorted month keys by ordering ascending before painting',
      (tester) async {
        // Map iteration order of DateTime keys depends on insertion; the
        // widget sorts entries before forwarding them to the painter, so a
        // descending-input map must still paint without throwing.
        final unordered = <DateTime, double?>{
          DateTime(2026, 4): 14.0,
          DateTime(2026, 1): 16.0,
          DateTime(2026, 3): null,
          DateTime(2026, 2): 15.5,
        };

        await pumpApp(
          tester,
          ChargingEfficiencyChart(monthlyEfficiency: unordered),
        );

        expect(tester.takeException(), isNull);

        final painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((p) => p.painter)
            .firstWhere(
              (p) =>
                  p != null && p.runtimeType.toString().contains('Efficiency'),
            );

        // ignore: avoid_dynamic_calls
        final entries = (painter as dynamic).entries as List;
        // Painter must receive entries in ascending key order.
        for (var i = 1; i < entries.length; i++) {
          // ignore: avoid_dynamic_calls
          final prev = entries[i - 1].key as DateTime;
          // ignore: avoid_dynamic_calls
          final curr = entries[i].key as DateTime;
          expect(
            prev.compareTo(curr) <= 0,
            isTrue,
            reason: 'painter entries must be sorted ascending by month',
          );
        }
      },
    );

    testWidgets(
      'rebuilds with new props when the efficiency map reference changes',
      (tester) async {
        final initial = <DateTime, double?>{
          DateTime(2026, 1): 12.0,
          DateTime(2026, 2): 14.0,
        };
        final next = <DateTime, double?>{
          DateTime(2026, 3): 11.0,
          DateTime(2026, 4): 13.0,
          DateTime(2026, 5): 15.0,
        };

        await pumpApp(
          tester,
          ChargingEfficiencyChart(monthlyEfficiency: initial),
        );

        var painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((p) => p.painter)
            .firstWhere(
              (p) =>
                  p != null && p.runtimeType.toString().contains('Efficiency'),
            );
        // ignore: avoid_dynamic_calls
        expect(((painter as dynamic).entries as List).length, 2);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChargingEfficiencyChart(monthlyEfficiency: next),
            ),
          ),
        );
        await tester.pumpAndSettle();

        painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((p) => p.painter)
            .firstWhere(
              (p) =>
                  p != null && p.runtimeType.toString().contains('Efficiency'),
            );
        // ignore: avoid_dynamic_calls
        expect(((painter as dynamic).entries as List).length, 3);
      },
    );
  });
}

