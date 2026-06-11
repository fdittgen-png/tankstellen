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
import 'package:tankstellen/features/station_detail/providers/station_detail_provider.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

void main() {
  group('StationDetailScreen', () {
    late MockHiveStorage mockStorage;
    late List<Object> commonOverrides;

    setUp(() {
      mockStorage = MockHiveStorage();
      when(() => mockStorage.getPriceRecords(any())).thenReturn([]);
      when(() => mockStorage.getPriceHistoryKeys()).thenReturn([]);
      when(() => mockStorage.getRatings()).thenReturn({});
      when(() => mockStorage.savePriceRecords(any(), any())).thenAnswer((_) async {});
      when(() => mockStorage.getRating(any())).thenReturn(null);
      commonOverrides = [
        hiveStorageProvider.overrideWithValue(mockStorage),
        priceHistoryRepositoryProvider.overrideWithValue(
          PriceHistoryRepository(mockStorage),
        ),
      ];
    });

    testWidgets('renders station brand when data is loaded', (tester) async {
      final result = ServiceResult(
        data: const StationDetail(station: testStation),
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );

      await pumpApp(
        tester,
        const StationDetailScreen(
          stationId: '51d4b477-a095-1aa0-e100-80009459e03a',
        ),
        overrides: [
          ...commonOverrides,
          stationDetailProvider('51d4b477-a095-1aa0-e100-80009459e03a')
              .overrideWith((_) async => result),
          favoritesOverride([]),
          isFavoriteOverride(
              '51d4b477-a095-1aa0-e100-80009459e03a', false),
        ],
      );

      // #2161 — the AppBar title slot no longer carries the brand, so
      // 'STAR' renders exactly once, in the body brand-header block.
      expect(find.text('STAR'), findsOneWidget);
    });

    testWidgets('renders price tiles for fuel types', (tester) async {
      final result = ServiceResult(
        data: const StationDetail(station: testStation),
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );

      await pumpApp(
        tester,
        const StationDetailScreen(
          stationId: '51d4b477-a095-1aa0-e100-80009459e03a',
        ),
        overrides: [
          ...commonOverrides,
          stationDetailProvider('51d4b477-a095-1aa0-e100-80009459e03a')
              .overrideWith((_) async => result),
          favoritesOverride([]),
          isFavoriteOverride(
              '51d4b477-a095-1aa0-e100-80009459e03a', false),
        ],
      );

      // Price tile labels should be present
      expect(find.text('Super E5'), findsOneWidget);
      expect(find.text('Super E10'), findsOneWidget);
      expect(find.text('Diesel'), findsOneWidget);
    });

    testWidgets('shows open status with freshness inline',
        (tester) async {
      final result = ServiceResult(
        data: const StationDetail(station: testStation), // isOpen: true
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );

      await pumpApp(
        tester,
        const StationDetailScreen(
          stationId: '51d4b477-a095-1aa0-e100-80009459e03a',
        ),
        overrides: [
          ...commonOverrides,
          stationDetailProvider('51d4b477-a095-1aa0-e100-80009459e03a')
              .overrideWith((_) async => result),
          favoritesOverride([]),
          isFavoriteOverride(
              '51d4b477-a095-1aa0-e100-80009459e03a', false),
        ],
      );

      // Status text should contain "Open" combined with freshness
      // e.g. "Open — < 1 min ago"
      expect(find.textContaining('Open'), findsAtLeast(1));
      expect(find.textContaining('ago'), findsAtLeast(1));
    });

    testWidgets('does not render separate FreshnessBadge widget',
        (tester) async {
      final result = ServiceResult(
        data: const StationDetail(station: testStation),
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );

      await pumpApp(
        tester,
        const StationDetailScreen(
          stationId: '51d4b477-a095-1aa0-e100-80009459e03a',
        ),
        overrides: [
          ...commonOverrides,
          stationDetailProvider('51d4b477-a095-1aa0-e100-80009459e03a')
              .overrideWith((_) async => result),
          favoritesOverride([]),
          isFavoriteOverride(
              '51d4b477-a095-1aa0-e100-80009459e03a', false),
        ],
      );

      // FreshnessBadge widget should no longer be used
      // (freshness is inline in status text now)
      expect(
        find.byWidgetPredicate((w) => w.runtimeType.toString() == 'FreshnessBadge'),
        findsNothing,
      );
    });

    testWidgets('shows rating stars when station has a rating',
        (tester) async {
      when(() => mockStorage.getRating(any())).thenReturn(4);
      when(() => mockStorage.getRatings())
          .thenReturn({'51d4b477-a095-1aa0-e100-80009459e03a': 4});

      final result = ServiceResult(
        data: const StationDetail(station: testStation),
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );

      await pumpApp(
        tester,
        const StationDetailScreen(
          stationId: '51d4b477-a095-1aa0-e100-80009459e03a',
        ),
        overrides: [
          ...commonOverrides,
          stationDetailProvider('51d4b477-a095-1aa0-e100-80009459e03a')
              .overrideWith((_) async => result),
          favoritesOverride([]),
          isFavoriteOverride(
              '51d4b477-a095-1aa0-e100-80009459e03a', false),
        ],
      );

      // Compact star icons should be in the top-right area
      // (16px stars from the inline Consumer)
      expect(find.byIcon(Icons.star), findsWidgets);
    });

    testWidgets('renders favorite button in app bar (not favorited)',
        (tester) async {
      final result = ServiceResult(
        data: const StationDetail(station: testStation),
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );

      await pumpApp(
        tester,
        const StationDetailScreen(
          stationId: '51d4b477-a095-1aa0-e100-80009459e03a',
        ),
        overrides: [
          ...commonOverrides,
          stationDetailProvider('51d4b477-a095-1aa0-e100-80009459e03a')
              .overrideWith((_) async => result),
          favoritesOverride([]),
          isFavoriteOverride(
              '51d4b477-a095-1aa0-e100-80009459e03a', false),
        ],
      );

      // Star icon should be present in the app bar actions
      expect(find.byIcon(Icons.star_border).evaluate().isNotEmpty ||
             find.byIcon(Icons.star).evaluate().isNotEmpty, isTrue);
    });

    testWidgets('renders favorite button as filled when station is favorited',
        (tester) async {
      final result = ServiceResult(
        data: const StationDetail(station: testStation),
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );

      await pumpApp(
        tester,
        const StationDetailScreen(
          stationId: '51d4b477-a095-1aa0-e100-80009459e03a',
        ),
        overrides: [
          ...commonOverrides,
          stationDetailProvider('51d4b477-a095-1aa0-e100-80009459e03a')
              .overrideWith((_) async => result),
          favoritesOverride(['51d4b477-a095-1aa0-e100-80009459e03a']),
          isFavoriteOverride(
              '51d4b477-a095-1aa0-e100-80009459e03a', true),
        ],
      );

      // Should have filled star (favorited)
      expect(find.byIcon(Icons.star), findsWidgets);
    });

    testWidgets(
        '#2161: app bar has NO station-name Hero and NO cheapest-price chip — '
        'just back arrow + actions',
        (tester) async {
      final result = ServiceResult(
        data: const StationDetail(station: testStation),
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );

      await pumpApp(
        tester,
        const StationDetailScreen(
          stationId: '51d4b477-a095-1aa0-e100-80009459e03a',
        ),
        overrides: [
          ...commonOverrides,
          stationDetailProvider('51d4b477-a095-1aa0-e100-80009459e03a')
              .overrideWith((_) async => result),
          favoritesOverride([]),
          isFavoriteOverride(
              '51d4b477-a095-1aa0-e100-80009459e03a', false),
        ],
      );

      // No Hero with the station-name tag — the title fly-in is gone
      // (#595 reversed by #2161). Other Heroes on the screen (e.g. FAB)
      // are unaffected, so we just check that none carry the
      // station-name-* tag.
      final heroes = find.byType(Hero);
      final matching = heroes.evaluate().where((element) {
        final widget = element.widget as Hero;
        return widget.tag.toString().startsWith('station-name-');
      });
      expect(matching, isEmpty,
          reason: 'detail screen must NOT carry a station-name Hero '
              '(#2161 — animation removed)');
    });

    testWidgets(
        'address surfaces through the AppBar header, not a duplicate '
        'body section (#1996)', (tester) async {
      final result = ServiceResult(
        data: const StationDetail(station: testStation),
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );

      await pumpApp(
        tester,
        const StationDetailScreen(
          stationId: '51d4b477-a095-1aa0-e100-80009459e03a',
        ),
        overrides: [
          ...commonOverrides,
          stationDetailProvider('51d4b477-a095-1aa0-e100-80009459e03a')
              .overrideWith((_) async => result),
          favoritesOverride([]),
          isFavoriteOverride(
              '51d4b477-a095-1aa0-e100-80009459e03a', false),
        ],
      );

      // The dedicated "Address" body block is gone (#1996 compaction);
      // the street + place still reach the user via the brand-header
      // inside the sliver app bar, so we just check that some piece of
      // the address survives somewhere on screen.
      expect(find.text('Address'), findsNothing,
          reason: 'duplicate Address heading must be gone after #1996');
      expect(find.textContaining('Berlin'), findsAtLeast(1),
          reason: 'street/place still reach the user via the AppBar');
    });
  });
}
