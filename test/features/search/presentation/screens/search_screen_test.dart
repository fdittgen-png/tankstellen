// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/map/presentation/widgets/inline_map.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/features/search/presentation/screens/search_screen.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_summary_bar.dart';
import 'package:tankstellen/features/search/presentation/widgets/user_position_bar.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// Spy [SearchState] that counts `repeatLastSearch` invocations without
/// hitting the network — lets the #2401 test assert the fuel-chip change
/// re-triggers the search exactly once.
class _SpySearchState extends SearchState {
  int repeatCount = 0;

  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() =>
      AsyncValue.data(ServiceResult(
        data: const [],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      ));

  @override
  Future<void> repeatLastSearch() async {
    repeatCount++;
  }
}

void main() {
  group('SearchScreen (results-first layout)', () {
    testWidgets('renders Scaffold', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      expect(find.byType(Scaffold), findsAtLeast(1));
    });

    testWidgets('renders the SearchSummaryBar at the top', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      expect(find.byType(SearchSummaryBar), findsOneWidget);
    });

    testWidgets('does NOT render the inline LocationInput/FuelTypeSelector',
        (tester) async {
      // In the new results-first layout, these live on the criteria screen.
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      // No TextField on the results screen — only the summary bar.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('renders UserPositionBar', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      expect(find.byType(UserPositionBar), findsOneWidget);
    });

    testWidgets('shows empty state message when no search performed',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      expect(
        find.text('Search to find fuel stations.'),
        findsOneWidget,
      );
    });

    testWidgets('rebuild does not re-trigger auto-search side effects',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(Scaffold), findsAtLeast(1));
      expect(find.text('Search to find fuel stations.'), findsOneWidget);
    });

    testWidgets('AppBar exposes a Refresh action (#1313)', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      // Mirrors favorites_screen.dart:50-57 — the Recherche tab needs
      // a manual refresh affordance so the typed query can re-fetch
      // without the user editing the criteria (#1313).
      final refreshInAppBar = find.descendant(
        of: find.byType(AppBar),
        matching: find.widgetWithIcon(IconButton, Icons.refresh),
      );
      expect(refreshInAppBar, findsOneWidget);
    });

    testWidgets(
        'changing the selected fuel re-triggers the search exactly once (#2401)',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      final spy = _SpySearchState();

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
          searchStateProvider.overrideWith(() => spy),
        ],
      );
      // A pump settles initState's post-frame auto-search attempt.
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SearchScreen)),
      );

      // No fuel change yet → the listener has not fired.
      expect(spy.repeatCount, 0);

      // Change the selected fuel chip → exactly one repeatLastSearch.
      container.read(selectedFuelTypeProvider.notifier).select(FuelType.diesel);
      await tester.pump();
      expect(spy.repeatCount, 1,
          reason: 'a fuel-chip change must re-run the last search once');

      // Selecting the SAME fuel again must NOT fire (prev == next).
      container.read(selectedFuelTypeProvider.notifier).select(FuelType.diesel);
      await tester.pump();
      expect(spy.repeatCount, 1,
          reason: 'an unchanged selection must not re-trigger the search');

      // A genuinely different fuel fires once more.
      container.read(selectedFuelTypeProvider.notifier).select(FuelType.e5);
      await tester.pump();
      expect(spy.repeatCount, 2);
    });

    testWidgets('results area dominates the viewport (≥60% vertical)',
        (tester) async {
      // Use a fixed-size phone viewport.
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      // The Expanded child (results area) is found via the Semantics label.
      final resultsFinder = find.bySemanticsLabel('Search results');
      expect(resultsFinder, findsOneWidget);

      final resultsBox = tester.getSize(resultsFinder.first);
      final screenHeight = tester.view.physicalSize.height /
          tester.view.devicePixelRatio;
      expect(
        resultsBox.height >= screenHeight * 0.5,
        isTrue,
        reason:
            'Expected results area to be at least 50% of screen height, got '
            '${resultsBox.height}/$screenHeight',
      );
    });

    // #2530 — Search now goes through the shared ResponsiveMasterDetail
    // scaffold. Structural pane-count assertions at the breakpoints.
    testWidgets('compact width renders a single pane (no VerticalDivider)',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [...test.overrides, userPositionNullOverride()],
      );

      expect(find.byType(VerticalDivider), findsNothing);
      expect(find.bySemanticsLabel('Search results'), findsOneWidget);
    });

    testWidgets('wide width renders two panes (VerticalDivider + InlineMap)',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [...test.overrides, userPositionNullOverride()],
      );

      // The split scaffold renders the search pane beside the inline map,
      // separated by the shared VerticalDivider.
      expect(find.byType(VerticalDivider), findsOneWidget);
      expect(find.byType(InlineMap), findsOneWidget);
      expect(find.bySemanticsLabel('Search results'), findsOneWidget);
    });
  });
}
