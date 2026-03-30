import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/price_history/data/models/price_record.dart';
import 'package:tankstellen/features/price_history/presentation/widgets/price_chart.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('PriceChart', () {
    testWidgets('renders "No price history yet" when records is empty',
        (tester) async {
      await pumpApp(
        tester,
        const PriceChart(records: [], fuelType: FuelType.diesel),
      );

      expect(find.text('No price history yet'), findsOneWidget);
      // Should not find a PriceChart-owned CustomPaint (only Scaffold's)
      expect(find.byType(PriceChart), findsOneWidget);
    });

    testWidgets('renders CustomPaint when records are provided',
        (tester) async {
      final records = [
        PriceRecord(
          stationId: 'test-1',
          recordedAt: DateTime(2026, 3, 25),
          diesel: 1.459,
        ),
        PriceRecord(
          stationId: 'test-1',
          recordedAt: DateTime(2026, 3, 26),
          diesel: 1.479,
        ),
        PriceRecord(
          stationId: 'test-1',
          recordedAt: DateTime(2026, 3, 27),
          diesel: 1.469,
        ),
      ];

      await pumpApp(
        tester,
        PriceChart(records: records, fuelType: FuelType.diesel),
      );

      expect(find.text('No price history yet'), findsNothing);
      // The PriceChart widget should be present and contain a CustomPaint
      expect(find.byType(PriceChart), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PriceChart),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders with a single record without error', (tester) async {
      final records = [
        PriceRecord(
          stationId: 'test-1',
          recordedAt: DateTime(2026, 3, 27),
          diesel: 1.459,
        ),
      ];

      await pumpApp(
        tester,
        PriceChart(records: records, fuelType: FuelType.diesel),
      );

      // Should render the CustomPaint (single dot case), no error text
      expect(find.text('No price history yet'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(PriceChart),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });
  });
}
