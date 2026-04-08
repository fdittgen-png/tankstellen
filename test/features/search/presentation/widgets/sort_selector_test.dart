import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/widgets/sort_selector.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('SortSelector', () {
    testWidgets('renders all six sort options', (tester) async {
      await pumpApp(
        tester,
        SortSelector(
          selected: SortMode.distance,
          onChanged: (_) {},
        ),
      );

      // First 3 visible without scroll
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Price'), findsOneWidget);
      expect(find.text('A-Z'), findsOneWidget);

      // Scroll to reveal new chips
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(-300, 0),
      );
      await tester.pump();

      expect(find.text('24h'), findsOneWidget);
      expect(find.text('Rating'), findsOneWidget);
      expect(find.text('Price/km'), findsOneWidget);
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
      expect(chips, hasLength(6));

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

    testWidgets('tapping 24h calls onChanged with open24h', (tester) async {
      SortMode? receivedMode;

      await pumpApp(
        tester,
        SortSelector(
          selected: SortMode.distance,
          onChanged: (mode) => receivedMode = mode,
        ),
      );

      // Scroll to reveal new chips
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(-300, 0),
      );
      await tester.pump();

      await tester.tap(find.text('24h'));
      await tester.pumpAndSettle();

      expect(receivedMode, SortMode.open24h);
    });

    testWidgets('tapping Rating calls onChanged with rating', (tester) async {
      SortMode? receivedMode;

      await pumpApp(
        tester,
        SortSelector(
          selected: SortMode.distance,
          onChanged: (mode) => receivedMode = mode,
        ),
      );

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(-300, 0),
      );
      await tester.pump();

      await tester.tap(find.text('Rating'));
      await tester.pumpAndSettle();

      expect(receivedMode, SortMode.rating);
    });

    testWidgets('tapping Price/km calls onChanged with priceDistance', (tester) async {
      SortMode? receivedMode;

      await pumpApp(
        tester,
        SortSelector(
          selected: SortMode.distance,
          onChanged: (mode) => receivedMode = mode,
        ),
      );

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(-300, 0),
      );
      await tester.pump();

      await tester.tap(find.text('Price/km'));
      await tester.pumpAndSettle();

      expect(receivedMode, SortMode.priceDistance);
    });

    testWidgets('each chip has an icon', (tester) async {
      await pumpApp(
        tester,
        SortSelector(
          selected: SortMode.distance,
          onChanged: (_) {},
        ),
      );

      // First 3 icons visible
      expect(find.byIcon(Icons.near_me), findsOneWidget);
      expect(find.byIcon(Icons.euro), findsOneWidget);
      expect(find.byIcon(Icons.sort_by_alpha), findsOneWidget);

      // Scroll to see new icons
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(-300, 0),
      );
      await tester.pump();

      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.balance), findsOneWidget);
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

    testWidgets('open24h selected chip is highlighted', (tester) async {
      await pumpApp(
        tester,
        SortSelector(
          selected: SortMode.open24h,
          onChanged: (_) {},
        ),
      );

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
      final open24hChip = chips.firstWhere(
        (c) => (c.label as Text).data == '24h',
      );
      expect(open24hChip.selected, isTrue);

      // Distance should not be selected
      final distChip = chips.firstWhere(
        (c) => (c.label as Text).data == 'Distance',
      );
      expect(distChip.selected, isFalse);
    });
  });

  group('SortMode enum', () {
    test('has six values', () {
      expect(SortMode.values.length, 6);
    });

    test('contains all expected modes', () {
      expect(SortMode.values, containsAll([
        SortMode.distance,
        SortMode.price,
        SortMode.name,
        SortMode.open24h,
        SortMode.rating,
        SortMode.priceDistance,
      ]));
    });
  });
}
