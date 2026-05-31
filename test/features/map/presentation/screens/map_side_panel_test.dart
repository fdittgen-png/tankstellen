// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/app/current_shell_branch_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/map/presentation/screens/map_screen.dart';
import 'package:tankstellen/features/map/presentation/widgets/nearby_map_view.dart';
import 'package:tankstellen/features/map/presentation/widgets/price_legend.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/selected_station_provider.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_detail_inline.dart';
import 'package:tankstellen/features/station_detail/providers/station_detail_provider.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// Branch index of the Carte tab in the bottom-nav `IndexedStack`.
const int _mapBranchIndex = 1;

/// A [SelectedStation] notifier pre-seeded with a selection so the wide map
/// renders the side-panel detail without a tap gesture in the test.
class _SelectedStation extends SelectedStation {
  final String? _initial;
  _SelectedStation(this._initial);

  @override
  String? build() => _initial;
}

ProviderContainer _containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MapScreen)));

Future<void> _goBranch(WidgetTester tester, int index) async {
  _containerOf(tester).read(currentShellBranchProvider.notifier).set(index);
  await tester.pumpAndSettle();
}

void main() {
  const stationId = '51d4b477-a095-1aa0-e100-80009459e03a';

  /// Pumps the MapScreen at [size], optionally with a pre-selected station,
  /// and brings the Carte tab onstage (the #1605 viewport gate only builds
  /// the map subtree once Carte is the visible branch).
  Future<void> pumpMap(
    WidgetTester tester, {
    required Size size,
    String? selected,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final test = standardTestOverrides();
    when(() => test.mockStorage.hasApiKey()).thenReturn(false);
    // The inline detail mounts a PriceHistorySection + rating section that
    // read price records / ratings off storage — stub them so the detail
    // pane builds without a provider-error throw.
    when(() => test.mockStorage.getPriceRecords(any())).thenReturn([]);
    when(() => test.mockStorage.getPriceHistoryKeys()).thenReturn([]);
    when(() => test.mockStorage.savePriceRecords(any(), any()))
        .thenAnswer((_) async {});
    when(() => test.mockStorage.getRatings()).thenReturn({});
    when(() => test.mockStorage.getRating(any())).thenReturn(null);

    final detailResult = ServiceResult(
      data: const StationDetail(station: testStation),
      source: ServiceSource.cache,
      fetchedAt: DateTime(2026, 3, 27, 10),
    );

    await pumpApp(
      tester,
      const MapScreen(),
      overrides: [
        ...test.overrides,
        userPositionNullOverride(),
        selectedStationProvider.overrideWith(() => _SelectedStation(selected)),
        stationDetailProvider(stationId).overrideWith((_) async => detailResult),
      ],
    );
    await _goBranch(tester, _mapBranchIndex);
  }

  group('MapScreen side-panel detail (#2532)', () {
    testWidgets(
      'wide (900x600) with a selected station renders the inline detail '
      'pane beside the map (a VerticalDivider splits the two panes)',
      (tester) async {
        await pumpMap(tester, size: const Size(900, 600), selected: stationId);

        // The detail pane is the inline station detail.
        expect(find.byType(StationDetailInline), findsOneWidget);
        // The two-pane split is identified by the master/detail divider.
        expect(find.byType(VerticalDivider), findsOneWidget);
        // The map (master pane) is still built full-bleed beside it.
        expect(find.byType(NearbyMapView), findsOneWidget);
      },
    );

    testWidgets(
      'wide (900x600) with NO selection renders the empty-state legend '
      'placeholder, not a detail pane',
      (tester) async {
        await pumpMap(tester, size: const Size(900, 600), selected: null);

        // No station selected → the placeholder, not the inline detail.
        expect(find.byType(StationDetailInline), findsNothing);
        // The empty-state placeholder carries the price legend.
        expect(find.byType(PriceLegend), findsWidgets);
        // The split container is still present on a wide screen.
        expect(find.byType(VerticalDivider), findsOneWidget);
      },
    );

    testWidgets(
      'compact (400x800) stays full-bleed — no detail pane, no divider, '
      'even when a station is selected',
      (tester) async {
        await pumpMap(tester, size: const Size(400, 800), selected: stationId);

        // On compact the map is full-bleed: ResponsiveMasterDetail hides the
        // detail entirely, so neither the inline detail nor the master/detail
        // divider is mounted. The marker tap keeps its `/station/:id` push.
        expect(find.byType(StationDetailInline), findsNothing);
        expect(find.byType(VerticalDivider), findsNothing);
        expect(find.byType(NearbyMapView), findsOneWidget);
      },
    );
  });
}
