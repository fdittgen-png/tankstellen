import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/price_history/data/repositories/price_history_repository.dart';
import 'package:tankstellen/features/price_history/providers/price_history_provider.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
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
      commonOverrides = [
        hiveStorageProvider.overrideWithValue(mockStorage),
        priceHistoryRepositoryProvider.overrideWithValue(
          PriceHistoryRepository(mockStorage),
        ),
      ];
    });

    testWidgets('renders station brand when data is loaded', (tester) async {
      final result = ServiceResult(
        data: StationDetail(station: testStation),
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

      // The brand 'STAR' should be displayed
      expect(find.text('STAR'), findsOneWidget);
    });

    testWidgets('renders price tiles for fuel types', (tester) async {
      final result = ServiceResult(
        data: StationDetail(station: testStation),
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

    testWidgets('shows open status indicator for open station',
        (tester) async {
      final result = ServiceResult(
        data: StationDetail(station: testStation), // isOpen: true
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

      // testStation.isOpen is true, so "Open" text should appear
      expect(find.text('Open'), findsOneWidget);
    });
  });
}
