import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/alert_statistics_card.dart';
import 'package:tankstellen/features/alerts/providers/alert_statistics_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('AlertStatisticsCard', () {
    testWidgets('renders three stat columns', (tester) async {
      final test = standardTestOverrides();

      await pumpApp(
        tester,
        const AlertStatisticsCard(),
        overrides: [
          ...test.overrides,
          alertStatisticsProvider.overrideWithValue(
            const AlertStatistics(
              totalAlerts: 5,
              activeAlerts: 3,
              triggeredToday: 1,
              triggeredThisWeek: 4,
            ),
          ),
        ],
      );

      // Active count
      expect(find.text('3'), findsOneWidget);
      // Today count
      expect(find.text('1'), findsOneWidget);
      // This week count
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('displays localized labels', (tester) async {
      final test = standardTestOverrides();

      await pumpApp(
        tester,
        const AlertStatisticsCard(),
        overrides: [
          ...test.overrides,
          alertStatisticsProvider.overrideWithValue(
            const AlertStatistics.empty(),
          ),
        ],
      );

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This week'), findsOneWidget);
    });

    testWidgets('shows zero values for empty stats', (tester) async {
      final test = standardTestOverrides();

      await pumpApp(
        tester,
        const AlertStatisticsCard(),
        overrides: [
          ...test.overrides,
          alertStatisticsProvider.overrideWithValue(
            const AlertStatistics.empty(),
          ),
        ],
      );

      expect(find.text('0'), findsNWidgets(3));
    });

    testWidgets('renders inside a Card', (tester) async {
      final test = standardTestOverrides();

      await pumpApp(
        tester,
        const AlertStatisticsCard(),
        overrides: [
          ...test.overrides,
          alertStatisticsProvider.overrideWithValue(
            const AlertStatistics.empty(),
          ),
        ],
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows correct icons', (tester) async {
      final test = standardTestOverrides();

      await pumpApp(
        tester,
        const AlertStatisticsCard(),
        overrides: [
          ...test.overrides,
          alertStatisticsProvider.overrideWithValue(
            const AlertStatistics.empty(),
          ),
        ],
      );

      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      expect(find.byIcon(Icons.today), findsOneWidget);
      expect(find.byIcon(Icons.date_range), findsOneWidget);
    });
  });
}
