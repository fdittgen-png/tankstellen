import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/widgets/sort_selector.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('SortSelector', () {
    testWidgets('renders all three sort options', (tester) async {
      await pumpApp(
        tester,
        SortSelector(
          selected: SortMode.distance,
          onChanged: (_) {},
        ),
      );

      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Price'), findsOneWidget);
      expect(find.text('A-Z'), findsOneWidget);
    });

    testWidgets('default selection is highlighted as selected', (tester) async {
      await pumpApp(
        tester,
        SortSelector(
          selected: SortMode.distance,
          onChanged: (_) {},
        ),
      );

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
      expect(chips, hasLength(3));

      // Distance chip should be selected
      final distanceChip = chips.firstWhere(
        (c) => (c.label as Text).data == 'Distance',
      );
      expect(distanceChip.selected, isTrue);

      // Others should not be selected
      final priceChip = chips.firstWhere(
        (c) => (c.label as Text).data == 'Price',
      );
      expect(priceChip.selected, isFalse);

      final nameChip = chips.firstWhere(
        (c) => (c.label as Text).data == 'A-Z',
      );
      expect(nameChip.selected, isFalse);
    });

    testWidgets('price selection is highlighted when selected', (tester) async {
      await pumpApp(
        tester,
        SortSelector(
          selected: SortMode.price,
          onChanged: (_) {},
        ),
      );

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
      final priceChip = chips.firstWhere(
        (c) => (c.label as Text).data == 'Price',
      );
      expect(priceChip.selected, isTrue);
    });

    testWidgets('tapping a sort option calls onChanged', (tester) async {
      SortMode? receivedMode;

      await pumpApp(
        tester,
        SortSelector(
          selected: SortMode.distance,
          onChanged: (mode) => receivedMode = mode,
        ),
      );

      await tester.tap(find.text('Price'));
      await tester.pumpAndSettle();

      expect(receivedMode, SortMode.price);
    });

    testWidgets('tapping A-Z calls onChanged with name', (tester) async {
      SortMode? receivedMode;

      await pumpApp(
        tester,
        SortSelector(
          selected: SortMode.distance,
          onChanged: (mode) => receivedMode = mode,
        ),
      );

      await tester.tap(find.text('A-Z'));
      await tester.pumpAndSettle();

      expect(receivedMode, SortMode.name);
    });

    testWidgets('each chip has an icon', (tester) async {
      await pumpApp(
        tester,
        SortSelector(
          selected: SortMode.distance,
          onChanged: (_) {},
        ),
      );

      // Each sort chip has an icon avatar
      expect(find.byIcon(Icons.near_me), findsOneWidget);
      expect(find.byIcon(Icons.euro), findsOneWidget);
      expect(find.byIcon(Icons.sort_by_alpha), findsOneWidget);
    });

    testWidgets('has correct semantics labels', (tester) async {
      await pumpApp(
        tester,
        SortSelector(
          selected: SortMode.price,
          onChanged: (_) {},
        ),
      );

      expect(
        find.bySemanticsLabel(RegExp(r'Sort by Price, selected')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Sort by Distance$')),
        findsOneWidget,
      );
    });
  });
}
