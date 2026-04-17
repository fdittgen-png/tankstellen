import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/payment_app_launcher.dart';
import 'package:tankstellen/features/search/presentation/widgets/pay_with_app_button.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('PayWithAppButton', () {
    testWidgets('renders nothing for unknown brand', (tester) async {
      await pumpApp(
        tester,
        const PayWithAppButton(brand: 'Local Independent'),
      );

      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('renders nothing for empty brand', (tester) async {
      await pumpApp(tester, const PayWithAppButton(brand: ''));
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('shows Pay with Shell App button for Shell brand',
        (tester) async {
      await pumpApp(tester, const PayWithAppButton(brand: 'Shell'));
      expect(find.textContaining('Shell App'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('shows Pay with BPme button for BP brand', (tester) async {
      await pumpApp(tester, const PayWithAppButton(brand: 'BP'));
      expect(find.textContaining('BPme'), findsOneWidget);
    });

    testWidgets('tap invokes launcher with the mapped app', (tester) async {
      PaymentApp? launched;
      await pumpApp(
        tester,
        PayWithAppButton(
          brand: 'Aral',
          onLaunch: (app) async {
            launched = app;
            return true;
          },
        ),
      );

      await tester.tap(find.byIcon(Icons.open_in_new));
      await tester.pump();

      expect(launched, isNotNull);
      expect(launched!.displayName, 'Aral Pay');
    });

    testWidgets('swallows launcher exceptions without crashing',
        (tester) async {
      await pumpApp(
        tester,
        PayWithAppButton(
          brand: 'Shell',
          onLaunch: (app) async => throw Exception('no browser'),
        ),
      );

      await tester.tap(find.byIcon(Icons.open_in_new));
      await tester.pump();

      // Test passes if no exception bubbles up.
      expect(tester.takeException(), isNull);
    });
  });
}
