// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/widgets/sort_selector.dart';

import '../../../../helpers/pump_app.dart';

/// #3939 — an icon-only sort chip has an [Icon] where the others have a
/// [Text], so it is addressed by its glyph.
ChoiceChip _chipWithIcon(List<ChoiceChip> chips, IconData icon) =>
    chips.firstWhere((c) => c.label is Icon && (c.label as Icon).icon == icon);

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

      // #3939 — distance, price and rating render ICON-ONLY: the arrow,
      // the euro sign and the star already say the word. The three whose
      // glyph says nothing keep their text.
      expect(find.text('Distance'), findsNothing);
      expect(find.text('Price'), findsNothing);
      expect(find.text('Rating'), findsNothing);
      expect(find.byIcon(Icons.near_me), findsOneWidget);
      expect(find.byIcon(Icons.euro), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);

      expect(find.text('A-Z'), findsOneWidget);
      expect(find.text('24h'), findsOneWidget);
      expect(find.text('Price/km'), findsOneWidget);
    });

    testWidgets('#3939 — every icon-only sort chip carries its label as a '
        'tooltip AND in its semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        SortSelector(selected: SortMode.distance, onChanged: (_) {}),
      );

      for (final label in const ['Distance', 'Price', 'Rating']) {
        expect(
          find.byTooltip(label),
          findsOneWidget,
          reason: 'the icon-only "$label" chip must name itself on '
              'long-press',
        );
        expect(
          find.bySemanticsLabel(
            RegExp('^Sort by ${RegExp.escape(label)}(,.*)?\$'),
          ),
          findsOneWidget,
          reason: 'the icon-only "$label" chip must name itself to a '
              'screen reader',
        );
      }
      handle.dispose();
    });

    testWidgets('#3939 — a selected icon-only chip KEEPS its glyph (a bare '
        'checkmark would say nothing)', (tester) async {
      await pumpApp(
        tester,
        SortSelector(selected: SortMode.price, onChanged: (_) {}),
      );

      expect(find.byIcon(Icons.euro), findsOneWidget);
      expect(find.byIcon(Icons.near_me), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
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
      for (final label in const ['A-Z', '24h', 'Price/km']) {
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

      expect(_chipWithIcon(chips, Icons.near_me).selected, isTrue);
      expect(_chipWithIcon(chips, Icons.euro).selected, isFalse);

      final nameChip = chips.firstWhere(
        (c) => c.label is Text && (c.label as Text).data == 'A-Z',
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
      expect(_chipWithIcon(chips, Icons.euro).selected, isTrue);
    });

    for (final (label, expected) in const [
      ('A-Z', SortMode.name),
      ('24h', SortMode.open24h),
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

    // #3939 — the icon-only chips are tapped by their glyph.
    for (final (icon, expected) in const [
      (Icons.euro, SortMode.price),
      (Icons.star, SortMode.rating),
    ]) {
      testWidgets('tapping the $expected glyph calls onChanged', (
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

        await tester.tap(find.byIcon(icon));
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
        (c) => c.label is Text && (c.label as Text).data == '24h',
      );
      expect(open24hChip.selected, isTrue);

      expect(_chipWithIcon(chips, Icons.near_me).selected, isFalse);
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
