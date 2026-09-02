// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// The mocktail Mock* storage doubles are deprecated as a steering hint
// (prefer the stateful fakes) but remain sanctioned for widget tests that
// stub reads exclusively -- see test/helpers/mock_providers.dart (#3742).
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/price_history/data/repositories/price_history_repository.dart';
import 'package:tankstellen/features/price_history/providers/price_history_provider.dart';
import 'package:tankstellen/features/station_detail/presentation/screens/station_detail_screen.dart';
import 'package:tankstellen/features/station_detail/providers/station_detail_provider.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

/// #3928 — the price-history fold link must clear the "Navigate" FAB.
///
/// In the field report the "Afficher tous les types" text button sat
/// half-hidden under the extended directions FAB: the last row of the
/// scroll view and the FAB occupied the same pixels. The screen already
/// reserves `kFabScrollClearance` plus the bottom safe-area inset
/// (#3902); this pins that the reservation is actually enough once the
/// price-history foldable is open, which is when the link exists.
void main() {
  const stationId = '51d4b477-a095-1aa0-e100-80009459e03a';

  testWidgets('the "Show all fuel types" link never intersects the '
      'directions FAB at 360x640', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockStorage = MockHiveStorage();
    when(() => mockStorage.getPriceRecords(any())).thenReturn([]);
    when(() => mockStorage.getPriceHistoryKeys()).thenReturn([]);
    when(() => mockStorage.getRatings()).thenReturn({});
    when(() => mockStorage.getRating(any())).thenReturn(null);
    when(() => mockStorage.savePriceRecords(any(), any()))
        .thenAnswer((_) async {});

    final result = ServiceResult(
      data: const StationDetail(station: testStation),
      source: ServiceSource.cache,
      fetchedAt: DateTime(2026, 3, 27, 10, 0, 0),
    );

    await pumpApp(
      tester,
      const StationDetailScreen(stationId: stationId),
      overrides: [
        hiveStorageProvider.overrideWithValue(mockStorage),
        priceHistoryRepositoryProvider
            .overrideWithValue(PriceHistoryRepository(mockStorage)),
        stationDetailProvider(stationId).overrideWith((_) async => result),
        favoritesOverride([]),
        isFavoriteOverride(stationId, false),
      ],
    );

    /// Drags the detail list up until [target] is laid out, or gives up.
    Future<void> scrollTo(Finder target) async {
      for (var i = 0; i < 20 && target.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
    }

    // The link only exists once the collapsed price-history card is open.
    await scrollTo(find.text('Price History'));
    await tester.tap(find.text('Price History'));
    await tester.pumpAndSettle();

    final link = find.text('Show all fuel types');
    await scrollTo(link);

    final fab = find.byKey(const Key('station_directions_fab'));
    expect(fab, findsOneWidget);
    expect(link, findsOneWidget);

    final linkRect = tester.getRect(link);
    final fabRect = tester.getRect(fab);
    expect(
      linkRect.overlaps(fabRect),
      isFalse,
      reason: 'The price-history fold link ($linkRect) sits under the '
          'Navigate FAB ($fabRect) — raise the sliver padding so the last '
          'row clears kFabScrollClearance + the bottom inset (#3928).',
    );
  });
}
