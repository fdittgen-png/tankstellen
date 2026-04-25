import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/widgets/shimmer_placeholder.dart';
import 'package:tankstellen/features/price_history/data/repositories/price_history_repository.dart';
import 'package:tankstellen/features/price_history/providers/price_history_provider.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/price_history_section.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_detail_inline.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_info_section.dart';
import 'package:tankstellen/features/station_detail/providers/station_detail_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

void main() {
  group('StationDetailInline', () {
    const stationId = '51d4b477-a095-1aa0-e100-80009459e03a';
    late MockHiveStorage mockStorage;
    late List<Object> commonOverrides;

    setUp(() {
      mockStorage = MockHiveStorage();
      when(() => mockStorage.getPriceRecords(any())).thenReturn([]);
      when(() => mockStorage.getPriceHistoryKeys()).thenReturn([]);
      when(() => mockStorage.getRatings()).thenReturn({});
      when(() => mockStorage.savePriceRecords(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockStorage.getRating(any())).thenReturn(null);
      commonOverrides = [
        hiveStorageProvider.overrideWithValue(mockStorage),
        priceHistoryRepositoryProvider.overrideWithValue(
          PriceHistoryRepository(mockStorage),
        ),
      ];
    });

    testWidgets('renders ShimmerStationDetail while data is loading',
        (tester) async {
      // Override with a never-completing future so the AsyncValue stays
      // in the loading state. We pump WITHOUT pumpAndSettle because the
      // shimmer widget is a continuously-running animation.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...commonOverrides,
            stationDetailProvider(stationId).overrideWith(
              (_) => Completer<ServiceResult<StationDetail>>().future,
            ),
            favoritesOverride([]),
            isFavoriteOverride(stationId, false),
          ].cast(),
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: StationDetailInline(stationId: stationId),
            ),
          ),
        ),
      );

      // First non-settled frame shows the shimmer placeholder.
      await tester.pump();
      expect(find.byType(ShimmerStationDetail), findsOneWidget);
    });

    testWidgets('renders centered error text when provider throws',
        (tester) async {
      await pumpApp(
        tester,
        const StationDetailInline(stationId: stationId),
        overrides: [
          ...commonOverrides,
          stationDetailProvider(stationId)
              .overrideWith((_) async => throw Exception('boom')),
          favoritesOverride([]),
          isFavoriteOverride(stationId, false),
        ],
      );

      // Error text contains the exception message and lives in a Center.
      expect(find.textContaining('boom'), findsOneWidget);
      expect(find.byType(Center), findsWidgets);
    });

    testWidgets(
        'data state shows brand in toolbar and mounts info + history sections',
        (tester) async {
      final result = ServiceResult(
        data: const StationDetail(station: testStation),
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );

      await pumpApp(
        tester,
        const StationDetailInline(stationId: stationId),
        overrides: [
          ...commonOverrides,
          stationDetailProvider(stationId).overrideWith((_) async => result),
          favoritesOverride([]),
          isFavoriteOverride(stationId, false),
        ],
      );

      // Brand 'STAR' rendered in the mini toolbar header.
      expect(find.text('STAR'), findsAtLeast(1));
      // Both sub-sections are mounted in the data branch.
      expect(find.byType(StationInfoSection), findsOneWidget);
      expect(find.byType(PriceHistorySection), findsOneWidget);
    });

    testWidgets('does not render close IconButton when onClose is null',
        (tester) async {
      final result = ServiceResult(
        data: const StationDetail(station: testStation),
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );

      await pumpApp(
        tester,
        const StationDetailInline(stationId: stationId),
        overrides: [
          ...commonOverrides,
          stationDetailProvider(stationId).overrideWith((_) async => result),
          favoritesOverride([]),
          isFavoriteOverride(stationId, false),
        ],
      );

      // No close icon is rendered when onClose is omitted.
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets(
        'renders close IconButton with tooltip when onClose is provided',
        (tester) async {
      final result = ServiceResult(
        data: const StationDetail(station: testStation),
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );

      await pumpApp(
        tester,
        StationDetailInline(stationId: stationId, onClose: () {}),
        overrides: [
          ...commonOverrides,
          stationDetailProvider(stationId).overrideWith((_) async => result),
          favoritesOverride([]),
          isFavoriteOverride(stationId, false),
        ],
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      // Tooltip widget carries the localized 'Close' message.
      expect(
        find.byTooltip('Close'),
        findsOneWidget,
      );
    });

    testWidgets('tapping close IconButton invokes onClose callback',
        (tester) async {
      final result = ServiceResult(
        data: const StationDetail(station: testStation),
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );

      var tapped = 0;
      await pumpApp(
        tester,
        StationDetailInline(
          stationId: stationId,
          onClose: () => tapped++,
        ),
        overrides: [
          ...commonOverrides,
          stationDetailProvider(stationId).overrideWith((_) async => result),
          favoritesOverride([]),
          isFavoriteOverride(stationId, false),
        ],
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(tapped, 1);
    });
  });
}
