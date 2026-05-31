// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/search/presentation/screens/ev_station_detail_screen.dart';
import 'package:tankstellen/features/search/presentation/widgets/ev_station_header_card.dart';
import 'package:tankstellen/features/search/presentation/widgets/ev_station_info_cards.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart';

/// Test fixture for a basic EV charging station.
const _testEvStation = ChargingStation(
  id: 'ocm-12345',
  name: 'Supercharger Berlin',
  operator: 'Tesla',
  latitude: 52.52,
  longitude: 13.405,
  dist: 2.3,
  address: 'Alexanderplatz 1',
  postCode: '10178',
  place: 'Berlin',
  connectors: [
    EvConnector(
      id: 'ocm-12345-c1',
      type: ConnectorType.ccs,
      rawType: 'CCS',
      maxPowerKw: 250,
      quantity: 8,
      currentType: 'DC',
      status: ConnectorStatus.available,
      statusLabel: 'Available',
    ),
    EvConnector(
      id: 'ocm-12345-c2',
      type: ConnectorType.type2,
      rawType: 'Type 2',
      maxPowerKw: 22,
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

  /// Structural responsive-layout coverage for the EV detail screen (#2532,
  /// Epic #2525). NO macOS goldens — the adaptive branch is pinned by
  /// finding (or not finding) the two-pane [VerticalDivider] while the SAME
  /// section cards render in both layouts.
  group('EVStationDetailScreen responsive layout (#2532)', () {
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

    Future<void> pumpAt(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpApp(
        tester,
        const EVStationDetailScreen(station: _testEvStation),
        overrides: overrides,
      );
    }

    testWidgets(
      'wide (900x600) renders two panes (a VerticalDivider) with the header '
      'and connector cards both mounted',
      (tester) async {
        await pumpAt(tester, const Size(900, 600));

        // The two-pane layout is identified by its divider.
        expect(find.byType(VerticalDivider), findsOneWidget);

        // BOTH the LEFT-pane header and the RIGHT-pane connector card render
        // simultaneously (the portrait single column also mounts both, but
        // the divider proves the two-pane split is active here).
        expect(find.byType(EVStationHeaderCard), findsOneWidget);
        expect(find.byType(EVConnectorsCard), findsOneWidget);

        // A normal AppBar — there is no expanding SliverAppBar in this screen.
        expect(find.byType(AppBar), findsOneWidget);
      },
    );

    testWidgets(
      'compact (590x900) keeps a single column — no VerticalDivider',
      (tester) async {
        // 590dp is below the 600dp split breakpoint (still compact) yet wide
        // enough that the pre-existing connector-tile Row does not overflow —
        // this test isolates the layout BRANCH, not that widget's intrinsic
        // sizing.
        await pumpAt(tester, const Size(590, 900));

        // No two-pane split on compact.
        expect(find.byType(VerticalDivider), findsNothing);

        // The section cards still render in the single column.
        expect(find.byType(EVStationHeaderCard), findsOneWidget);
        expect(find.byType(EVConnectorsCard), findsOneWidget);
      },
    );
  });
}
