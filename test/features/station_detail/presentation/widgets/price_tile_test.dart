// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/animated_price_text.dart';
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

    testWidgets('#2973 — wraps the price in an AnimatedPriceText',
        (tester) async {
      await pumpApp(
        tester,
        const PriceTile(
            label: 'Diesel', price: 1.459, fuelType: FuelType.diesel),
      );
      expect(find.byType(AnimatedPriceText), findsOneWidget);
    });

    testWidgets('#2973 — a price change flashes (controller runs)',
        (tester) async {
      Widget host(double price) => MaterialApp(
            home: Scaffold(
              body: PriceTile(
                label: 'Diesel',
                price: price,
                fuelType: FuelType.diesel,
              ),
            ),
          );

      await tester.pumpWidget(host(1.699));
      await tester.pumpAndSettle();

      // A real drop must kick the flash controller.
      await tester.pumpWidget(host(1.499));
      await tester.pump();
      expect(tester.hasRunningAnimations, isTrue,
          reason: 'a price drop on the detail tile must flash');
      await tester.pumpAndSettle();
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
