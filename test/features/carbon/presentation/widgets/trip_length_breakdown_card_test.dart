import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/carbon/presentation/widgets/trip_length_breakdown_card.dart';
import 'package:tankstellen/features/consumption/domain/services/consumption_trip_length_aggregator.dart';

import '../../../../helpers/pump_app.dart';

ConsumptionTripLengthBucketStats _bucket({
  required int tripCount,
  required double totalDistanceKm,
  required double totalLitres,
}) {
  if (tripCount == 0) return ConsumptionTripLengthBucketStats.empty;
  return ConsumptionTripLengthBucketStats(
    tripCount: tripCount,
    totalDistanceKm: totalDistanceKm,
    totalLitres: totalLitres,
    avgLPer100Km: totalDistanceKm > 0
        ? (totalLitres / totalDistanceKm) * 100.0
        : null,
  );
}

void main() {
  group('TripLengthBreakdownCard', () {
    testWidgets(
      'renders three tile states for the issue\'s sample data '
      '(5 short, 0 medium, 7 long)',
      (tester) async {
        // 5 short trips totalling 20 km and 2.5 L → 12.5 L/100 km.
        // 0 medium trips → "need more data" placeholder.
        // 7 long trips totalling 350 km and 21 L → 6.0 L/100 km.
        // Overall: 23.5 L / 370 km * 100 = 6.35 L/100 km — short is
        // above average (arrow_drop_up), long is below (arrow_drop_down).
        final breakdown = ConsumptionTripLengthBreakdown(
          short:
              _bucket(tripCount: 5, totalDistanceKm: 20.0, totalLitres: 2.5),
          medium: ConsumptionTripLengthBucketStats.empty,
          long:
              _bucket(tripCount: 7, totalDistanceKm: 350.0, totalLitres: 21.0),
          overallAvgLPer100Km: 23.5 / 370.0 * 100.0,
        );

        await pumpApp(
          tester,
          TripLengthBreakdownCard(breakdown: breakdown),
        );

        // Three tiles by Key.
        expect(
          find.byKey(const Key('trip_length_bucket_short')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('trip_length_bucket_medium')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('trip_length_bucket_long')),
          findsOneWidget,
        );

        // Card title rendered.
        expect(find.text('Consumption by trip length'), findsOneWidget);

        // Bucket labels.
        expect(find.text('Short'), findsOneWidget);
        expect(find.text('Medium'), findsOneWidget);
        expect(find.text('Long'), findsOneWidget);

        // Short tile: above-average arrow + L/100 km value.
        expect(find.text('12.5 L/100 km'), findsOneWidget);

        // Long tile: below-average arrow + L/100 km value.
        expect(find.text('6.0 L/100 km'), findsOneWidget);

        // Medium tile: 0 trips → "need more data" placeholder.
        expect(
          find.byKey(const Key('trip_length_need_more_data')),
          findsOneWidget,
        );

        // Arrow icons reflect the direction relative to overall average.
        expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);
        expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      },
    );

    testWidgets(
      'shows "need more data" for buckets with fewer than 5 trips',
      (tester) async {
        final breakdown = ConsumptionTripLengthBreakdown(
          // 4 trips — under threshold. Tile must hide the avg.
          short:
              _bucket(tripCount: 4, totalDistanceKm: 12.0, totalLitres: 1.5),
          medium:
              _bucket(tripCount: 5, totalDistanceKm: 60.0, totalLitres: 4.0),
          long: ConsumptionTripLengthBucketStats.empty,
          overallAvgLPer100Km: 5.5 / 72.0 * 100.0,
        );

        await pumpApp(
          tester,
          TripLengthBreakdownCard(breakdown: breakdown),
        );

        // Short tile shows the placeholder; medium tile shows the avg.
        expect(
          find.byKey(const Key('trip_length_need_more_data')),
          // Both short and long have <5 trips → both show placeholder.
          findsNWidgets(2),
        );
        // Medium has 5 trips → 4.0 L / 60 km * 100 = 6.667 ≈ 6.7
        expect(find.text('6.7 L/100 km'), findsOneWidget);
      },
    );

    testWidgets(
      'returns a zero-sized box when every bucket is empty (defence-in-depth)',
      (tester) async {
        const breakdown = ConsumptionTripLengthBreakdown.empty;
        await pumpApp(
          tester,
          const TripLengthBreakdownCard(breakdown: breakdown),
        );

        // Card title must NOT render.
        expect(find.text('Consumption by trip length'), findsNothing);
        // None of the bucket tiles render either.
        expect(
          find.byKey(const Key('trip_length_bucket_short')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('trip_length_bucket_medium')),
          findsNothing,
        );
        expect(
          find.byKey(const Key('trip_length_bucket_long')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'renders English fallback strings when AppLocalizations is absent',
      (tester) async {
        final breakdown = ConsumptionTripLengthBreakdown(
          short: _bucket(
            tripCount: 5,
            totalDistanceKm: 20.0,
            totalLitres: 2.5,
          ),
          medium: ConsumptionTripLengthBucketStats.empty,
          long: ConsumptionTripLengthBucketStats.empty,
          overallAvgLPer100Km: 12.5,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TripLengthBreakdownCard(breakdown: breakdown),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // English fallback path on the title.
        expect(find.text('Consumption by trip length'), findsOneWidget);
        // Bucket labels fall back to English.
        expect(find.text('Short'), findsOneWidget);
        // Avg L/100 km falls back to '<value> L/100 km'.
        expect(find.text('12.5 L/100 km'), findsOneWidget);
      },
    );
  });
}
