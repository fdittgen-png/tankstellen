import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/calculator/presentation/widgets/calculator_empty_hint.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('CalculatorEmptyHint', () {
    testWidgets('renders the calculator icon and hint text',
        (tester) async {
      await pumpApp(tester, const CalculatorEmptyHint());

      expect(find.byIcon(Icons.calculate_outlined), findsOneWidget);
      expect(
        find.textContaining('Enter distance'),
        findsOneWidget,
      );
    });

    testWidgets('hint text is centered', (tester) async {
      await pumpApp(tester, const CalculatorEmptyHint());
      final text = tester.widget<Text>(
        find.textContaining('Enter distance'),
      );
      expect(text.textAlign, TextAlign.center);
    });

    testWidgets('uses a large 64-px icon so the empty state is obvious',
        (tester) async {
      await pumpApp(tester, const CalculatorEmptyHint());
      final icon = tester.widget<Icon>(
        find.byIcon(Icons.calculate_outlined),
      );
      expect(icon.size, 64);
    });
  });
}
