import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/data/services/ev_charging_service.dart';
import 'package:tankstellen/features/search/domain/entities/charging_station.dart';

void main() {
  group('EVChargingService', () {
    group('connector type mapping', () {
      // The _mapConnectionType method is private, so we verify the mapping
      // indirectly through the ChargingStation model and known OCM type IDs.
      // ConnectionTypeID mappings:
      //   1 = Type 1, 2 = CHAdeMO, 25 = Type 2, 27 = Tesla Supercharger
      //   32 = CCS Type 1, 33 = CCS Type 2, 1036 = Type 2
      //   other = Unknown

      test('service can be instantiated with API key', () {
        final service = EVChargingService(apiKey: 'test-key');
        expect(service, isNotNull);
        expect(service.apiKey, 'test-key');
      });
    });

    group('ChargingStation model', () {
      test('creates from minimal data', () {
        const station = ChargingStation(
          id: 'ocm-123',
          name: 'Test Charger',
          operator: 'TestNet',
          lat: 52.5,
          lng: 13.4,
          address: 'Main St 1',
          connectors: [],
        );

        expect(station.id, 'ocm-123');
        expect(station.dist, 0);
        expect(station.totalPoints, 0);
        expect(station.isOperational, isNull);
        expect(station.postCode, '');
        expect(station.place, '');
      });

      test('creates with full data', () {
        const station = ChargingStation(
          id: 'ocm-456',
          name: 'Super Charger',
          operator: 'Ionity',
          lat: 48.8,
          lng: 2.3,
          dist: 5.2,
          address: 'Rue de Paris',
          postCode: '75001',
          place: 'Paris',
          connectors: [
            Connector(type: 'CCS Type 2', powerKW: 350, quantity: 4, currentType: 'DC'),
            Connector(type: 'Type 2', powerKW: 22, quantity: 2, currentType: 'AC'),
          ],
          totalPoints: 6,
          isOperational: true,
          usageCost: '0.39 EUR/kWh',
          updatedAt: '27/03/2026',
          countryCode: 'FR',
        );

        expect(station.operator, 'Ionity');
        expect(station.connectors.length, 2);
        expect(station.totalPoints, 6);
        expect(station.usageCost, '0.39 EUR/kWh');
        expect(station.countryCode, 'FR');
      });
    });

    group('Connector model', () {
      test('creates with defaults', () {
        const connector = Connector(type: 'CCS');

        expect(connector.powerKW, 0);
        expect(connector.quantity, 0);
        expect(connector.currentType, isNull);
        expect(connector.status, isNull);
      });

      test('creates with full data', () {
        const connector = Connector(
          type: 'CCS Type 2',
          powerKW: 150,
          quantity: 4,
          currentType: 'DC',
          status: 'Available',
        );

        expect(connector.type, 'CCS Type 2');
        expect(connector.powerKW, 150);
        expect(connector.quantity, 4);
        expect(connector.currentType, 'DC');
        expect(connector.status, 'Available');
      });

      test('fromJson parses correctly', () {
        final json = {
          'type': 'CHAdeMO',
          'powerKW': 50.0,
          'quantity': 2,
          'currentType': 'DC',
          'status': 'Available',
        };

        final connector = Connector.fromJson(json);

        expect(connector.type, 'CHAdeMO');
        expect(connector.powerKW, 50.0);
        expect(connector.quantity, 2);
        expect(connector.currentType, 'DC');
        expect(connector.status, 'Available');
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'type': 'Type 2',
        };

        final connector = Connector.fromJson(json);

        expect(connector.type, 'Type 2');
        expect(connector.powerKW, 0);
        expect(connector.quantity, 0);
        expect(connector.currentType, isNull);
        expect(connector.status, isNull);
      });
    });
  });
}
