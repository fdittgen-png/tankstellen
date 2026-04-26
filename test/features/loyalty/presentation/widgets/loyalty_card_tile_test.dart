import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/loyalty/domain/entities/loyalty_card.dart';
import 'package:tankstellen/features/loyalty/presentation/widgets/loyalty_card_tile.dart';

import '../../../../helpers/pump_app.dart';

LoyaltyCard _makeCard({
  String id = 'card-1',
  String label = 'Personal',
  double discount = 0.05,
  LoyaltyBrand brand = LoyaltyBrand.totalEnergies,
  bool enabled = true,
}) {
  return LoyaltyCard(
    id: id,
    brand: brand,
    discountPerLiter: discount,
    label: label,
    addedAt: DateTime(2026, 4, 1),
    enabled: enabled,
  );
}

void main() {
  group('LoyaltyCardTile', () {
    testWidgets(
        'renders the user-supplied label, brand and discount line',
        (tester) async {
      await pumpApp(
        tester,
        LoyaltyCardTile(
          card: _makeCard(),
          onToggle: (_) {},
          onDeleteRequested: () {},
        ),
      );

      // Title row uses the user-supplied label, not the brand name.
      expect(find.text('Personal'), findsOneWidget);
      // Subtitle exposes the canonical brand and the formatted discount.
      expect(find.textContaining('TotalEnergies'), findsOneWidget);
      expect(find.textContaining('−0.05 /L'), findsOneWidget);
    });

    testWidgets('falls back to canonical brand when label is empty',
        (tester) async {
      await pumpApp(
        tester,
        LoyaltyCardTile(
          card: _makeCard(label: ''),
          onToggle: (_) {},
          onDeleteRequested: () {},
        ),
      );

      // Title row falls back to "TotalEnergies" (brand canonicalBrand).
      expect(find.text('TotalEnergies'), findsAtLeastNWidgets(1));
    });

    testWidgets('Switch reflects the card.enabled flag', (tester) async {
      await pumpApp(
        tester,
        LoyaltyCardTile(
          card: _makeCard(enabled: false),
          onToggle: (_) {},
          onDeleteRequested: () {},
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('flipping the Switch invokes onToggle with the new value',
        (tester) async {
      bool? lastValue;
      await pumpApp(
        tester,
        LoyaltyCardTile(
          card: _makeCard(enabled: false),
          onToggle: (v) => lastValue = v,
          onDeleteRequested: () {},
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(lastValue, isTrue);
    });

    testWidgets('tapping the trash icon invokes onDeleteRequested',
        (tester) async {
      var deleteCalls = 0;
      await pumpApp(
        tester,
        LoyaltyCardTile(
          card: _makeCard(),
          onToggle: (_) {},
          onDeleteRequested: () => deleteCalls++,
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(deleteCalls, 1);
    });

    testWidgets('trash IconButton exposes a tooltip', (tester) async {
      await pumpApp(
        tester,
        LoyaltyCardTile(
          card: _makeCard(),
          onToggle: (_) {},
          onDeleteRequested: () {},
        ),
      );

      // English fallback string from the localization helper.
      expect(find.byTooltip('Delete'), findsOneWidget);
    });

    testWidgets('end-to-start swipe routes through onDeleteRequested',
        (tester) async {
      var deleteCalls = 0;
      await pumpApp(
        tester,
        LoyaltyCardTile(
          card: _makeCard(),
          onToggle: (_) {},
          onDeleteRequested: () => deleteCalls++,
        ),
      );

      // Swipe the Dismissible from end to start past the dismiss
      // threshold; confirmDismiss returns false but still calls back.
      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(deleteCalls, greaterThanOrEqualTo(1));
    });

    testWidgets('hit targets meet the Android tap-target guideline',
        (tester) async {
      await pumpApp(
        tester,
        LoyaltyCardTile(
          card: _makeCard(),
          onToggle: (_) {},
          onDeleteRequested: () {},
        ),
      );

      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });
  });
}
