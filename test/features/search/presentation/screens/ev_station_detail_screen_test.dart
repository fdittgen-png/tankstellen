import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/search/domain/entities/charging_station.dart';
import 'package:tankstellen/features/search/presentation/screens/ev_station_detail_screen.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

/// Test fixture for a basic EV charging station.
const _testEvStation = ChargingStation(
  id: 'ocm-12345',
  name: 'Supercharger Berlin',
  operator: 'Tesla',
  lat: 52.52,
  lng: 13.405,
  dist: 2.3,
  address: 'Alexanderplatz 1',
  postCode: '10178',
  place: 'Berlin',
  connectors: [
    Connector(
      type: 'CCS',
      powerKW: 250,
      quantity: 8,
      currentType: 'DC',
      status: 'Available',
    ),
    Connector(
      type: 'Type 2',
      powerKW: 22,
      quantity: 4,
      currentType: 'AC',
    ),
  ],
  totalPoints: 12,
  isOperational: true,
  usageCost: '0.39 EUR/kWh',
);

void main() {
  group('EVStationDetailScreen', () {
    late MockHiveStorage mockStorage;
    late List<Object> overrides;

    setUp(() {
      mockStorage = MockHiveStorage();
      when(() => mockStorage.hasApiKey()).thenReturn(false);
      when(() => mockStorage.getFavoriteIds()).thenReturn([]);
      when(() => mockStorage.getRatings()).thenReturn({});
      when(() => mockStorage.getRating(any())).thenReturn(null);
      when(() => mockStorage.getEvApiKey()).thenReturn(null);

      overrides = [
        hiveStorageProvider.overrideWithValue(mockStorage),
        favoritesOverride([]),
        isFavoriteOverride('ocm-12345', false),
      ];
    });

    testWidgets('renders Scaffold with operator in app bar', (tester) async {
      await pumpApp(
        tester,
        const EVStationDetailScreen(station: _testEvStation),
        overrides: overrides,
      );

      expect(find.byType(Scaffold), findsAtLeast(1));
      // App bar title shows operator when non-empty
      expect(find.text('Tesla'), findsAtLeast(1));
    });

    testWidgets('renders station name and address', (tester) async {
      await pumpApp(
        tester,
        const EVStationDetailScreen(station: _testEvStation),
        overrides: overrides,
      );

      expect(find.text('Supercharger Berlin'), findsOneWidget);
      expect(find.text('Alexanderplatz 1'), findsOneWidget);
    });

    testWidgets('renders connector information', (tester) async {
      await pumpApp(
        tester,
        const EVStationDetailScreen(station: _testEvStation),
        overrides: overrides,
      );

      expect(find.text('CCS'), findsOneWidget);
      expect(find.text('Type 2'), findsOneWidget);
      expect(find.text('250 kW'), findsOneWidget);
    });

    testWidgets('shows operational status', (tester) async {
      await pumpApp(
        tester,
        const EVStationDetailScreen(station: _testEvStation),
        overrides: overrides,
      );

      expect(find.text('Operational'), findsOneWidget);
    });

    testWidgets('shows usage cost when available', (tester) async {
      await pumpApp(
        tester,
        const EVStationDetailScreen(station: _testEvStation),
        overrides: overrides,
      );

      expect(find.text('0.39 EUR/kWh'), findsOneWidget);
    });
  });
}
