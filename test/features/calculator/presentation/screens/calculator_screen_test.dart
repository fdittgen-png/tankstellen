import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/calculator/presentation/screens/calculator_screen.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('CalculatorScreen', () {
    testWidgets('renders Scaffold with app bar', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const CalculatorScreen(),
        overrides: test.overrides,
      );

      expect(find.byType(Scaffold), findsAtLeast(1));
      expect(find.text('Fuel Cost Calculator'), findsOneWidget);
    });

    testWidgets('renders three input fields', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const CalculatorScreen(),
        overrides: test.overrides,
      );

      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.text('Distance (km)'), findsOneWidget);
      expect(find.text('Consumption (L/100km)'), findsOneWidget);
    });

    testWidgets('shows empty state hint when no values entered', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const CalculatorScreen(),
        overrides: test.overrides,
      );

      expect(
        find.text('Enter distance, consumption, and price to calculate trip cost'),
        findsOneWidget,
      );
    });
  });
}
