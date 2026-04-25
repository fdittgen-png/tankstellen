import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/driving_insight.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/driving_insights_card.dart';

import '../../../../helpers/pump_app.dart';

/// Widget-level coverage for [DrivingInsightsCard] (#1041 phase 2).
///
/// The card is purely presentational — it takes the analyzer's already
/// sorted, capped output and turns it into ListTile rows. The tests
/// therefore lock down formatting (one-decimal litres, whole-number
/// percent), the empty-state copy, and the localized title; the
/// ranking/cap behaviour stays in the analyzer's own test file.
void main() {
  group('DrivingInsightsCard — title', () {
    testWidgets('renders the localized "Top wasteful behaviours" title',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingInsightsCard(insights: []),
      );

      expect(find.text('Top wasteful behaviours'), findsOneWidget);
    });
  });

  group('DrivingInsightsCard — empty state', () {
    testWidgets('renders the empty-state copy when insights is empty',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingInsightsCard(insights: []),
      );

      expect(
        find.text('No notable inefficiencies — keep it up!'),
        findsOneWidget,
      );
    });

    testWidgets('does not render any insight tiles when insights is empty',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingInsightsCard(insights: []),
      );

      expect(find.byType(ListTile), findsNothing);
    });
  });

  group('DrivingInsightsCard — populated', () {
    testWidgets('renders one ListTile per insight', (tester) async {
      const insights = [
        DrivingInsight(
          labelKey: 'insightHighRpm',
          litersWasted: 0.6,
          percentOfTrip: 12.0,
        ),
        DrivingInsight(
          labelKey: 'insightHardAccel',
          litersWasted: 0.2,
          percentOfTrip: 4.0,
          metadata: {'eventCount': 4},
        ),
        DrivingInsight(
          labelKey: 'insightIdling',
          litersWasted: 0.1,
          percentOfTrip: 8.0,
        ),
      ];

      await pumpApp(
        tester,
        const DrivingInsightsCard(insights: insights),
      );

      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('does not render the empty-state when insights is non-empty',
        (tester) async {
      const insights = [
        DrivingInsight(
          labelKey: 'insightHighRpm',
          litersWasted: 0.6,
          percentOfTrip: 12.0,
        ),
      ];

      await pumpApp(
        tester,
        const DrivingInsightsCard(insights: insights),
      );

      expect(
        find.text('No notable inefficiencies — keep it up!'),
        findsNothing,
      );
    });

    testWidgets('formats liters to one decimal — "0.6 L", not "0.6000 L"',
        (tester) async {
      const insights = [
        DrivingInsight(
          labelKey: 'insightHighRpm',
          litersWasted: 0.6234,
          percentOfTrip: 12.0,
        ),
      ];

      await pumpApp(
        tester,
        const DrivingInsightsCard(insights: insights),
      );

      // Trailing badge — one-decimal precision.
      expect(find.text('+0.6 L'), findsOneWidget);
      // No four-decimal leak.
      expect(find.textContaining('0.6234'), findsNothing);
    });

    testWidgets('renders the localized high-RPM headline with placeholders',
        (tester) async {
      const insights = [
        DrivingInsight(
          labelKey: 'insightHighRpm',
          litersWasted: 0.6,
          percentOfTrip: 12.0,
        ),
      ];

      await pumpApp(
        tester,
        const DrivingInsightsCard(insights: insights),
      );

      // Headline copy with both placeholders rendered.
      expect(
        find.text('Engine over 3000 RPM (12% of trip): wasted 0.6 L'),
        findsOneWidget,
      );
    });

    testWidgets(
        'renders hard-accel headline with eventCount from metadata',
        (tester) async {
      const insights = [
        DrivingInsight(
          labelKey: 'insightHardAccel',
          litersWasted: 0.2,
          percentOfTrip: 4.0,
          metadata: {'eventCount': 4},
        ),
      ];

      await pumpApp(
        tester,
        const DrivingInsightsCard(insights: insights),
      );

      expect(
        find.text('4 hard accelerations: wasted 0.2 L'),
        findsOneWidget,
      );
    });

    testWidgets('renders the idling headline with percent placeholder',
        (tester) async {
      const insights = [
        DrivingInsight(
          labelKey: 'insightIdling',
          litersWasted: 0.3,
          percentOfTrip: 25.0,
        ),
      ];

      await pumpApp(
        tester,
        const DrivingInsightsCard(insights: insights),
      );

      expect(
        find.text('Idling (25% of trip): wasted 0.3 L'),
        findsOneWidget,
      );
    });

    testWidgets('subtitle shows "{pct}% of trip" beneath each tile',
        (tester) async {
      const insights = [
        DrivingInsight(
          labelKey: 'insightHighRpm',
          litersWasted: 0.6,
          percentOfTrip: 12.0,
        ),
      ];

      await pumpApp(
        tester,
        const DrivingInsightsCard(insights: insights),
      );

      expect(find.text('12% of trip'), findsOneWidget);
    });

    testWidgets('preserves insight order (analyzer is the source of truth)',
        (tester) async {
      // Smallest waste first — the card MUST NOT re-sort. The analyzer
      // owns ordering so future ranking tweaks (#1041 phase 4) ship
      // without UI edits.
      const insights = [
        DrivingInsight(
          labelKey: 'insightIdling',
          litersWasted: 0.1,
          percentOfTrip: 8.0,
        ),
        DrivingInsight(
          labelKey: 'insightHardAccel',
          litersWasted: 0.9,
          percentOfTrip: 4.0,
          metadata: {'eventCount': 18},
        ),
      ];

      await pumpApp(
        tester,
        const DrivingInsightsCard(insights: insights),
      );

      final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(tiles, hasLength(2));
      // First tile renders the idling headline.
      expect(
        ((tiles[0].title as Text).data),
        contains('Idling'),
      );
      // Second tile renders the hard-accel headline.
      expect(
        ((tiles[1].title as Text).data),
        contains('hard accelerations'),
      );
    });
  });
}
