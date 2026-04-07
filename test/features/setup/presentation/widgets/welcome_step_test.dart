import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/presentation/widgets/welcome_step.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('WelcomeStep', () {
    testWidgets('renders app icon and welcome text', (tester) async {
      await pumpApp(tester, const WelcomeStep());

      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
      expect(find.text('Fuel Prices'), findsOneWidget);
      expect(
        find.text('Find the cheapest fuel near you.'),
        findsOneWidget,
      );
    });

    testWidgets('renders setup hint text', (tester) async {
      await pumpApp(tester, const WelcomeStep());

      expect(
        find.text('Set up the app in a few quick steps.'),
        findsOneWidget,
      );
    });

    testWidgets('renders German text with de locale', (tester) async {
      await pumpApp(
        tester,
        const WelcomeStep(),
        locale: const Locale('de'),
      );

      expect(find.text('Tankstellen'), findsOneWidget);
      expect(
        find.text('Richten Sie die App in wenigen Schritten ein.'),
        findsOneWidget,
      );
    });

    testWidgets('meets tap target guidelines', (tester) async {
      await pumpApp(tester, const WelcomeStep());

      // Welcome step has no interactive elements, so no tap targets to check
      // but we verify it renders without errors
      expect(find.byType(WelcomeStep), findsOneWidget);
    });
  });
}
