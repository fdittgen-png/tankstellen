import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/price_history/data/repositories/price_history_repository.dart';
import 'package:tankstellen/features/price_history/presentation/widgets/price_stats_card.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('PriceStatsCard', () {
    testWidgets('renders min, max, avg values', (tester) async {
      const stats = PriceStats(
        min: 1.399,
        max: 1.559,
        avg: 1.479,
        current: 1.499,
        trend: PriceTrend.stable,
      );

      await pumpApp(
        tester,
        const PriceStatsCard(stats: stats),
      );

      expect(find.text('Min'), findsOneWidget);
      expect(find.text('Max'), findsOneWidget);
      expect(find.text('Avg'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
      expect(find.textContaining('1.399'), findsOneWidget);
      expect(find.textContaining('1.559'), findsOneWidget);
      expect(find.textContaining('1.479'), findsOneWidget);
      expect(find.textContaining('1.499'), findsOneWidget);
    });

    testWidgets('shows trending_up icon when trend is up', (tester) async {
      const stats = PriceStats(
        min: 1.399,
        max: 1.559,
        avg: 1.479,
        current: 1.559,
        trend: PriceTrend.up,
      );

      await pumpApp(
        tester,
        const PriceStatsCard(stats: stats),
      );

      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('shows trending_down icon when trend is down', (tester) async {
      const stats = PriceStats(
        min: 1.399,
        max: 1.559,
        avg: 1.479,
        current: 1.399,
        trend: PriceTrend.down,
      );

      await pumpApp(
        tester,
        const PriceStatsCard(stats: stats),
      );

      expect(find.byIcon(Icons.trending_down), findsOneWidget);
    });

    testWidgets('shows "No statistics available" when stats are empty',
        (tester) async {
      const stats = PriceStats();

      await pumpApp(
        tester,
        const PriceStatsCard(stats: stats),
      );

      expect(find.text('No statistics available'), findsOneWidget);
    });
  });
}
