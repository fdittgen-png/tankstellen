// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/widgets/help_banner.dart';
import 'package:tankstellen/features/search/presentation/widgets/all_prices/all_prices_table_header.dart';
import 'package:tankstellen/features/search/presentation/widgets/radar_search_fab.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/results_row.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_list.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_summary_bar.dart';
import 'package:tankstellen/features/search/presentation/widgets/sort_selector.dart';
import 'package:tankstellen/features/search/providers/all_prices_comparison_model.dart';
import 'package:tankstellen/features/search/providers/all_prices_table_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #3939 (Epic #3937) — "an icon that carries the meaning gets no label;
/// text is reserved for what the icon cannot say", and "explanation is not
/// chrome".
///
/// This file pins the three claims that make the epic true rather than
/// merely tidy:
///
///  1. every chip the epic named renders its VALUE only, and hands its
///     sentence to a tooltip and a semantics label — so nothing is lost;
///  2. the results row spends its 320 dp on controls rather than on words
///     — the symptom the extended radar chip caused (#3943 has since
///     deleted the count that used to prove it);
///  3. the permanent all-prices legend is gone from the layout, and the
///     explanation it carried is reachable on the search surface's help
///     bubble instead.
///
/// Measured at 320 dp (the narrowest width in the support matrix), where
/// the chrome cost the most: row A fell 98 → 68 dp, row B 148 → 128 dp,
/// and the all-prices header lost its 82 dp legend block.
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

void main() {
  List<Object> seeded() {
    final test = standardTestOverrides();
    when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
    when(() => test.mockStorage.getIgnoredIds()).thenReturn(<String>[]);
    when(() => test.mockStorage.getRatings()).thenReturn(const <String, int>{});
    when(() => test.mockStorage.getSetting(any())).thenReturn(null);
    return test.overrides;
  }

  void narrow(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('#3939 — the summary bar carries values, not sentences', () {
    testWidgets('no pill repeats the noun its glyph already says', (
      tester,
    ) async {
      narrow(tester);
      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...seeded(),
          selectedFuelTypeOverride(FuelType.e85),
          searchRadiusOverride(10),
          userPositionNullOverride(),
        ],
      );

      // The value is what shows …
      expect(find.text('E85'), findsOneWidget);
      expect(find.text('10 km'), findsOneWidget);
      // … and every word the annotated screenshot struck out is gone.
      for (final struck in const [
        'E85 / Bioéthanol',
        'Within 10 km',
        'Super E10',
      ]) {
        expect(
          find.text(struck),
          findsNothing,
          reason: '"$struck" repeats what the pill\'s glyph already says',
        );
      }
    });
  });

  group('#3939 — the results row spends its width on controls, not words', () {
    testWidgets('at 320 dp the radar action is a glyph, and #3943 has since '
        'taken the count away entirely', (tester) async {
      narrow(tester);
      await pumpApp(
        tester,
        const SearchResultsRow(
          items: [FuelStationResult(_a), FuelStationResult(_b)],
        ),
        overrides: seeded(),
      );

      // #3939 shrank the extended radar pill to a glyph so the count had
      // room to render in full. #3943 then deleted the count outright — the
      // list already says how many results there are — and gave the width
      // to the sort chips.
      expect(find.text('2 stations found'), findsNothing);
      expect(find.byType(SortSelector), findsOneWidget);

      // The radar action is still what freed the room: a glyph, not a
      // phrase.
      expect(find.byType(RadarSearchChip), findsOneWidget);
      expect(find.text('Start fuel station radar'), findsNothing);
      expect(find.byTooltip('Start fuel station radar'), findsOneWidget);
    });
  });

  group('#3939 — the legend left the layout for the help bubble', () {
    testWidgets('the all-prices header is column codes and nothing else', (
      tester,
    ) async {
      narrow(tester);
      await pumpApp(
        tester,
        const AllPricesTableHeader(),
        overrides: [
          ...seeded(),
          allPricesColumnsProvider.overrideWithValue(
            const AllPricesColumns(
              visible: [FuelType.e10, FuelType.e98, FuelType.diesel],
              overflow: [],
            ),
          ),
          allPricesFuelCostModelProvider.overrideWithValue(
            const FuelCostModel(
              litersPer100kmByFuel: {FuelType.e10: 6.0},
              usableFuels: {FuelType.e10},
            ),
          ),
        ],
      );

      expect(find.textContaining('cheapest of these results'), findsNothing);
      // One row of codes: the header now costs a single line of height.
      expect(
        tester.getSize(find.byType(AllPricesTableHeader)).height,
        lessThan(30),
      );
    });

    testWidgets('the search surface teaches the same two things on its help '
        'bubble instead', (tester) async {
      await pumpApp(
        tester,
        SearchResultsList(
          result: ServiceResult<List<SearchResultItem>>(
            data: const [FuelStationResult(_a)],
            source: ServiceSource.cache,
            fetchedAt: DateTime(2026, 3, 11),
          ),
          onRefresh: () {},
        ),
        overrides: seeded(),
      );

      expect(find.byType(HelpBanner), findsOneWidget);

      // Tip 2 and tip 3 are the two halves of the deleted legend. Page to
      // them from the first tip.
      const key = StorageKeys.helpBannerSearchResults;
      await tester.tap(find.byKey(const ValueKey('help-bubble-next-$key')));
      await tester.pumpAndSettle();
      expect(find.textContaining('cheapest price for that fuel'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('help-bubble-next-$key')));
      await tester.pumpAndSettle();
      expect(find.textContaining('100 km'), findsOneWidget);
    });

    testWidgets('a dismissed bubble leaves the results screen with two '
        'chrome rows and nothing else', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      when(() => test.mockStorage.getIgnoredIds()).thenReturn(<String>[]);
      when(
        () => test.mockStorage.getRatings(),
      ).thenReturn(const <String, int>{});
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);
      when(
        () => test.mockStorage.getSetting(StorageKeys.helpBannerSearchResults),
      ).thenReturn(true);

      await pumpApp(
        tester,
        SearchResultsList(
          result: ServiceResult<List<SearchResultItem>>(
            data: const [FuelStationResult(_a)],
            source: ServiceSource.cache,
            fetchedAt: DateTime(2026, 3, 11),
          ),
          onRefresh: () {},
        ),
        overrides: test.overrides,
      );

      expect(find.byType(SearchResultsRow), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey(
            'help-bubble-pager-${StorageKeys.helpBannerSearchResults}',
          ),
        ),
        findsNothing,
      );
    });
  });
}
