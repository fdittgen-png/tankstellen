// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/radar_search_fab.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/results_row.dart';
import 'package:tankstellen/features/search/presentation/widgets/sort_selector.dart';
import 'package:tankstellen/features/search/providers/brand_filter_provider.dart';
import 'package:tankstellen/features/search/providers/search_screen_ui_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #3943 — the results screen gave a whole strip back.
///
/// #3926 left row B as two stacked lines: the count line (count · radar ·
/// filter · view · overflow) and, under it, a `Wrap` of six sort chips that
/// spilled onto a second line of its own at 320 dp. This file pins the
/// single band that replaced them:
///
///  * the three glyph sort chips are laid out ON the icon row, not under
///    it — every control shares one horizontal band;
///  * three chips plus four controls fit 320 dp at a 1.3x text scale, the
///    narrowest/largest combination in the support matrix (the band has
///    overflowed twice in this area's history, by 2.4 px each time);
///  * `A-Z`, `24h` and `Price/km` were demoted into the overflow menu, not
///    deleted — each still sets its [SortMode], and the active one is
///    ticked.
///
/// The overflow guarantee is structural, not arithmetic: the sort group is
/// the row's only flexible child (an [Expanded]) and scrolls inside that
/// bounded slot, so nothing it contains can widen the row. A
/// `LayoutBuilder` could not have provided this — a non-flex child of a
/// `Row` is laid out with unbounded width and can measure nothing.
const _a = Station(
  id: 'fr-a',
  name: 'A',
  brand: 'TOTAL',
  street: 'rue A',
  postCode: '75001',
  place: 'Paris',
  lat: 48.85,
  lng: 2.35,
  dist: 1.2,
  e10: 1.75,
  isOpen: true,
);

const _b = Station(
  id: 'fr-b',
  name: 'B',
  brand: 'ESSO',
  street: 'rue B',
  postCode: '75002',
  place: 'Paris',
  lat: 48.86,
  lng: 2.36,
  dist: 2.4,
  e10: 1.95,
  isOpen: true,
);

const _items = <SearchResultItem>[FuelStationResult(_a), FuelStationResult(_b)];

/// Two picked brands, so the filter button carries its badge — the widest
/// the trailing controls ever get.
class _PickedBrands extends SelectedBrands {
  @override
  Set<String> build() => const {'TOTAL', 'ESSO'};
}

