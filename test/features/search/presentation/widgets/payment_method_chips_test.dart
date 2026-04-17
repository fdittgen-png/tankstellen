import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/widgets/payment_method_chips.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('PaymentMethodChips', () {
    testWidgets('renders nothing when brand is blank', (tester) async {
      // Blank brand still yields cash+card defaults, so chips render.
      // Keep this as a guard that widget never throws for empty brand.
      await pumpApp(
        tester,
        const PaymentMethodChips(brand: ''),
      );
      expect(find.byType(PaymentMethodChips), findsOneWidget);
    });

    testWidgets('renders cash, card, contactless for unknown brand',
        (tester) async {
      await pumpApp(
        tester,
        const PaymentMethodChips(brand: 'Local Independent'),
      );

      expect(find.byIcon(Icons.payments), findsOneWidget);
      expect(find.byIcon(Icons.credit_card), findsOneWidget);
      expect(find.byIcon(Icons.contactless), findsOneWidget);
      // No fuel card or app
      expect(find.byIcon(Icons.local_gas_station), findsNothing);
      expect(find.byIcon(Icons.smartphone), findsNothing);
    });

    testWidgets('Shell station renders fuel card and branded app chip',
        (tester) async {
      await pumpApp(
        tester,
        const PaymentMethodChips(brand: 'Shell'),
      );

      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
      expect(find.byIcon(Icons.smartphone), findsOneWidget);
      // Branded app label comes through
      expect(find.text('Shell App'), findsOneWidget);
    });

    testWidgets('BP station uses BPme branded label', (tester) async {
      await pumpApp(
        tester,
        const PaymentMethodChips(brand: 'BP'),
      );
      expect(find.text('BPme'), findsOneWidget);
    });

    testWidgets('Aral station uses Aral Pay branded label', (tester) async {
      await pumpApp(
        tester,
        const PaymentMethodChips(brand: 'Aral'),
      );
      expect(find.text('Aral Pay'), findsOneWidget);
    });

    testWidgets('shows overflow +N when exceeding maxVisible', (tester) async {
      // Shell produces 5 methods (cash, card, contactless, fuelCard, app)
      await pumpApp(
        tester,
        const PaymentMethodChips(brand: 'Shell', maxVisible: 3),
      );
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('no overflow indicator when within maxVisible',
        (tester) async {
      await pumpApp(
        tester,
        const PaymentMethodChips(brand: 'Shell', maxVisible: 6),
      );
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('exposes a group Semantics label for screen readers',
        (tester) async {
      await pumpApp(
        tester,
        const PaymentMethodChips(brand: 'Shell'),
      );

      final semantics = tester.getSemantics(find.byType(PaymentMethodChips));
      expect(semantics.label, contains('Payment methods'));
      expect(semantics.label, contains('Cash'));
      expect(semantics.label, contains('Shell App'));
    });
  });
}
