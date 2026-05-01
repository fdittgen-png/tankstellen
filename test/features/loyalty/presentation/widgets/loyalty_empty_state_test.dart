import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/loyalty/presentation/widgets/loyalty_empty_state.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('LoyaltyEmptyState', () {
    testWidgets('renders the empty-title and explanatory body',
        (tester) async {
      await pumpApp(
        tester,
        const LoyaltyEmptyState(),
      );

      expect(find.text('No fuel club cards yet'), findsOneWidget);
      expect(
        find.textContaining('Add a card to apply your per-litre discount'),
        findsOneWidget,
      );
      // The marquee membership icon at 64px.
      expect(find.byIcon(Icons.card_membership), findsOneWidget);
      // No inline CTA — the canonical action is the parent screen's FAB
      // (#1329).
      expect(find.byType(FilledButton), findsNothing);
    });
  });
}
