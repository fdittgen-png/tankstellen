import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/charging_station.dart';

void main() {
  group('ChargingStation', () {
    test('fromJson with full data', () {
      final json = {
        'id': 'ocm-456',
        'name': 'Super Charger',
        'operator': 'Ionity',
        'lat': 48.8,
        'lng': 2.3,
        'dist': 5.2,
        'address': 'Rue de Paris',
        'postCode': '75001',
        'place': 'Paris',
        'connectors': [
          {
            'type': 'CCS Type 2',
            'powerKW': 350.0,
            'quantity': 4,
            'currentType': 'DC',
            'status': 'Available',
          },
          {
            'type': 'Type 2',
            'powerKW': 22.0,
            'quantity': 2,
            'currentType': 'AC',
          },
        ],
        'totalPoints': 6,
        'isOperational': true,
        'usageCost': '0.39 EUR/kWh',
        'updatedAt': '27/03/2026',
        'countryCode': 'FR',
      };

      final station = ChargingStation.fromJson(json);

      expect(station.id, 'ocm-456');
      expect(station.name, 'Super Charger');
      expect(station.operator, 'Ionity');
      expect(station.lat, 48.8);
      expect(station.lng, 2.3);
      expect(station.dist, 5.2);
      expect(station.address, 'Rue de Paris');
      expect(station.postCode, '75001');
      expect(station.place, 'Paris');
      expect(station.connectors.length, 2);
      expect(station.totalPoints, 6);
      expect(station.isOperational, true);
      expect(station.usageCost, '0.39 EUR/kWh');
      expect(station.updatedAt, '27/03/2026');
      expect(station.countryCode, 'FR');
    });

    test('fromJson with minimal data (missing optional fields)', () {
      final json = {
        'id': 'ocm-100',
        'name': 'Minimal Charger',
        'operator': 'TestOp',
        'lat': 50.0,
        'lng': 8.0,
        'address': 'Main St',
        'connectors': <Map<String, dynamic>>[],
      };

      final station = ChargingStation.fromJson(json);

      expect(station.id, 'ocm-100');
      expect(station.name, 'Minimal Charger');
      expect(station.dist, 0);
      expect(station.postCode, '');
      expect(station.place, '');
      expect(station.totalPoints, 0);
      expect(station.isOperational, isNull);
      expect(station.usageCost, isNull);
      expect(station.updatedAt, isNull);
      expect(station.countryCode, isNull);
      expect(station.connectors, isEmpty);
    });

    test('copyWith works', () {
      const station = ChargingStation(
        id: 'ocm-1',
        name: 'Original',
        operator: 'Op',
        lat: 50.0,
        lng: 8.0,
        address: 'Addr',
        connectors: [],
      );

      final updated = station.copyWith(
        name: 'Updated',
        dist: 3.5,
        totalPoints: 4,
      );

      expect(updated.name, 'Updated');
      expect(updated.dist, 3.5);
      expect(updated.totalPoints, 4);
      // Unchanged fields remain the same
      expect(updated.id, 'ocm-1');
      expect(updated.operator, 'Op');
      expect(updated.lat, 50.0);
    });

    test('default values (dist=0, totalPoints=0, connectors=[])', () {
      const station = ChargingStation(
        id: 'ocm-99',
        name: 'Defaults',
        operator: 'Op',
        lat: 48.0,
        lng: 2.0,
        address: 'Street',
        connectors: [],
      );

      expect(station.dist, 0);
      expect(station.totalPoints, 0);
      expect(station.connectors, isEmpty);
      expect(station.postCode, '');
      expect(station.place, '');
    });

    test('equality works for identical data', () {
      const a = ChargingStation(
        id: 'ocm-1',
        name: 'A',
        operator: 'Op',
        lat: 50.0,
        lng: 8.0,
        address: 'Addr',
        connectors: [],
      );
      const b = ChargingStation(
        id: 'ocm-1',
        name: 'A',
        operator: 'Op',
        lat: 50.0,
        lng: 8.0,
        address: 'Addr',
        connectors: [],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('Connector', () {
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

    test('creates with defaults', () {
      const connector = Connector(type: 'CCS');

      expect(connector.type, 'CCS');
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

    test('equality works', () {
      const a = Connector(type: 'Type 2', powerKW: 22, quantity: 1);
      const b = Connector(type: 'Type 2', powerKW: 22, quantity: 1);

      expect(a, equals(b));
    });
  });
}
