// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/widgets/sort_selector.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('SortSelector', () {
    testWidgets('renders all six sort options without scrolling (#3926)', (
      tester,
    ) async {
      await pumpApp(
        tester,
        SortSelector(selected: SortMode.distance, onChanged: (_) {}),
      );

      // #3926 — the chips used to live in a horizontal SingleChildScrollView
      // that cut "24h" in half at 320 dp and hid the three chips past it.
      // A Wrap moves a whole chip to the next line instead, so every option
      // is on screen with no drag.
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byType(Wrap), findsOneWidget);

      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Price'), findsOneWidget);
      expect(find.text('A-Z'), findsOneWidget);
      expect(find.text('24h'), findsOneWidget);
      expect(find.text('Rating'), findsOneWidget);
      expect(find.text('Price/km'), findsOneWidget);
    });

    testWidgets('no chip is clipped at a 320 dp width (#3926)', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpApp(
        tester,
        SortSelector(selected: SortMode.distance, onChanged: (_) {}),
      );

      expect(tester.takeException(), isNull);
      for (final label in const [
        'Distance',
        'Price',
        'A-Z',
        '24h',
        'Rating',
        'Price/km',
      ]) {
        final rect = tester.getRect(find.text(label));
        expect(
          rect.left >= 0 && rect.right <= 320,
          isTrue,
          reason: 'the "$label" chip must sit fully inside a 320 dp viewport '
              '— it is $rect',
        );
      }
    });

    testWidgets('default selection is highlighted as selected', (tester) async {
      await pumpApp(
        tester,
        SortSelector(selected: SortMode.distance, onChanged: (_) {}),
      );

      final chips = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .toList();
      expect(chips, hasLength(6));

      final distanceChip = chips.firstWhere(
        (c) => (c.label as Text).data == 'Distance',
      );
      expect(distanceChip.selected, isTrue);

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
        SortSelector(selected: SortMode.price, onChanged: (_) {}),
      );

      final chips = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .toList();
      final priceChip = chips.firstWhere(
        (c) => (c.label as Text).data == 'Price',
      );
      expect(priceChip.selected, isTrue);
    });

    for (final (label, expected) in const [
      ('Price', SortMode.price),
      ('A-Z', SortMode.name),
      ('24h', SortMode.open24h),
      ('Rating', SortMode.rating),
      ('Price/km', SortMode.priceDistance),
    ]) {
      testWidgets('tapping $label calls onChanged with $expected', (
        tester,
      ) async {
        SortMode? receivedMode;

        await pumpApp(
          tester,
          SortSelector(
            selected: SortMode.distance,
            onChanged: (mode) => receivedMode = mode,
          ),
        );

        await tester.tap(find.text(label));
        await tester.pumpAndSettle();

        expect(receivedMode, expected);
      });
    }

    testWidgets('each chip has an icon', (tester) async {
      await pumpApp(
        tester,
        SortSelector(selected: SortMode.distance, onChanged: (_) {}),
      );

      expect(find.byIcon(Icons.near_me), findsOneWidget);
      expect(find.byIcon(Icons.euro), findsOneWidget);
      expect(find.byIcon(Icons.sort_by_alpha), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.balance), findsOneWidget);
    });

    testWidgets('has correct semantics labels', (tester) async {
      await pumpApp(
        tester,
        SortSelector(selected: SortMode.price, onChanged: (_) {}),
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
        SortSelector(selected: SortMode.open24h, onChanged: (_) {}),
      );

      final chips = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .toList();
      final open24hChip = chips.firstWhere(
        (c) => (c.label as Text).data == '24h',
      );
      expect(open24hChip.selected, isTrue);

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
      expect(
        SortMode.values,
        containsAll([
          SortMode.distance,
          SortMode.price,
          SortMode.name,
          SortMode.open24h,
          SortMode.rating,
          SortMode.priceDistance,
        ]),
      );
    });
  });
}
