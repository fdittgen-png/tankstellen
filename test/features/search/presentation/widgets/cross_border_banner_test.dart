import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/cross_border_comparison.dart';
import 'package:tankstellen/features/search/presentation/widgets/cross_border_banner.dart';
import 'package:tankstellen/features/search/providers/cross_border_provider.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('CrossBorderBanner', () {
    testWidgets('shows nothing when no comparisons', (tester) async {
      await pumpApp(
        tester,
        const CrossBorderBanner(),
        overrides: [
          crossBorderComparisonsProvider.overrideWith((ref) => const []),
        ],
      );

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('shows banner with neighbor info', (tester) async {
      final comparisons = [
        const CrossBorderComparison(
          neighborCode: 'FR',
          neighborName: 'France',
          neighborFlag: '\u{1F1EB}\u{1F1F7}',
          neighborCurrency: '\u20ac',
          currentAvgPrice: 1.850,
          borderDistanceKm: 12.5,
          stationCount: 5,
        ),
      ];

      await pumpApp(
        tester,
        const CrossBorderBanner(),
        overrides: [
          crossBorderComparisonsProvider.overrideWith((ref) => comparisons),
        ],
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('France is nearby'), findsOneWidget);
      expect(find.text('~13 km to border'), findsOneWidget);
      expect(
        find.text('Avg here: 1.850 EUR (5 stations)'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.compare_arrows), findsOneWidget);
    });

    testWidgets('shows multiple banners for multiple neighbors', (tester) async {
      final comparisons = [
        const CrossBorderComparison(
          neighborCode: 'FR',
          neighborName: 'France',
          neighborFlag: '\u{1F1EB}\u{1F1F7}',
          neighborCurrency: '\u20ac',
          currentAvgPrice: 1.800,
          borderDistanceKm: 10.0,
          stationCount: 3,
        ),
        const CrossBorderComparison(
          neighborCode: 'AT',
          neighborName: '\u00d6sterreich',
          neighborFlag: '\u{1F1E6}\u{1F1F9}',
          neighborCurrency: '\u20ac',
          currentAvgPrice: 1.800,
          borderDistanceKm: 25.0,
          stationCount: 3,
        ),
      ];

      await pumpApp(
        tester,
        const CrossBorderBanner(),
        overrides: [
          crossBorderComparisonsProvider.overrideWith((ref) => comparisons),
        ],
      );

      expect(find.byType(Card), findsNWidgets(2));
      expect(find.text('France is nearby'), findsOneWidget);
      expect(find.text('\u00d6sterreich is nearby'), findsOneWidget);
    });

    testWidgets('rounds distance correctly', (tester) async {
      final comparisons = [
        const CrossBorderComparison(
          neighborCode: 'DK',
          neighborName: 'Danmark',
          neighborFlag: '\u{1F1E9}\u{1F1F0}',
          neighborCurrency: 'kr',
          currentAvgPrice: 1.650,
          borderDistanceKm: 7.3,
          stationCount: 2,
        ),
      ];

      await pumpApp(
        tester,
        const CrossBorderBanner(),
        overrides: [
          crossBorderComparisonsProvider.overrideWith((ref) => comparisons),
        ],
      );

      expect(find.text('~7 km to border'), findsOneWidget);
    });

    testWidgets('meets tap target guidelines', (tester) async {
      await pumpApp(
        tester,
        const CrossBorderBanner(),
        overrides: [
          crossBorderComparisonsProvider.overrideWith((ref) => const []),
        ],
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });
}
