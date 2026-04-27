import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/services/monthly_insights_aggregator.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/monthly_insights_card.dart';

import '../../../../helpers/pump_app.dart';

/// Widget-level coverage for [MonthlyInsightsCard] (#1041 phase 4).
///
/// The card is purely presentational — it renders the summary value
/// produced by `aggregateMonthlyInsights`. The aggregator's bucketing
/// + reliability logic is locked down in its own unit-test file; here
/// we cover the rendering contract:
///   * three (or four) labelled rows render with localized labels
///   * reliable comparison shows previous-month values + delta arrows
///   * unreliable comparison hides previous values + arrows and shows
///     the "Need at least 3 trips per month" caption
///   * avg consumption row only renders when current month has a value
void main() {
  group('MonthlyInsightsCard — title', () {
    testWidgets('renders the localized title', (tester) async {
      await pumpApp(
        tester,
        const MonthlyInsightsCard(summary: MonthlyInsightsSummary.empty),
      );

      expect(find.text('This month vs last month'), findsOneWidget);
    });
  });

  group('MonthlyInsightsCard — reliable comparison', () {
    const reliableSummary = MonthlyInsightsSummary(
      currentMonthTripCount: 8,
      previousMonthTripCount: 5,
      currentMonthDriveTime: Duration(hours: 4, minutes: 15),
      previousMonthDriveTime: Duration(hours: 2, minutes: 30),
      currentMonthDistanceKm: 240.0,
      previousMonthDistanceKm: 180.0,
      currentMonthAvgConsumptionLPer100km: 6.0,
      previousMonthAvgConsumptionLPer100km: 7.0,
      isComparisonReliable: true,
    );

    testWidgets('renders all four metric labels', (tester) async {
      await pumpApp(
        tester,
        const MonthlyInsightsCard(summary: reliableSummary),
      );

      expect(find.text('Trips'), findsOneWidget);
      expect(find.text('Drive time'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Avg consumption'), findsOneWidget);
    });

    testWidgets('renders both current and previous values for each row',
        (tester) async {
      await pumpApp(
        tester,
        const MonthlyInsightsCard(summary: reliableSummary),
      );

      // Trip count
      expect(find.text('8'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      // Distance — formatted whole-number above 10 km.
      expect(find.text('240 km'), findsOneWidget);
      expect(find.text('180 km'), findsOneWidget);
      // Avg consumption — one-decimal L/100.
      expect(find.text('6.0 L/100'), findsOneWidget);
      expect(find.text('7.0 L/100'), findsOneWidget);
    });

    testWidgets('renders delta arrows when values differ', (tester) async {
      await pumpApp(
        tester,
        const MonthlyInsightsCard(summary: reliableSummary),
      );

      // Trip count rose (8 vs 5) → up arrow (neutral grey).
      expect(find.byIcon(Icons.arrow_upward), findsWidgets);
      // Avg consumption fell (6 vs 7) → down arrow.
      expect(find.byIcon(Icons.arrow_downward), findsWidgets);
    });

    testWidgets('does not render the unreliable-comparison caption',
        (tester) async {
      await pumpApp(
        tester,
        const MonthlyInsightsCard(summary: reliableSummary),
      );

      expect(
        find.text('Need at least 3 trips per month for comparison'),
        findsNothing,
      );
    });
  });

  group('MonthlyInsightsCard — unreliable comparison', () {
    const unreliableSummary = MonthlyInsightsSummary(
      currentMonthTripCount: 1,
      previousMonthTripCount: 0,
      currentMonthDriveTime: Duration(minutes: 15),
      previousMonthDriveTime: Duration.zero,
      currentMonthDistanceKm: 7.0,
      previousMonthDistanceKm: 0.0,
      currentMonthAvgConsumptionLPer100km: null,
      previousMonthAvgConsumptionLPer100km: null,
      isComparisonReliable: false,
    );

    testWidgets('renders the caption explaining the comparison is hidden',
        (tester) async {
      await pumpApp(
        tester,
        const MonthlyInsightsCard(summary: unreliableSummary),
      );

      expect(
        find.text('Need at least 3 trips per month for comparison'),
        findsOneWidget,
      );
    });

    testWidgets('renders only current-month values, never the previous '
        '"0" placeholder', (tester) async {
      await pumpApp(
        tester,
        const MonthlyInsightsCard(summary: unreliableSummary),
      );

      // Current month: 1 trip, 15 min, 7.0 km. All visible.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('15 min'), findsOneWidget);
      expect(find.text('7.0 km'), findsOneWidget);
      // Previous-month "0" / "0 min" / "0.0 km" must NOT render — the
      // reliability gate hides the previous column entirely.
      expect(find.text('0'), findsNothing);
      expect(find.text('0 min'), findsNothing);
      expect(find.text('0.0 km'), findsNothing);
    });

    testWidgets('does not render delta arrows when comparison is unreliable',
        (tester) async {
      await pumpApp(
        tester,
        const MonthlyInsightsCard(summary: unreliableSummary),
      );

      expect(find.byIcon(Icons.arrow_upward), findsNothing);
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
    });

    testWidgets('hides the avg-consumption row when current value is null',
        (tester) async {
      await pumpApp(
        tester,
        const MonthlyInsightsCard(summary: unreliableSummary),
      );

      // The label only renders alongside a value — no value, no row.
      expect(find.text('Avg consumption'), findsNothing);
    });
  });

  group('MonthlyInsightsCard — empty summary', () {
    testWidgets('renders the unreliable caption + zeroed current values',
        (tester) async {
      await pumpApp(
        tester,
        const MonthlyInsightsCard(summary: MonthlyInsightsSummary.empty),
      );

      expect(
        find.text('Need at least 3 trips per month for comparison'),
        findsOneWidget,
      );
      // Trips: 0, drive time: 0 min, distance: 0.0 km — all current.
      expect(find.text('0'), findsOneWidget);
      expect(find.text('0 min'), findsOneWidget);
      expect(find.text('0.0 km'), findsOneWidget);
    });
  });
}
