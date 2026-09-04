// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/navigation/current_shell_branch_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/widgets/page_scaffold.dart';
import 'package:tankstellen/features/map/presentation/screens/map_screen.dart';
import 'package:tankstellen/features/map/presentation/widgets/nearby_map_view.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_summary_bar.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

import '../../../../fixtures/stations.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// Branch index of the Carte tab in the bottom-nav `IndexedStack`.
const int _mapBranchIndex = 1;

/// Resolves the [ProviderContainer] backing the pumped `MapScreen`.
ProviderContainer _containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MapScreen)));

/// Simulates `ShellScreen` publishing a tab change, then settles the two
/// frames a branch flip needs to propagate.
Future<void> _goBranch(WidgetTester tester, int index) async {
  _containerOf(tester).read(currentShellBranchProvider.notifier).set(index);
  await tester.pumpAndSettle();
}

void main() {
  group('MapScreen — structural viewport gate (#1605)', () {
    testWidgets(
      'renders the canonical PageScaffold chrome regardless of branch '
      'visibility',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

        await pumpApp(
          tester,
          const MapScreen(),
          overrides: [...test.overrides, userPositionNullOverride()],
        );

        expect(find.byType(PageScaffold), findsOneWidget);
        expect(find.text('Map'), findsOneWidget);
      },
    );

    testWidgets(
      'does NOT build the FlutterMap subtree while Carte is offstage — '
      'TileLayer must never capture the IndexedStack zero-sized viewport',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

        // Default branch is 0 (Search) — Carte sits offstage in the shell
        // IndexedStack, mounted with degenerate constraints.
        await pumpApp(
          tester,
          const MapScreen(),
          overrides: [...test.overrides, userPositionNullOverride()],
        );

        expect(
          find.byType(NearbyMapView),
          findsNothing,
          reason:
              'While Carte is not the visible shell branch the FlutterMap '
              'subtree must not be built. Building it offstage is the root '
              'cause of the cold-start grey-tile bug (#473-#1316): '
              'TileLayer captures the IndexedStack pre-mount zero-sized '
              'viewport and never re-issues tile fetches.',
        );
      },
    );

    testWidgets(
      'builds the FlutterMap subtree once Carte becomes the visible branch',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

        await pumpApp(
          tester,
          const MapScreen(),
          overrides: [...test.overrides, userPositionNullOverride()],
        );

        await _goBranch(tester, _mapBranchIndex);

        expect(
          find.byType(NearbyMapView),
          findsOneWidget,
          reason:
              'When Carte is the visible shell branch the FlutterMap '
              'subtree must be built. The shell publishes the branch index '
              'before the IndexedStack promotes the branch onstage, so this '
              'first layout pass runs against real constraints.',
        );
      },
    );

    testWidgets(
      'exposes the refresh-prices action in the app bar',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

        await pumpApp(
          tester,
          const MapScreen(),
          overrides: [...test.overrides, userPositionNullOverride()],
        );

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      },
    );

    testWidgets(
      'exposes the share action in the app bar (#1959)',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

        await pumpApp(
          tester,
          const MapScreen(),
          overrides: [...test.overrides, userPositionNullOverride()],
        );

        expect(find.byIcon(Icons.share), findsOneWidget);
      },
    );

    testWidgets(
      'a long-gap app resume while Carte is visible does not throw',
      (tester) async {
        final test = standardTestOverrides();
        when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

        await pumpApp(
          tester,
          MapScreen(
            clockOverride: () => DateTime(2026, 5, 15, 12),
          ),
          overrides: [...test.overrides, userPositionNullOverride()],
        );
        await _goBranch(tester, _mapBranchIndex);

        final binding = tester.binding;
        binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        // The resume path re-issues the last search; with no prior search
        // it is a harmless no-op. The assertion is simply that the
        // lifecycle round-trip leaves the screen mounted and intact.
        expect(find.byType(MapScreen), findsOneWidget);
      },
    );
  });

  // #3949 (Epic #3947) — the map's bottom info bar ("25 stations · 25 km ·
  // < 1 min") is gone; the results chrome's SearchSummaryBar sits above the
  // map instead and carries the station count as one more summary chip.
  group('MapScreen — summary bar header (#3949)', () {
    testWidgets('renders the SearchSummaryBar above the map once Carte is '
        'visible, and not while offstage', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

      await pumpApp(
        tester,
        const MapScreen(),
        overrides: [...test.overrides, userPositionNullOverride()],
      );
      expect(find.byType(SearchSummaryBar), findsNothing);

      await _goBranch(tester, _mapBranchIndex);
      expect(find.byType(SearchSummaryBar), findsOneWidget);
      final barBottom = tester.getBottomLeft(find.byType(SearchSummaryBar)).dy;
      final mapTop = tester.getTopLeft(find.byType(NearbyMapView)).dy;
      expect(barBottom, lessThanOrEqualTo(mapTop));
    });

    testWidgets('the station count is a summary chip in the header; the old '
        'bottom bar is gone', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);

      await pumpApp(
        tester,
        const MapScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
          searchStateProvider.overrideWith(_ThreeStationsSearchState.new),
        ],
      );
      await _goBranch(tester, _mapBranchIndex);

      final chip = find.byKey(const Key('search_summary_station_count'));
      expect(chip, findsOneWidget);
      expect(find.text('3 stations'), findsOneWidget);
      // The count lives in the header band, above the map body.
      expect(
        tester.getBottomLeft(chip).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(NearbyMapView)).dy),
      );
      // No second rendering of the count anywhere below the map.
      expect(find.textContaining('stations'), findsOneWidget);
    });
  });
}

/// A landed nearby search with three fuel stations, so the header can
/// count them.
class _ThreeStationsSearchState extends SearchState {
  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() => AsyncValue.data(
        ServiceResult(
          data: [for (final s in testStationList) FuelStationResult(s)],
          source: ServiceSource.tankerkoenigApi,
          fetchedAt: DateTime(2026, 9, 4, 12),
        ),
      );
}
