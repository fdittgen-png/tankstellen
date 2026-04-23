import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_price_per_liter_readout.dart';

import '../../../../helpers/pump_app.dart';

/// Widget tests for the live price-per-liter derivation shown under
/// the cost field on the restyled Add-Fill-up form (#751 phase 2).
void main() {
  group('FillUpPricePerLiterReadout (#751 phase 2)', () {
    testWidgets('stays hidden when liters is empty', (tester) async {
      final liters = TextEditingController();
      final cost = TextEditingController(text: '60');
      await pumpApp(
        tester,
        FillUpPricePerLiterReadout(
          litersController: liters,
          costController: cost,
        ),
      );
      expect(find.textContaining('Price per liter'), findsNothing);
    });

    testWidgets('stays hidden when cost is empty', (tester) async {
      final liters = TextEditingController(text: '30');
      final cost = TextEditingController();
      await pumpApp(
        tester,
        FillUpPricePerLiterReadout(
          litersController: liters,
          costController: cost,
        ),
      );
      expect(find.textContaining('Price per liter'), findsNothing);
    });

    testWidgets('renders value when liters+cost both set (30 L / 60 €)',
        (tester) async {
      final liters = TextEditingController(text: '30');
      final cost = TextEditingController(text: '60');
      await pumpApp(
        tester,
        FillUpPricePerLiterReadout(
          litersController: liters,
          costController: cost,
        ),
      );
      // 60 / 30 = 2.000
      expect(find.textContaining('Price per liter'), findsOneWidget);
      expect(find.textContaining('2.000'), findsOneWidget);
    });

    testWidgets('comma-decimals are treated as dots (50,25 € / 25 L)',
        (tester) async {
      final liters = TextEditingController(text: '25');
      final cost = TextEditingController(text: '50,25');
      await pumpApp(
        tester,
        FillUpPricePerLiterReadout(
          litersController: liters,
          costController: cost,
        ),
      );
      // 50.25 / 25 = 2.010
      expect(find.textContaining('2.010'), findsOneWidget);
    });

    testWidgets('reacts to live edits of the controllers', (tester) async {
      final liters = TextEditingController();
      final cost = TextEditingController();
      await pumpApp(
        tester,
        FillUpPricePerLiterReadout(
          litersController: liters,
          costController: cost,
        ),
      );
      expect(find.textContaining('Price per liter'), findsNothing);

      liters.text = '40';
      cost.text = '74.36';
      await tester.pump();

      // 74.36 / 40 = 1.859
      expect(find.textContaining('Price per liter'), findsOneWidget);
      expect(find.textContaining('1.859'), findsOneWidget);
    });

    testWidgets('hides again when a value goes to zero', (tester) async {
      final liters = TextEditingController(text: '10');
      final cost = TextEditingController(text: '20');
      await pumpApp(
        tester,
        FillUpPricePerLiterReadout(
          litersController: liters,
          costController: cost,
        ),
      );
      expect(find.textContaining('2.000'), findsOneWidget);

      cost.text = '0';
      await tester.pump();
      expect(find.textContaining('Price per liter'), findsNothing);
    });
  });
}
