// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/price_history/data/repositories/price_history_repository.dart';
import 'package:tankstellen/features/price_history/providers/price_history_provider.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/station_detail/presentation/screens/station_detail_screen.dart';
import 'package:tankstellen/features/station_detail/presentation/screens/station_detail_wide_layout.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_brand_header.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_prices_section.dart';
import 'package:tankstellen/features/station_detail/providers/station_detail_provider.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

/// Structural responsive-layout coverage for StationDetailScreen (#2531,
/// Epic #2525).
///
/// NO macOS goldens (per the cross-platform-golden rule). Instead this pins
/// the adaptive branch structurally:
///
/// * at a wide width (≥ 600dp) the screen renders the [StationDetailWideLayout]
///   two-pane variant — the brand header AND the prices section render
///   simultaneously, and the AppBar is a NORMAL (non-expanding) one, NOT the
///   196dp `SliverAppBar`.
/// * at a compact width (< 600dp) it keeps the single `CustomScrollView` +
///   `SliverAppBar` path, with no [StationDetailWideLayout].
void main() {
  const stationId = '51d4b477-a095-1aa0-e100-80009459e03a';

  late MockHiveStorage mockStorage;
  late List<Object> overrides;

  setUp(() {
    mockStorage = MockHiveStorage();
    when(() => mockStorage.getPriceRecords(any())).thenReturn([]);
    when(() => mockStorage.getPriceHistoryKeys()).thenReturn([]);
    when(() => mockStorage.getRatings()).thenReturn({});
    when(() => mockStorage.savePriceRecords(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockStorage.getRating(any())).thenReturn(null);

    final result = ServiceResult(
      data: const StationDetail(station: testStation),
      source: ServiceSource.cache,
      fetchedAt: DateTime(2026, 3, 27, 10, 0, 0),
    );
    overrides = [
      hiveStorageProvider.overrideWithValue(mockStorage),
      priceHistoryRepositoryProvider
          .overrideWithValue(PriceHistoryRepository(mockStorage)),
      stationDetailProvider(stationId).overrideWith((_) async => result),
      favoritesOverride([]),
      isFavoriteOverride(stationId, false),
    ];
  });

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpApp(
      tester,
      const StationDetailScreen(stationId: stationId),
      overrides: overrides,
    );
  }

  group('StationDetailScreen responsive layout (#2531)', () {
    testWidgets(
      'wide (900x600) renders both panes + a normal AppBar, no SliverAppBar',
      (tester) async {
        await pumpAt(tester, const Size(900, 600));

        // The two-column variant is mounted.
        expect(find.byType(StationDetailWideLayout), findsOneWidget);

        // BOTH panes render simultaneously — left brand header + right
        // prices section coexist (the portrait sliver collapses one out of
        // view; the two-column layout shows both at once).
        expect(find.byType(StationBrandHeader), findsOneWidget);
        expect(find.byType(StationPricesSection), findsOneWidget);

        // The VerticalDivider between the two panes.
        expect(find.byType(VerticalDivider), findsOneWidget);

        // A NORMAL AppBar (PageScaffold), NOT the 196dp expanding sliver.
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(SliverAppBar), findsNothing);
      },
    );

    testWidgets(
      'compact (400x800) keeps the single CustomScrollView + SliverAppBar',
      (tester) async {
        await pumpAt(tester, const Size(400, 800));

        // No two-column variant on compact.
        expect(find.byType(StationDetailWideLayout), findsNothing);

        // The original sliver layout: a CustomScrollView with a SliverAppBar
        // and no plain AppBar / VerticalDivider.
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.byType(SliverAppBar), findsOneWidget);
        expect(find.byType(VerticalDivider), findsNothing);

        // The body content still renders (brand header + prices section).
        expect(find.byType(StationBrandHeader), findsOneWidget);
        expect(find.byType(StationPricesSection), findsOneWidget);
      },
    );
  });
}
