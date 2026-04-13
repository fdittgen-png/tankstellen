import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/calculator/presentation/widgets/calculator_input_field.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('CalculatorInputField', () {
    testWidgets('renders label, hint and icon', (tester) async {
      await pumpApp(
        tester,
        CalculatorInputField(
          controller: TextEditingController(),
          labelText: 'Distance (km)',
          hintText: 'e.g. 150',
          icon: Icons.straighten,
          onParsed: (_) {},
        ),
      );

      expect(find.text('Distance (km)'), findsOneWidget);
      expect(find.text('e.g. 150'), findsOneWidget);
      expect(find.byIcon(Icons.straighten), findsOneWidget);
    });

    testWidgets('forwards parsed value on change', (tester) async {
      double? parsed;
      await pumpApp(
        tester,
        CalculatorInputField(
          controller: TextEditingController(),
          labelText: 'Distance (km)',
          hintText: 'e.g. 150',
          icon: Icons.straighten,
          onParsed: (v) => parsed = v,
        ),
      );

      await tester.enterText(find.byType(TextField), '42.5');
      expect(parsed, 42.5);
    });

    testWidgets('forwards 0 for unparseable input', (tester) async {
      double? parsed;
      await pumpApp(
        tester,
        CalculatorInputField(
          controller: TextEditingController(),
          labelText: 'Distance (km)',
          hintText: 'e.g. 150',
          icon: Icons.straighten,
          onParsed: (v) => parsed = v,
        ),
      );

      await tester.enterText(find.byType(TextField), 'abc');
      expect(parsed, 0);
    });
  });
}
