import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/price_history/data/models/price_prediction.dart';
import 'package:tankstellen/features/price_history/presentation/widgets/best_time_banner.dart';
import 'package:tankstellen/features/price_history/providers/price_prediction_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../../helpers/pump_app.dart';

PricePrediction _pred({
  String recommendation = 'Prices typically drop Tuesday evenings',
  double? potentialSaving,
}) =>
    PricePrediction(
      recommendation: recommendation,
      potentialSaving: potentialSaving,
      bestHour: 19,
      bestDayOfWeek: 2,
      hourlyAverages: const [],
      dailyAverages: const [],
    );

void main() {
  group('BestTimeBanner', () {
    testWidgets('renders nothing when prediction is null', (tester) async {
      await pumpApp(
        tester,
        const BestTimeBanner(
          stationId: 'st-1',
          fuelType: FuelType.diesel,
        ),
        overrides: [
          pricePredictionProvider('st-1', FuelType.diesel)
              .overrideWithValue(null),
        ],
      );

      expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('renders lightbulb + recommendation when prediction exists',
        (tester) async {
      await pumpApp(
        tester,
        const BestTimeBanner(
          stationId: 'st-1',
          fuelType: FuelType.diesel,
        ),
        overrides: [
          pricePredictionProvider('st-1', FuelType.diesel)
              .overrideWithValue(_pred()),
        ],
      );

      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      expect(find.text('Prices typically drop Tuesday evenings'),
          findsOneWidget);
    });

    testWidgets('shows saving line when potentialSaving > 0',
        (tester) async {
      await pumpApp(
        tester,
        const BestTimeBanner(
          stationId: 'st-1',
          fuelType: FuelType.e10,
        ),
        overrides: [
          pricePredictionProvider('st-1', FuelType.e10)
              .overrideWithValue(_pred(potentialSaving: 0.025)),
        ],
      );

      // 0.025 EUR → 2.5 ct/L
      expect(find.textContaining('Save'), findsOneWidget);
      expect(find.textContaining('2.5 ct/L'), findsOneWidget);
    });

    testWidgets('hides the saving line when potentialSaving is null',
        (tester) async {
      await pumpApp(
        tester,
        const BestTimeBanner(
          stationId: 'st-1',
          fuelType: FuelType.diesel,
        ),
        overrides: [
          pricePredictionProvider('st-1', FuelType.diesel)
              .overrideWithValue(_pred()),
        ],
      );
      expect(find.textContaining('Save'), findsNothing);
    });

    testWidgets('hides the saving line when potentialSaving is 0 or less',
        (tester) async {
      // The guard is `saving == null || saving <= 0`.
      await pumpApp(
        tester,
        const BestTimeBanner(
          stationId: 'st-1',
          fuelType: FuelType.diesel,
        ),
        overrides: [
          pricePredictionProvider('st-1', FuelType.diesel)
              .overrideWithValue(_pred(potentialSaving: 0)),
        ],
      );
      expect(find.textContaining('Save'), findsNothing);
    });

    testWidgets('recommendation text is bold/medium-weight for emphasis',
        (tester) async {
      await pumpApp(
        tester,
        const BestTimeBanner(
          stationId: 'st-1',
          fuelType: FuelType.diesel,
        ),
        overrides: [
          pricePredictionProvider('st-1', FuelType.diesel)
              .overrideWithValue(_pred()),
        ],
      );
      final txt = tester.widget<Text>(
        find.text('Prices typically drop Tuesday evenings'),
      );
      expect(txt.style?.fontWeight, FontWeight.w600);
    });
  });
}
