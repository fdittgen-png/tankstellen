import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/price_history/data/repositories/price_history_repository.dart';
import 'package:tankstellen/features/price_history/presentation/screens/price_history_screen.dart';
import 'package:tankstellen/features/price_history/providers/price_history_provider.dart';

import '../../../../fakes/fake_hive_storage.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('PriceHistoryScreen', () {
    late FakeHiveStorage fakeStorage;
    late List<Object> commonOverrides;

    setUp(() {
      fakeStorage = FakeHiveStorage();
      commonOverrides = [
        hiveStorageProvider.overrideWithValue(fakeStorage),
        priceHistoryRepositoryProvider.overrideWithValue(
          PriceHistoryRepository(fakeStorage),
        ),
      ];
    });

    testWidgets('renders Scaffold with Price History title', (tester) async {
      await pumpApp(
        tester,
        const PriceHistoryScreen(stationId: 'test-station-1'),
        overrides: commonOverrides,
      );

      expect(find.byType(Scaffold), findsAtLeast(1));
      expect(find.text('Price History'), findsOneWidget);
    });

    testWidgets('shows empty state when no history exists', (tester) async {
      await pumpApp(
        tester,
        const PriceHistoryScreen(stationId: 'test-station-1'),
        overrides: commonOverrides,
      );

      expect(find.text('No price history yet'), findsOneWidget);
    });

    testWidgets('renders back button in app bar', (tester) async {
      await pumpApp(
        tester,
        const PriceHistoryScreen(stationId: 'test-station-1'),
        overrides: commonOverrides,
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
