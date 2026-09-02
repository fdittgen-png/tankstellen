// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/search/presentation/widgets/radar_search_fab.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/results_action_menu.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/results_row.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_content.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_summary_bar.dart';
import 'package:tankstellen/features/search/presentation/widgets/sort_selector.dart';
import 'package:tankstellen/features/search/presentation/widgets/user_position_bar.dart';
import 'package:tankstellen/features/search/providers/brand_filter_provider.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/features/search/providers/search_screen_ui_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #3926 (epic #3925) — the results screen used to stack SIX chrome strips
/// above the first station card: the country source link, the fuel/radius
/// chips, "Your position: GPS (1 min)" with a second refresh icon, the count
/// row with three unlabelled icon buttons and a wordless amber pill, the
/// clipped sort scroller and the "All brands ⌄" filter header. This pins the
/// two-row replacement.

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

class _LoadedSearch extends SearchState {
  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() => AsyncValue.data(
    ServiceResult(
      data: const [FuelStationResult(_a), FuelStationResult(_b)],
      source: ServiceSource.prixCarburantsApi,
      fetchedAt: DateTime(2026, 3, 11, 14, 30),
    ),
  );
}

class _PickedBrands extends SelectedBrands {
  @override
  Set<String> build() => const {'TOTAL', 'ESSO'};
}

Future<void> noopRetry() async {}

void main() {
  List<Object> seeded() {
    final test = standardTestOverrides();
    when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
    when(() => test.mockStorage.getIgnoredIds()).thenReturn(<String>[]);
    when(() => test.mockStorage.getRatings()).thenReturn(const <String, int>{});
    when(() => test.mockStorage.getSetting(any())).thenReturn(null);
    return test.overrides;
  }

  group('Row B — the results row', () {
    testWidgets('carries the count, the radar chip, the sort chips and one '
        'overflow button — no bare glyph rows', (tester) async {
      final overrides = seeded();

      await pumpApp(
        tester,
        const SearchResultsContent(onGpsRetry: noopRetry),
        overrides: [
          ...overrides,
          searchStateProvider.overrideWith(_LoadedSearch.new),
        ],
      );

      expect(find.byType(SearchResultsRow), findsOneWidget);
      expect(find.text('2 stations found'), findsOneWidget);
      expect(find.byType(SortSelector), findsOneWidget);
      expect(find.byType(RadarSearchChip), findsOneWidget);
      expect(find.byType(ResultsActionMenu), findsOneWidget);

      // The three unlabelled header icons are gone from the row itself.
      expect(find.byIcon(Icons.map), findsNothing);
      expect(find.byIcon(Icons.calculate), findsNothing);
    });

    testWidgets('the overflow opens LABELLED entries that keep their keys and '
        'accessibility labels', (tester) async {
      final overrides = seeded();

      await pumpApp(
        tester,
        const SearchResultsContent(onGpsRetry: noopRetry),
        overrides: [
          ...overrides,
          searchStateProvider.overrideWith(_LoadedSearch.new),
        ],
      );

      await tester.tap(find.byKey(const Key('results_action_menu')));
      await tester.pumpAndSettle();

      expect(find.text('Show stations on map'), findsOneWidget);
      expect(find.text('Fuel Cost Calculator'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Show stations on map'),
        findsOneWidget,
      );
    });

    testWidgets('the filter button badges the number of active filters and '
        'expands the filter panel', (tester) async {
      final overrides = seeded();

      await pumpApp(
        tester,
        const SearchResultsContent(onGpsRetry: noopRetry),
        overrides: [
          ...overrides,
          searchStateProvider.overrideWith(_LoadedSearch.new),
          selectedBrandsProvider.overrideWith(_PickedBrands.new),
        ],
      );

      expect(find.byKey(const Key('results_filter_button')), findsOneWidget);
      // Two selected brands → a "2" badge on the glyph.
      expect(find.text('2'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Filters, 2 active'),
        findsOneWidget,
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SearchResultsRow)),
      );
      expect(container.read(brandFiltersExpandedProvider), isFalse);
      await tester.tap(find.byKey(const Key('results_filter_button')));
      await tester.pump();
      expect(container.read(brandFiltersExpandedProvider), isTrue);
    });

    testWidgets('every icon action on the row carries a tooltip', (
      tester,
    ) async {
      final overrides = seeded();

      await pumpApp(
        tester,
        const SearchResultsContent(onGpsRetry: noopRetry),
        overrides: [
          ...overrides,
          searchStateProvider.overrideWith(_LoadedSearch.new),
        ],
      );

      expect(find.byTooltip('Filters'), findsOneWidget);
      expect(find.byTooltip('Switch to all-prices view'), findsOneWidget);
      expect(find.byTooltip('More actions'), findsOneWidget);
    });
  });

  group('Two chrome rows at 320 dp', () {
    testWidgets('row A and row B are the only chrome above the first card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final overrides = seeded();

      await pumpApp(
        tester,
        const Column(
          children: [
            SearchSummaryBar(),
            Expanded(child: SearchResultsContent(onGpsRetry: noopRetry)),
          ],
        ),
        overrides: [
          ...overrides,
          userPositionNullOverride(),
          searchStateProvider.overrideWith(_LoadedSearch.new),
        ],
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SearchSummaryBar), findsOneWidget);
      expect(find.byType(SearchResultsRow), findsOneWidget);
      // The position strip is a segment INSIDE row A now, not a strip.
      expect(
        find.descendant(
          of: find.byType(SearchSummaryBar),
          matching: find.byType(UserPositionBar),
        ),
        findsOneWidget,
      );
      // Row B sits above the first station card.
      final rowB = tester.getRect(find.byType(SearchResultsRow));
      final firstCard = tester.getRect(
        find.byKey(const ValueKey('station-fr-a')),
      );
      expect(rowB.bottom, lessThanOrEqualTo(firstCard.top));
    });
  });
}
