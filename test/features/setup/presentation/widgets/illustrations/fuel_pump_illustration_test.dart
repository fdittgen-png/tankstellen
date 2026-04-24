import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/setup/presentation/widgets/illustrations/fuel_pump_illustration.dart';

import '../../../../../helpers/pump_app.dart';

void main() {
  group('FuelPumpIllustration rendering', () {
    testWidgets('renders the fuel-pump icon as the hero glyph',
        (tester) async {
      await pumpApp(tester, const FuelPumpIllustration());

      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
    });

    testWidgets('renders inside a SizedBox sized to the given dimension',
        (tester) async {
      await pumpApp(tester, const FuelPumpIllustration(size: 180));

      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(FuelPumpIllustration),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.width, 180);
      expect(sizedBox.height, 180);
    });

    testWidgets('defaults to 200dp square when no size is provided',
        (tester) async {
      await pumpApp(tester, const FuelPumpIllustration());

      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(FuelPumpIllustration),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.width, 200);
      expect(sizedBox.height, 200);
    });

    testWidgets('sparkline is painted by a CustomPaint behind the pump',
        (tester) async {
      await pumpApp(tester, const FuelPumpIllustration());

      // The ticker's sparkline paints onto its own CustomPaint — confirm
      // it actually exists so the illustration doesn't silently drop its
      // "prices going down" hint.
      expect(
        find.descendant(
          of: find.byType(FuelPumpIllustration),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );
    });

    testWidgets('exposes a descriptive image Semantics label',
        (tester) async {
      await pumpApp(tester, const FuelPumpIllustration());

      // Screen readers should announce the onboarding illustration as an
      // image rather than reading out each icon individually.
      expect(
        find.bySemanticsLabel('Fuel pump with price ticker'),
        findsOneWidget,
      );
    });

    testWidgets('renders without theme overflow when shrunk',
        (tester) async {
      // The illustration is sometimes rendered inside a small ConstrainedBox
      // on short screens — verify a narrow size doesn't trigger layout
      // assertions.
      await pumpApp(tester, const FuelPumpIllustration(size: 80));

      expect(find.byType(FuelPumpIllustration), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
