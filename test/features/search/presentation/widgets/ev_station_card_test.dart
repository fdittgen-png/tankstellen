import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/charging_station.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/presentation/widgets/ev_station_card.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  const testStation = ChargingStation(
    id: 'ocm-123',
    name: 'Test Charger',
    operator: 'Ionity',
    lat: 52.5,
    lng: 13.4,
    dist: 3.5,
    address: 'Hauptstr. 10',
    postCode: '10115',
    place: 'Berlin',
    connectors: [
      Connector(type: 'CCS Type 2', powerKW: 350, quantity: 4, currentType: 'DC'),
      Connector(type: 'Type 2', powerKW: 22, quantity: 2, currentType: 'AC'),
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
      await pumpApp(
        tester,
        EVStationCard(result: EVStationResult(noOperator)),
      );

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
  });
}
