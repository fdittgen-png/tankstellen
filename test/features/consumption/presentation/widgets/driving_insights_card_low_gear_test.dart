import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/driving_insight.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/driving_insights_card.dart';

import '../../../../helpers/pump_app.dart';

/// Coverage for the gear-coaching row added to [DrivingInsightsCard]
/// in #1263 phase 3.
///
/// The row surfaces `TripSummary.secondsBelowOptimalGear` (computed by
/// `gear_inference.dart` in phase 1, persisted in phase 2) when the
/// metric is non-null and strictly greater than 60s. Below the
/// threshold, the row stays hidden so noisy short bursts don't dilute
/// the coaching signal.
void main() {
  const lowGearKey = ValueKey('insight_tile_insightLowGear');

  group('DrivingInsightsCard — gear-coaching row visibility', () {
    testWidgets('hidden when secondsBelowOptimalGear is null',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingInsightsCard(insights: []),
      );

      expect(find.byKey(lowGearKey), findsNothing);
      expect(find.textContaining('Labouring'), findsNothing);
    });

    testWidgets('hidden at the boundary — 60.0 is NOT > 60',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingInsightsCard(
          insights: [],
          secondsBelowOptimalGear: 60.0,
        ),
      );

      expect(find.byKey(lowGearKey), findsNothing);
      expect(find.textContaining('Labouring'), findsNothing);
    });

    testWidgets('rendered when secondsBelowOptimalGear is 65 — shows "1 min"',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingInsightsCard(
          insights: [],
          secondsBelowOptimalGear: 65.0,
        ),
      );

      expect(find.byKey(lowGearKey), findsOneWidget);
      expect(
        find.text('Labouring in low gear (1 min)'),
        findsOneWidget,
      );
    });

    testWidgets('rendered when secondsBelowOptimalGear is 180 — shows "3 min"',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingInsightsCard(
          insights: [],
          secondsBelowOptimalGear: 180.0,
        ),
      );

      expect(find.byKey(lowGearKey), findsOneWidget);
      expect(
        find.text('Labouring in low gear (3 min)'),
        findsOneWidget,
      );
    });

    testWidgets(
        'when fired with no other insights, replaces empty-state — no '
        '"keep it up" copy', (tester) async {
      await pumpApp(
        tester,
        const DrivingInsightsCard(
          insights: [],
          secondsBelowOptimalGear: 180.0,
        ),
      );

      expect(find.byKey(lowGearKey), findsOneWidget);
      expect(
        find.text('No notable inefficiencies — keep it up!'),
        findsNothing,
      );
    });

    testWidgets(
        'when fired alongside non-empty insights, BOTH render — gear row '
        'first', (tester) async {
      const insights = [
        DrivingInsight(
          labelKey: 'insightHighRpm',
          litersWasted: 0.6,
          percentOfTrip: 12.0,
        ),
      ];

      await pumpApp(
        tester,
        const DrivingInsightsCard(
          insights: insights,
          secondsBelowOptimalGear: 180.0,
        ),
      );

      // Both rows present.
      expect(find.byKey(lowGearKey), findsOneWidget);
      expect(
        find.text('Labouring in low gear (3 min)'),
        findsOneWidget,
      );
      expect(
        find.text('Engine over 3000 RPM (12% of trip): wasted 0.6 L'),
        findsOneWidget,
      );
      // ListTile count: gear row + 1 insight tile.
      expect(find.byType(ListTile), findsNWidgets(2));

      // Gear row precedes the insight tile vertically (smaller dy).
      final gearTopLeft = tester.getTopLeft(find.byKey(lowGearKey));
      final insightTopLeft = tester.getTopLeft(
        find.text('Engine over 3000 RPM (12% of trip): wasted 0.6 L'),
      );
      expect(gearTopLeft.dy, lessThan(insightTopLeft.dy));
    });

    testWidgets('gear row does NOT carry a trailing "+x L" badge',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingInsightsCard(
          insights: [],
          secondsBelowOptimalGear: 180.0,
        ),
      );

      final tile = tester.widget<ListTile>(find.byKey(lowGearKey));
      expect(tile.trailing, isNull);
    });
  });
}
