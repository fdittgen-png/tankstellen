import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/calculator/presentation/widgets/calculator_result_card.dart';
import 'package:tankstellen/features/calculator/providers/calculator_provider.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('CalculatorResultCard', () {
    testWidgets('renders trip cost header, fuel needed and total cost',
        (tester) async {
      const state = CalculatorState(
        distanceKm: 100,
        consumptionPer100Km: 7,
        pricePerLiter: 2,
      );

      await pumpApp(tester, const CalculatorResultCard(state: state));

      expect(find.text('Trip Cost'), findsOneWidget);
      expect(find.text('Fuel needed'), findsOneWidget);
      expect(find.text('Total cost'), findsOneWidget);
      // 100 km * 7 L/100km = 7 L
      expect(find.text('7.0 L'), findsOneWidget);
      // 7 L * 2 €/L = 14.00 €
      expect(find.text('14.00 \u20ac'), findsOneWidget);
    });
  });
}
