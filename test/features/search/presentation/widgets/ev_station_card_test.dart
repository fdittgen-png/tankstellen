// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/fuel_colors.dart';
import 'package:tankstellen/core/widgets/station_card_shell.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/presentation/widgets/ev_station_card.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

import '../../../../helpers/pump_app.dart';

void main() {
  const testStation = ChargingStation(
    id: 'ocm-123',
    name: 'Test Charger',
    operator: 'Ionity',
    latitude: 52.5,
    longitude: 13.4,
    dist: 3.5,
    address: 'Hauptstr. 10',
    postCode: '10115',
    place: 'Berlin',
    connectors: [
      EvConnector(
        id: 'c1',
        type: ConnectorType.ccs,
        rawType: 'CCS Type 2',
        maxPowerKw: 350,
        quantity: 4,
        currentType: 'DC',
      ),
      EvConnector(
        id: 'c2',
        type: ConnectorType.type2,
        rawType: 'Type 2',
        maxPowerKw: 22,
        quantity: 2,
        currentType: 'AC',
      ),
    ],
    totalPoints: 6,
    isOperational: true,
    usageCost: '0.39 EUR/kWh',
  );

  group('EVStationCard', () {
    testWidgets('renders operator name', (tester) async {
      await pumpApp(
        tester,
        const EVStationCard(result: EVStationResult(testStation)),
      );

      expect(find.text('Ionity'), findsOneWidget);
    });

    testWidgets('renders address', (tester) async {
      await pumpApp(
        tester,
        const EVStationCard(result: EVStationResult(testStation)),
      );

      expect(find.textContaining('Hauptstr'), findsOneWidget);
    });

    testWidgets('renders max power in kW', (tester) async {
      await pumpApp(
        tester,
        const EVStationCard(result: EVStationResult(testStation)),
      );

      expect(find.text('350 kW'), findsOneWidget);
    });

    testWidgets('renders connector type chips', (tester) async {
      await pumpApp(
        tester,
        const EVStationCard(result: EVStationResult(testStation)),
      );

      expect(find.text('CCS Type 2'), findsOneWidget);
      expect(find.text('Type 2'), findsOneWidget);
    });

    testWidgets('renders usage cost', (tester) async {
      await pumpApp(
        tester,
        const EVStationCard(result: EVStationResult(testStation)),
      );

      expect(find.textContaining('0.39'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await pumpApp(
        tester,
        EVStationCard(
          result: const EVStationResult(testStation),
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(EVStationCard));
      expect(tapped, true);
    });

    testWidgets('renders EV station icon', (tester) async {
      await pumpApp(
        tester,
        const EVStationCard(result: EVStationResult(testStation)),
      );

      expect(find.byIcon(Icons.ev_station), findsOneWidget);
    });

    testWidgets('shows station name when operator is empty', (tester) async {
      final noOperator = testStation.copyWith(operator: '');
      await pumpApp(tester, EVStationCard(result: EVStationResult(noOperator)));

      expect(find.text('Test Charger'), findsOneWidget);
    });

    testWidgets('shows -- when no connectors', (tester) async {
      final noConnectors = testStation.copyWith(connectors: const []);
      await pumpApp(
        tester,
        EVStationCard(result: EVStationResult(noConnectors)),
      );

      expect(find.text('--'), findsOneWidget);
    });

    group('favourite star (#1896)', () {
      testWidgets('no star when onFavoriteTap is null', (tester) async {
        await pumpApp(
          tester,
          const EVStationCard(result: EVStationResult(testStation)),
        );
        expect(find.byIcon(Icons.star), findsNothing);
        expect(find.byIcon(Icons.star_border), findsNothing);
      });

      testWidgets('outlined star when not favourited; tap fires the callback', (
        tester,
      ) async {
        var tapped = 0;
        await pumpApp(
          tester,
          EVStationCard(
            result: const EVStationResult(testStation),
            onFavoriteTap: () => tapped++,
          ),
        );
        expect(find.byIcon(Icons.star_border), findsOneWidget);
        expect(find.byIcon(Icons.star), findsNothing);

        await tester.tap(find.byIcon(Icons.star_border));
        expect(tapped, 1);
      });

      testWidgets('filled star when favourited', (tester) async {
        await pumpApp(
          tester,
          EVStationCard(
            result: const EVStationResult(testStation),
            isFavorite: true,
            onFavoriteTap: () {},
          ),
        );
        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.byIcon(Icons.star_border), findsNothing);
      });
    });

    group('StationCardShell composition (#2493)', () {
      testWidgets('built from the shared shell with the evAccent stripe', (
        tester,
      ) async {
        await pumpApp(
          tester,
          const EVStationCard(result: EVStationResult(testStation)),
        );
        final shell = tester.widget<StationCardShell>(
          find.byType(StationCardShell),
        );
        // #2493 — single canonical EV accent (no teal `#009688` /
        // `FuelType.electric` stripe divergence).
        expect(shell.stripeColor, FuelColors.evAccent);
      });
    });
  });
}
