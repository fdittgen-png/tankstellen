// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/price_history/data/repositories/price_history_repository.dart';
import 'package:tankstellen/features/price_history/providers/price_history_provider.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/station_detail/presentation/screens/station_detail_screen.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_brand_header.dart';
import 'package:tankstellen/features/station_detail/providers/station_detail_provider.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

/// Structural layout coverage for StationDetailScreen (#2161 / #2352).
///
/// HONEST NOTE: #2352 asked for a *golden* of this screen. The brand
/// header renders a `CachedNetworkImage` (`BrandLogo`), whose cache
/// manager calls `path_provider.getTemporaryDirectory` and a network
/// fetch — neither resolves reliably headless, and the logo would golden
/// as a non-deterministic placeholder. Per the issue's fallback clause
/// ("if goldens can't render reliably headless, fall back to structural
/// widget tests + note it honestly"), this pins the post-#2161 layout
/// structurally instead: brand header present, NO AppBar-title Hero, the
/// three fuel price-tile labels, and the inline open+freshness status —
/// the exact surface #2161 regressed. The two surfaces that DO render
/// cleanly headless (the approach PiP overlay and the onboarding step)
/// keep real pixel goldens under `test/goldens/`.
void main() {
  const stationId = '51d4b477-a095-1aa0-e100-80009459e03a';

  group('StationDetailScreen structure (#2161 / #2352)', () {
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

    testWidgets('renders the brand header, price tiles, and inline status',
        (tester) async {
      await pumpApp(
        tester,
        const StationDetailScreen(stationId: stationId),
        overrides: overrides,
      );

      // Brand header block is the canonical surface — its presence + the
      // brand text in exactly one place is what #2161 changed (the brand
      // left the AppBar title slot and lives only in the body header).
      expect(find.byType(StationBrandHeader), findsOneWidget);
      expect(find.text('STAR'), findsOneWidget,
          reason: '#2161 — brand renders once, in the body header, not '
              'also in an AppBar title slot');

      // The three fuel price tiles.
      expect(find.text('Super E5'), findsOneWidget);
      expect(find.text('Super E10'), findsOneWidget);
      expect(find.text('Diesel'), findsOneWidget);

      // Inline open + freshness status (the FreshnessBadge was folded in).
      expect(find.textContaining('Open'), findsAtLeast(1));
      expect(find.textContaining('ago'), findsAtLeast(1));
    });

    testWidgets('#2161 — no station-name Hero in the AppBar', (tester) async {
      await pumpApp(
        tester,
        const StationDetailScreen(stationId: stationId),
        overrides: overrides,
      );

      final stationNameHeroes = find.byType(Hero).evaluate().where((element) {
        final hero = element.widget as Hero;
        return hero.tag.toString().startsWith('station-name-');
      });
      expect(stationNameHeroes, isEmpty,
          reason: 'the title fly-in Hero was removed in #2161 — a regression '
              'that re-adds it must trip here');
    });
  });
}
