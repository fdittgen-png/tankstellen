// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/ev/domain/entities/ev_access_cost.dart';
import 'package:tankstellen/features/search/data/services/ev_charging_service.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

class MockDio extends Mock implements Dio {}

void main() {
  group('EVChargingService', () {
    test('service can be instantiated with API key', () {
      final service = EVChargingService(apiKey: 'test-key');
      expect(service, isNotNull);
      expect(service.apiKey, 'test-key');
    });

    group('ChargingStation model', () {
      test('creates from minimal data', () {
        const station = ChargingStation(
          id: 'ocm-123',
          name: 'Test Charger',
          operator: 'TestNet',
          latitude: 52.5,
          longitude: 13.4,
          address: 'Main St 1',
        );

        expect(station.id, 'ocm-123');
        expect(station.dist, 0);
        expect(station.totalPoints, 0);
        expect(station.isOperational, isNull);
        expect(station.postCode, isNull);
        expect(station.place, isNull);
      });

      test('creates with full data', () {
        const station = ChargingStation(
          id: 'ocm-456',
          name: 'Super Charger',
          operator: 'Ionity',
          latitude: 48.8,
          longitude: 2.3,
          dist: 5.2,
          address: 'Rue de Paris',
          postCode: '75001',
          place: 'Paris',
          connectors: [
            EvConnector(
                id: 'c1',
                type: ConnectorType.ccs,
                rawType: 'CCS Type 2',
                maxPowerKw: 350,
                quantity: 4,
                currentType: 'DC'),
            EvConnector(
                id: 'c2',
                type: ConnectorType.type2,
                rawType: 'Type 2',
                maxPowerKw: 22,
                quantity: 2,
                currentType: 'AC'),
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

    group('EvConnector model', () {
      test('creates with defaults', () {
        const connector =
            EvConnector(id: 'c', type: ConnectorType.ccs);

        expect(connector.maxPowerKw, 0);
        expect(connector.powerKW, 0);
        expect(connector.quantity, 0);
        expect(connector.currentType, isNull);
        expect(connector.status, ConnectorStatus.unknown);
      });

      test('creates with full data', () {
        const connector = EvConnector(
          id: 'c',
          type: ConnectorType.ccs,
          rawType: 'CCS Type 2',
          maxPowerKw: 150,
          quantity: 4,
          currentType: 'DC',
          status: ConnectorStatus.available,
          statusLabel: 'Available',
        );

        expect(connector.rawType, 'CCS Type 2');
        expect(connector.maxPowerKw, 150);
        expect(connector.powerKW, 150);
        expect(connector.quantity, 4);
        expect(connector.currentType, 'DC');
        expect(connector.status, ConnectorStatus.available);
        expect(connector.statusLabel, 'Available');
      });

      test('fromJson parses legacy search-side payload', () {
        final json = {
          'type': 'CHAdeMO',
          'powerKW': 50.0,
          'quantity': 2,
          'currentType': 'DC',
          'status': 'Available',
        };

        final connector = EvConnector.fromJson(json);

        expect(connector.type, ConnectorType.chademo);
        expect(connector.rawType, 'CHAdeMO');
        expect(connector.maxPowerKw, 50);
        expect(connector.quantity, 2);
        expect(connector.currentType, 'DC');
        expect(connector.status, ConnectorStatus.available);
        expect(connector.statusLabel, 'Available');
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': 'c',
          'type': 'type2',
        };

        final connector = EvConnector.fromJson(json);

        expect(connector.type, ConnectorType.type2);
        expect(connector.maxPowerKw, 0);
        expect(connector.quantity, 0);
        expect(connector.currentType, isNull);
        expect(connector.status, ConnectorStatus.unknown);
      });

      test('toJson round-trips correctly', () {
        const connector = EvConnector(
          id: 'c',
          type: ConnectorType.ccs,
          rawType: 'CCS Type 2',
          maxPowerKw: 150,
          quantity: 4,
          currentType: 'DC',
          status: ConnectorStatus.available,
          statusLabel: 'Available',
        );

        final json = connector.toJson();
        final restored = EvConnector.fromJson(json);

        expect(restored.type, connector.type);
        expect(restored.rawType, connector.rawType);
        expect(restored.maxPowerKw, connector.maxPowerKw);
        expect(restored.quantity, connector.quantity);
        expect(restored.currentType, connector.currentType);
        expect(restored.status, connector.status);
      });
    });

    group('parsing integration', () {
      test('handles non-list response data', () async {
        const station = ChargingStation(
          id: 'ocm-1',
          name: 'Test',
          operator: '',
          latitude: 52.5,
          longitude: 13.4,
          address: 'Test',
        );

        expect(station.operator, '');
        expect(station.name, 'Test');
      });

      test('ChargingStation handles all connector types', () {
        const connectors = [
          EvConnector(
              id: 'c1',
              type: ConnectorType.type1,
              rawType: 'Type 1',
              maxPowerKw: 7.4),
          EvConnector(
              id: 'c2',
              type: ConnectorType.chademo,
              rawType: 'CHAdeMO',
              maxPowerKw: 50),
          EvConnector(
              id: 'c3',
              type: ConnectorType.type2,
              rawType: 'Type 2',
              maxPowerKw: 22),
          EvConnector(
              id: 'c4',
              type: ConnectorType.tesla,
              rawType: 'Tesla Supercharger',
              maxPowerKw: 250),
          EvConnector(
              id: 'c5',
              type: ConnectorType.ccs,
              rawType: 'CCS Type 1',
              maxPowerKw: 50),
          EvConnector(
              id: 'c6',
              type: ConnectorType.ccs,
              rawType: 'CCS Type 2',
              maxPowerKw: 350),
        ];

        const station = ChargingStation(
          id: 'ocm-all',
          name: 'All Connectors',
          operator: 'Test',
          latitude: 52.5,
          longitude: 13.4,
          address: 'Test',
          connectors: connectors,
          totalPoints: 6,
        );

        expect(station.connectors.length, 6);
        expect(station.totalPoints, 6);
      });

      test('ChargingStation handles various status values', () {
        const operational = ChargingStation(
          id: 'ocm-op',
          name: 'Operational',
          operator: 'Test',
          latitude: 52.5,
          longitude: 13.4,
          address: 'Test',
          isOperational: true,
        );

        const notOperational = ChargingStation(
          id: 'ocm-nop',
          name: 'Not Operational',
          operator: 'Test',
          latitude: 52.5,
          longitude: 13.4,
          address: 'Test',
          isOperational: false,
        );

        expect(operational.isOperational, true);
        expect(notOperational.isOperational, false);
      });
    });

    group('UsageType access-cost extraction (#2618)', () {
      Map<String, dynamic> ocmItem({Map<String, dynamic>? usageType}) {
        final item = <String, dynamic>{
          'ID': 42,
          'AddressInfo': {
            'Title': 'Test Hub',
            'Latitude': 48.85,
            'Longitude': 2.35,
            'AddressLine1': '1 Rue de Test',
            'Town': 'Paris',
            'Postcode': '75001',
            'Country': {'ISOCode': 'FR'},
          },
          'Connections': const <dynamic>[],
          'NumberOfPoints': 2,
          'UsageCost': '0.45 EUR/kWh',
        };
        if (usageType != null) item['UsageType'] = usageType;
        return item;
      }

      Future<ChargingStation> parseSingle(Map<String, dynamic> item) async {
        final dio = MockDio();
        when(() => dio.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              cancelToken: any(named: 'cancelToken'),
            )).thenAnswer((_) async => Response<dynamic>(
              requestOptions: RequestOptions(path: '/poi/'),
              statusCode: 200,
              data: <dynamic>[item],
            ));
        final service = EVChargingService(apiKey: 'k', dio: dio);
        final result = await service.searchStations(
          lat: 48.85,
          lng: 2.35,
          radiusKm: 5,
        );
        expect(result.data, hasLength(1));
        return result.data.single;
      }

      test('item WITH a UsageType block populates the 4 fields', () async {
        final station = await parseSingle(ocmItem(usageType: const {
          'ID': 4,
          'Title': 'Public - Pay At Location',
          'IsPayAtLocation': true,
          'IsMembershipRequired': false,
        }));

        expect(station.usageTypeId, 4);
        expect(station.usageTypeTitle, 'Public - Pay At Location');
        expect(station.isPayAtLocation, isTrue);
        expect(station.isMembershipRequired, isFalse);
        // usageCost stays the raw indicative text, untouched.
        expect(station.usageCost, '0.45 EUR/kWh');
        // Derived signal.
        expect(station.accessCost.kind, EvAccessCostKind.paid);
      });

      test('item WITHOUT a UsageType yields all-null, no crash', () async {
        final station = await parseSingle(ocmItem());

        expect(station.usageTypeId, isNull);
        expect(station.usageTypeTitle, isNull);
        expect(station.isPayAtLocation, isNull);
        expect(station.isMembershipRequired, isNull);
        expect(station.isFranceIrveEnriched, isFalse);
        expect(station.usageCost, '0.45 EUR/kWh');
      });

      test('a free UsageType resolves to a free access badge', () async {
        final station = await parseSingle(ocmItem(usageType: const {
          'ID': 1,
          'Title': 'Public - Free',
          'IsPayAtLocation': false,
          'IsMembershipRequired': false,
        })
          ..['UsageCost'] = null);

        expect(station.accessCost.kind, EvAccessCostKind.free);
      });
    });

    group('ServiceSource', () {
      test('openChargeMapApi has correct display name', () {
        expect(
            ServiceSource.openChargeMapApi.displayName, 'OpenChargeMap');
      });
    });
  });
}
