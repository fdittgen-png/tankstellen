import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/loyalty/presentation/widgets/loyalty_empty_state.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('LoyaltyEmptyState', () {
    testWidgets('renders the empty-title, body and "Add card" CTA',
        (tester) async {
      await pumpApp(
        tester,
        LoyaltyEmptyState(onAdd: () {}),
      );

      expect(find.text('No fuel club cards yet'), findsOneWidget);
      expect(
        find.textContaining('Add a card to apply your per-litre discount'),
        findsOneWidget,
      );
      // Primary CTA — the FilledButton.icon variant exposes both an
      // icon and the "Add card" label.
      expect(find.widgetWithText(FilledButton, 'Add card'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      // The marquee membership icon at 64px.
      expect(find.byIcon(Icons.card_membership), findsOneWidget);
    });

    testWidgets('invokes onAdd when the CTA is tapped', (tester) async {
      var taps = 0;
      await pumpApp(
        tester,
        LoyaltyEmptyState(onAdd: () => taps++),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Add card'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('CTA hit target meets the Android tap-target guideline',
        (tester) async {
      await pumpApp(
        tester,
        LoyaltyEmptyState(onAdd: () {}),
      );

      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });
  });
}
