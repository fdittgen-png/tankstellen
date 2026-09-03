// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/presentation/widgets/sort_selector.dart';

import '../../../../helpers/pump_app.dart';

/// #3939 / #3943 — every sort chip is icon-only now, so a chip is addressed
/// by its glyph.
ChoiceChip _chipWithIcon(List<ChoiceChip> chips, IconData icon) =>
    chips.firstWhere((c) => c.label is Icon && (c.label as Icon).icon == icon);

void main() {
  group('SortSelector', () {
    testWidgets('renders exactly the three glyph chips (#3943)', (
      tester,
    ) async {
      await pumpApp(
        tester,
        SortSelector(selected: SortMode.distance, onChanged: (_) {}),
      );

      // #3943 — the selector joined the results icon row, so only the modes
      // whose glyph is unambiguous stay on screen: the navigation arrow is
      // distance, the euro sign is price, the star is rating.
      expect(find.byType(ChoiceChip), findsNWidgets(3));
      expect(find.byIcon(Icons.near_me), findsOneWidget);
      expect(find.byIcon(Icons.euro), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);

      // The three modes no glyph can say moved into the overflow menu —
      // they are not chips any more, and they are not words here either.
      for (final gone in const ['A-Z', '24h', 'Price/km']) {
        expect(find.text(gone), findsNothing);
      }
      expect(find.byIcon(Icons.sort_by_alpha), findsNothing);
      expect(find.byIcon(Icons.schedule), findsNothing);
      expect(find.byIcon(Icons.balance), findsNothing);

      // No chip spells a word its glyph already says, either.
      for (final word in const ['Distance', 'Price', 'Rating']) {
        expect(find.text(word), findsNothing);
      }
    });

    testWidgets('#3943 — the group scrolls inside its own slot rather than '
        'growing the row', (tester) async {
      await pumpApp(
        tester,
        SortSelector(selected: SortMode.distance, onChanged: (_) {}),
      );

      // A `LayoutBuilder` cannot measure the room left in a Row (non-flex
      // children are laid out unbounded), so the guarantee is structural:
      // the group is a horizontal scroller, and the row hands it a bounded
      // Expanded slot. It can never push the row past its own width.
      final scroller = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scroller.scrollDirection, Axis.horizontal);
    });

    testWidgets('#3939 — every chip carries its label as a tooltip AND in '
        'its semantics', (tester) async {
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

    testWidgets('#3939 — a selected chip KEEPS its glyph (a bare checkmark '
        'would say nothing)', (tester) async {
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
      for (final icon in const [Icons.near_me, Icons.euro, Icons.star]) {
        final rect = tester.getRect(find.byIcon(icon));
        expect(
          rect.left >= 0 && rect.right <= 320,
          isTrue,
          reason: 'the $icon chip must sit fully inside a 320 dp viewport '
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
      expect(chips, hasLength(3));

      expect(_chipWithIcon(chips, Icons.near_me).selected, isTrue);
      expect(_chipWithIcon(chips, Icons.euro).selected, isFalse);
      expect(_chipWithIcon(chips, Icons.star).selected, isFalse);
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

    // #3939 — the chips are tapped by their glyph.
    for (final (icon, expected) in const [
      (Icons.near_me, SortMode.distance),
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
            selected: SortMode.open24h,
            onChanged: (mode) => receivedMode = mode,
          ),
        );

        await tester.tap(find.byIcon(icon));
        await tester.pumpAndSettle();

        expect(receivedMode, expected);
      });
    }

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

    testWidgets('a mode that lives in the overflow menu leaves every chip '
        'unselected (#3943)', (tester) async {
      await pumpApp(
        tester,
        SortSelector(selected: SortMode.open24h, onChanged: (_) {}),
      );

      final chips = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .toList();
      expect(chips.every((c) => !c.selected), isTrue);
    });
  });

  group('SortMode enum', () {
    test('has six values — #3943 moved three of them, deleted none', () {
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

    test('the three visible chips are the glyph modes (#3943)', () {
      expect(SortSelector.visibleModes, const [
        SortMode.distance,
        SortMode.price,
        SortMode.rating,
      ]);
    });
  });
}
