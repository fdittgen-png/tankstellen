// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/navigation/current_shell_branch_provider.dart';
import 'package:tankstellen/core/widgets/responsive_layout.dart';
import 'package:tankstellen/features/map/presentation/screens/map_screen.dart';
import 'package:tankstellen/features/map/presentation/widgets/nearby_map_view.dart';
import 'package:tankstellen/features/search/providers/selected_station_provider.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_detail_inline.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// Branch index of the Carte tab in the bottom-nav `IndexedStack`.
const int _mapBranchIndex = 1;

/// A [SelectedStation] notifier pre-seeded with a selection. Used to prove
/// that — after the #2547 revert — a selected station no longer surfaces a
/// side-panel detail on the map (a marker tap pushes `/station/:id` instead).
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

    await pumpApp(
      tester,
      const MapScreen(),
      overrides: [
        ...test.overrides,
        userPositionNullOverride(),
        selectedStationProvider.overrideWith(() => _SelectedStation(selected)),
      ],
    );
    await _goBranch(tester, _mapBranchIndex);
  }

  group('MapScreen full horizontal width (#2547 — reverts the #2532 split)',
      () {
    testWidgets(
      'wide (900x600): the map is full-bleed — no master/detail split, '
      'no detail pane, the map fills the whole content width',
      (tester) async {
        await pumpMap(tester, size: const Size(900, 600), selected: null);

        // The map body is the full body.
        expect(find.byType(NearbyMapView), findsOneWidget);
        // No side-panel split: the #2532 ResponsiveMasterDetail wrapper +
        // its VerticalDivider are gone, so the map owns the full width.
        expect(find.byType(ResponsiveMasterDetail), findsNothing);
        expect(find.byType(VerticalDivider), findsNothing);
        // No detail pane either.
        expect(find.byType(StationDetailInline), findsNothing);
      },
    );

    testWidgets(
      'wide (900x600): a selected station does NOT open a side-panel — the '
      'marker tap no longer feeds selectedStationProvider into a detail pane',
      (tester) async {
        // Pre-seed a selection as if a marker had been tapped. Pre-#2532 (and
        // post-revert) behaviour is a `/station/:id` push, never a side-panel,
        // so even a non-null selection must not surface an inline detail.
        await pumpMap(tester, size: const Size(900, 600), selected: stationId);

        expect(find.byType(StationDetailInline), findsNothing);
        expect(find.byType(VerticalDivider), findsNothing);
        expect(find.byType(ResponsiveMasterDetail), findsNothing);
        // The map still owns the full content area.
        expect(find.byType(NearbyMapView), findsOneWidget);
      },
    );

    testWidgets(
      'compact (400x800): unchanged — full-bleed map, no detail pane, '
      'no divider, even with a selected station',
      (tester) async {
        await pumpMap(tester, size: const Size(400, 800), selected: stationId);

        expect(find.byType(StationDetailInline), findsNothing);
        expect(find.byType(VerticalDivider), findsNothing);
        expect(find.byType(ResponsiveMasterDetail), findsNothing);
        expect(find.byType(NearbyMapView), findsOneWidget);
      },
    );
  });
}
