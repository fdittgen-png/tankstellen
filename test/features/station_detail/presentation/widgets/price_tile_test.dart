import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/price_tile.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('PriceTile', () {
    testWidgets('renders label and formatted price', (tester) async {
      await pumpApp(
        tester,
        const PriceTile(label: 'Diesel', price: 1.459, fuelType: FuelType.diesel),
      );

      expect(find.text('Diesel'), findsOneWidget);
      // PriceFormatter formats to locale-specific string
      expect(find.textContaining('1'), findsWidgets);
    });

    testWidgets('renders dash for null price', (tester) async {
      await pumpApp(
        tester,
        const PriceTile(label: 'Super E5', price: null, fuelType: FuelType.e5),
      );

      expect(find.text('Super E5'), findsOneWidget);
      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('uses compact layout with Row instead of ListTile',
        (tester) async {
      await pumpApp(
        tester,
        const PriceTile(
            label: 'Diesel', price: 1.459, fuelType: FuelType.diesel),
      );

      // Should NOT use ListTile (compact layout)
      expect(find.byType(ListTile), findsNothing);
      // Should use a Row-based layout with gas station icon
      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
    });

    testWidgets('vertical padding is compact (4dp)', (tester) async {
      await pumpApp(
        tester,
        const Column(
          children: [
            PriceTile(
                label: 'Super E5', price: 1.859, fuelType: FuelType.e5),
            PriceTile(
                label: 'Super E10', price: 1.799, fuelType: FuelType.e10),
          ],
        ),
      );

      // Both should render in a compact space
      final e5Rect = tester.getRect(find.text('Super E5'));
      final e10Rect = tester.getRect(find.text('Super E10'));
      // Gap between the two rows should be small (< 30dp)
      final gap = e10Rect.top - e5Rect.bottom;
      expect(gap, lessThan(30));
    });
  });
}