void main() {
  List<Object> seeded() {
    final test = standardTestOverrides();
    when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
    when(() => test.mockStorage.getIgnoredIds()).thenReturn(<String>[]);
    when(() => test.mockStorage.getRatings()).thenReturn(const <String, int>{});
    when(() => test.mockStorage.getSetting(any())).thenReturn(null);
    return [
      ...test.overrides,
      selectedBrandsProvider.overrideWith(_PickedBrands.new),
    ];
  }

  void narrow(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('#3943 — the sort chips joined the icon row', () {
    testWidgets('every control shares ONE horizontal band', (tester) async {
      narrow(tester);
      await pumpApp(
        tester,
        const SearchResultsRow(items: _items),
        overrides: seeded(),
      );

      final row = tester.getRect(find.byType(SearchResultsRow));
      final sort = tester.getRect(find.byType(SortSelector));
      final radar = tester.getRect(find.byType(RadarSearchChip));
      final filter = tester.getRect(find.byKey(const Key(
        'results_filter_button',
      )));
      final view = tester.getRect(find.byKey(const Key(
        'results_view_toggle',
      )));
      final menu = tester.getRect(find.byKey(const Key(
        'results_action_menu',
      )));

      // The sort group is not UNDER the controls any more: every one of
      // them overlaps it vertically, which is what "one band" means.
      for (final control in <Rect>[radar, filter, view, menu]) {
        expect(
          control.top < sort.bottom && control.bottom > sort.top,
          isTrue,
          reason: 'the sort chips must share the controls\' band — '
              'sort $sort vs control $control',
        );
      }

      // And the band is one control tall: the row is no taller than its
      // tallest child plus its own 2 dp of vertical padding. The two-line
      // shape it replaced was more than twice this.
      final tallest = <Rect>[
        sort,
        radar,
        filter,
        view,
        menu,
      ].map((r) => r.height).reduce((a, b) => a > b ? a : b);
      expect(row.height, lessThanOrEqualTo(tallest + 4));
    });

    testWidgets('the count is gone — nothing on the row is prose', (
      tester,
    ) async {
      narrow(tester);
      await pumpApp(
        tester,
        const SearchResultsRow(items: _items),
        overrides: seeded(),
      );

      expect(find.text('2 stations found'), findsNothing);
      // Only the filter badge is text; every other control is a glyph.
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('#3943 — no overflow at 320 dp with a 1.3x text scale', () {
    testWidgets('three chips plus four controls fit the narrowest screen', (
      tester,
    ) async {
      narrow(tester);
      await pumpScaledApp(
        tester,
        const SearchResultsRow(items: _items, onRadarToggle: _noop),
        textScaleFactor: 1.3,
        overrides: seeded(),
      );

      // A RenderFlex overflow throws in a test binding — this is the
      // assertion the 2.4 px regressions would have failed.
      expect(tester.takeException(), isNull);

      final row = tester.getRect(find.byType(SearchResultsRow));
      expect(row.width, 320);

      for (final finder in <Finder>[
        find.byType(SortSelector),
        find.byType(RadarSearchChip),
        find.byKey(const Key('results_filter_button')),
        find.byKey(const Key('results_view_toggle')),
        find.byKey(const Key('results_action_menu')),
      ]) {
        final rect = tester.getRect(finder);
        expect(
          rect.left >= 0 && rect.right <= 320,
          isTrue,
          reason: 'every control must sit inside the 320 dp row — '
              '$finder is $rect',
        );
      }

      // Every sort chip is reachable without a drag at this size, so the
      // scroller inside the Expanded slot is a guarantee, not a cost.
      for (final icon in const [Icons.near_me, Icons.euro, Icons.star]) {
        final rect = tester.getRect(find.byIcon(icon));
        expect(rect.right <= 320, isTrue, reason: '$icon is at $rect');
      }
    });

    testWidgets('the landscape radar variant drops the sort group without '
        'leaving a hole', (tester) async {
      narrow(tester);
      await pumpScaledApp(
        tester,
        const SearchResultsRow(items: _items, showSortAndFilter: false),
        textScaleFactor: 1.3,
        overrides: seeded(),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SortSelector), findsNothing);
      expect(find.byKey(const Key('results_filter_button')), findsNothing);
      // The controls that stay are pushed to the trailing edge.
      final menu = tester.getRect(find.byKey(const Key(
        'results_action_menu',
      )));
      expect(menu.right, closeTo(320 - 16, 8));
    });
  });

  group('#3943 — the demoted sort modes live in the overflow, not the bin', () {
    Future<ProviderContainer> openMenu(WidgetTester tester) async {
      await pumpApp(
        tester,
        const SearchResultsRow(items: _items),
        overrides: seeded(),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SearchResultsRow)),
      );
      await tester.tap(find.byKey(const Key('results_action_menu')));
      await tester.pumpAndSettle();
      return container;
    }

    for (final (key, label, mode) in const [
      ('results_sort_name', 'Sort by name (A–Z)', SortMode.name),
      ('results_sort_open24h', '24-hour stations first', SortMode.open24h),
      (
        'results_sort_price_distance',
        'Sort by price per kilometre',
        SortMode.priceDistance,
      ),
    ]) {
      testWidgets('"$label" is a labelled entry and still sorts', (
        tester,
      ) async {
        final container = await openMenu(tester);

        expect(find.text(label), findsOneWidget);
        expect(container.read(selectedSortModeProvider), isNot(mode));

        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();

        expect(container.read(selectedSortModeProvider), mode);
      });
    }

    testWidgets('the active mode is ticked, so the menu also answers "how is '
        'this sorted?"', (tester) async {
      final container = await openMenu(tester);
      container.read(selectedSortModeProvider.notifier).set(SortMode.open24h);
      await tester.pumpAndSettle();

      // Reopen with the mode active.
      await tester.tap(find.byKey(const Key('results_sort_name')));
      await tester.pumpAndSettle();
      container.read(selectedSortModeProvider.notifier).set(SortMode.open24h);
      await tester.pump();
      await tester.tap(find.byKey(const Key('results_action_menu')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('results_sort_open24h')),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('results_sort_name')),
          matching: find.byIcon(Icons.check),
        ),
        findsNothing,
      );
    });

    testWidgets('a ticked entry names its state to a screen reader', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const SearchResultsRow(items: _items),
        overrides: seeded(),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SearchResultsRow)),
      );
      container
          .read(selectedSortModeProvider.notifier)
          .set(SortMode.priceDistance);
      await tester.pump();
      await tester.tap(find.byKey(const Key('results_action_menu')));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Sort by price per kilometre, current sort'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}

void _noop() {}
