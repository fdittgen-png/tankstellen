import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/price_history/data/models/price_prediction.dart';
import 'package:tankstellen/features/price_history/presentation/widgets/hourly_price_chart.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('HourlyPriceChart', () {
    testWidgets(
      'renders "No hourly data" fallback when hourlyAverages is empty',
      (tester) async {
        await pumpApp(
          tester,
          const HourlyPriceChart(hourlyAverages: []),
        );

        expect(find.text('No hourly data'), findsOneWidget);
        expect(find.byType(HourlyPriceChart), findsOneWidget);
        // Empty branch does NOT render a CustomPaint owned by HourlyPriceChart.
        expect(
          find.descendant(
            of: find.byType(HourlyPriceChart),
            matching: find.byType(CustomPaint),
          ),
          findsNothing,
        );
      },
    );

    testWidgets('empty state uses a fixed SizedBox height of 140',
        (tester) async {
      await pumpApp(
        tester,
        const HourlyPriceChart(hourlyAverages: []),
      );

      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(HourlyPriceChart),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.height, 140);
    });

    testWidgets('renders CustomPaint when hourlyAverages has entries',
        (tester) async {
      final averages = [
        const HourlyAverage(hour: 0, avgPrice: 1.459, sampleCount: 3),
        const HourlyAverage(hour: 6, avgPrice: 1.479, sampleCount: 4),
        const HourlyAverage(hour: 12, avgPrice: 1.499, sampleCount: 5),
        const HourlyAverage(hour: 18, avgPrice: 1.469, sampleCount: 2),
      ];

      await pumpApp(
        tester,
        HourlyPriceChart(hourlyAverages: averages),
      );

      expect(find.text('No hourly data'), findsNothing);
      expect(find.byType(HourlyPriceChart), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HourlyPriceChart),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders with a single entry (flat-price branch)',
        (tester) async {
      final averages = [
        const HourlyAverage(hour: 9, avgPrice: 1.459, sampleCount: 1),
      ];

      await pumpApp(
        tester,
        HourlyPriceChart(hourlyAverages: averages),
      );

      expect(find.text('No hourly data'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(HourlyPriceChart),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders a full 24-hour dataset without error',
        (tester) async {
      final averages = List<HourlyAverage>.generate(
        24,
        (i) => HourlyAverage(
          hour: i,
          // Price varies so min/max colouring branches get exercised.
          avgPrice: 1.400 + (i % 7) * 0.01,
          sampleCount: 2,
        ),
      );

      await pumpApp(
        tester,
        HourlyPriceChart(hourlyAverages: averages),
      );

      expect(find.text('No hourly data'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(HourlyPriceChart),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
      // No exceptions during paint.
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'non-empty state uses a fixed SizedBox height of 140',
      (tester) async {
        final averages = [
          const HourlyAverage(hour: 3, avgPrice: 1.45, sampleCount: 1),
          const HourlyAverage(hour: 15, avgPrice: 1.55, sampleCount: 1),
        ];

        await pumpApp(
          tester,
          HourlyPriceChart(hourlyAverages: averages),
        );

        final sizedBox = tester.widget<SizedBox>(
          find
              .descendant(
                of: find.byType(HourlyPriceChart),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        expect(sizedBox.height, 140);
      },
    );
  });
}
