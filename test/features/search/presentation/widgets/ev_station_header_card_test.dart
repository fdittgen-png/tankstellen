import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/charging_station.dart';
import 'package:tankstellen/features/search/presentation/widgets/ev_station_header_card.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  const station = ChargingStation(
    id: 'ocm-123',
    name: 'Test Charging Hub',
    operator: 'ChargePoint',
    address: '123 Test St',
    postCode: '12345',
    place: 'Test City',
    lat: 48.5,
    lng: 2.3,
    dist: 1.5,
    totalPoints: 4,
    connectors: [],
  );

  group('EVStationHeaderCard', () {
    testWidgets('renders station name and operator', (tester) async {
      await pumpApp(
        tester,
        const EVStationHeaderCard(
          station: station,
          evColor: Colors.green,
        ),
      );

      expect(find.text('Test Charging Hub'), findsOneWidget);
      expect(find.text('ChargePoint'), findsOneWidget);
    });

    testWidgets('shows status unknown for null operational', (tester) async {
      await pumpApp(
        tester,
        const EVStationHeaderCard(
          station: station,
          evColor: Colors.green,
        ),
      );

      expect(find.text('Status unknown'), findsOneWidget);
    });

    testWidgets('shows Operational for operational station', (tester) async {
      const opStation = ChargingStation(
        id: 'ocm-456',
        name: 'Operational Station',
        operator: 'Operator',
        address: '456 St',
        postCode: '00000',
        place: 'Place',
        lat: 48.0,
        lng: 2.0,
        dist: 1.0,
        totalPoints: 1,
        connectors: [],
        isOperational: true,
      );

      await pumpApp(
        tester,
        const EVStationHeaderCard(
          station: opStation,
          evColor: Colors.green,
        ),
      );

      expect(find.text('Operational'), findsOneWidget);
    });
  });
}
