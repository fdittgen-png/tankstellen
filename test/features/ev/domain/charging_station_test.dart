import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/ev/domain/entities/opening_hours.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

/// Canonical tests for [ChargingStation] after the #560 consolidation.
///
/// Post-#560, a single `ChargingStation` lives at
/// `lib/features/ev/domain/entities/charging_station.dart`. The tests
/// below pin down:
///   1. [fromJson] accepts BOTH `lat`/`lng` AND `latitude`/`longitude`
///      (TDD for #567 — the "fromJson handles both shapes" checkbox).
///   2. [toJson] always produces the canonical `latitude`/`longitude`.
///   3. Round-trip preserves all fields.
///   4. The free-form search-side `Connector` shape (string `type`,
///      string `status`, `powerKW`) is accepted by
///      [EvConnector.fromJson] and normalised into typed enums.
void main() {
  group('ChargingStation entity', () {
    ChargingStation sample() => ChargingStation(
          id: 'station-1',
          name: 'Ionity Strasbourg',
          operator: 'Ionity',
          latitude: 48.5734,
          longitude: 7.7521,
          address: '67000 Strasbourg, France',
          connectors: const [
            EvConnector(
              id: 'c1',
              type: ConnectorType.ccs,
              maxPowerKw: 350,
              status: ConnectorStatus.available,
              tariffId: 'tariff-1',
            ),
            EvConnector(
              id: 'c2',
              type: ConnectorType.type2,
              maxPowerKw: 22,
              status: ConnectorStatus.occupied,
            ),
          ],
          amenities: const ['restroom', 'cafe'],
          openingHours: const OpeningHours(twentyFourSeven: true),
          lastUpdate: DateTime.utc(2026, 4, 8, 10, 0),
        );

    test('JSON round-trip preserves every field', () {
      final original = sample();
      final json = original.toJson();
      final restored = ChargingStation.fromJson(json);
      expect(restored, original);
    });

    test('hasAvailableConnector reflects connector status', () {
      expect(sample().hasAvailableConnector, isTrue);
      final none = sample().copyWith(
        connectors: const [
          EvConnector(
            id: 'c',
            type: ConnectorType.ccs,
            maxPowerKw: 50,
            status: ConnectorStatus.outOfOrder,
          ),
        ],
      );
      expect(none.hasAvailableConnector, isFalse);
    });

    test('maxPowerKw returns the highest connector rating', () {
      expect(sample().maxPowerKw, 350);
    });

    test('maxPowerKw returns 0 for empty connectors', () {
      final empty = sample().copyWith(connectors: const []);
      expect(empty.maxPowerKw, 0);
    });

    test('openingHours with regular hours round-trips', () {
      const hours = OpeningHours(
        regularHours: [
          RegularHours(
            weekday: 1,
            periodBegin: '06:00',
            periodEnd: '22:00',
          ),
          RegularHours(
            weekday: 7,
            periodBegin: '08:00',
            periodEnd: '20:00',
          ),
        ],
      );
      final restored = OpeningHours.fromJson(hours.toJson());
      expect(restored, hours);
    });

    test('lat/lng getters alias latitude/longitude', () {
      const s = ChargingStation(
        id: 'x',
        name: 'X',
        latitude: 48.1,
        longitude: 2.5,
      );
      expect(s.lat, 48.1);
      expect(s.lng, 2.5);
    });
  });

  group('ChargingStation.fromJson accepts both key shapes (#567)', () {
    test('fromJson accepts canonical latitude/longitude keys', () {
      final json = {
        'id': 'ocm-1',
        'name': 'Canonical',
        'latitude': 48.85,
        'longitude': 2.35,
        'connectors': <Map<String, dynamic>>[],
      };
      final station = ChargingStation.fromJson(json);
      expect(station.latitude, 48.85);
      expect(station.longitude, 2.35);
      expect(station.lat, 48.85);
      expect(station.lng, 2.35);
    });

    test('fromJson accepts legacy search-side lat/lng keys', () {
      // This is the shape persisted by the pre-#560 search/
      // ChargingStation. The unified entity must still parse it so
      // users upgrading from the old app don't lose their favorites.
      final json = {
        'id': 'ocm-1',
        'name': 'Legacy Shape',
        'operator': 'Ionity',
        'lat': 43.46,
        'lng': 3.42,
        'address': '1 Avenue du Test',
        'connectors': <Map<String, dynamic>>[],
      };
      final station = ChargingStation.fromJson(json);
      expect(station.latitude, 43.46);
      expect(station.longitude, 3.42);
      expect(station.lat, 43.46);
      expect(station.lng, 3.42);
      expect(station.name, 'Legacy Shape');
      expect(station.operator, 'Ionity');
      expect(station.address, '1 Avenue du Test');
    });

    test('fromJson prefers canonical keys when BOTH are present', () {
      // Guard against silent mis-reads if storage ever contains both
      // naming schemes in the same object.
      final json = {
        'id': 'ocm-1',
        'name': 'Both',
        'latitude': 10.0,
        'longitude': 20.0,
        'lat': 99.0,
        'lng': 99.0,
        'connectors': <Map<String, dynamic>>[],
      };
      final station = ChargingStation.fromJson(json);
      expect(station.latitude, 10.0);
      expect(station.longitude, 20.0);
    });

    test('toJson always produces canonical latitude/longitude keys', () {
      const station = ChargingStation(
        id: 'ocm-1',
        name: 'Canonical output',
        latitude: 48.85,
        longitude: 2.35,
      );
      final json = station.toJson();
      expect(json.containsKey('latitude'), isTrue);
      expect(json.containsKey('longitude'), isTrue);
      expect(json.containsKey('lat'), isFalse,
          reason: 'toJson must not emit the legacy lat key');
      expect(json.containsKey('lng'), isFalse,
          reason: 'toJson must not emit the legacy lng key');
      expect(json['latitude'], 48.85);
      expect(json['longitude'], 2.35);
    });

    test('round-trip through toJson -> fromJson preserves coordinates', () {
      const original = ChargingStation(
        id: 'ocm-1',
        name: 'Round trip',
        latitude: 48.85,
        longitude: 2.35,
      );
      final restored = ChargingStation.fromJson(original.toJson());
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored, original);
    });

    test(
        'legacy-shape JSON (lat/lng) round-trips back to canonical output '
        'via fromJson -> toJson', () {
      final legacyJson = {
        'id': 'ocm-1',
        'name': 'Legacy Shape',
        'lat': 43.46,
        'lng': 3.42,
        'connectors': <Map<String, dynamic>>[],
        'amenities': <dynamic>[],
      };
      final station = ChargingStation.fromJson(legacyJson);
      final roundTripped = station.toJson();
      expect(roundTripped['latitude'], 43.46);
      expect(roundTripped['longitude'], 3.42);
      expect(roundTripped.containsKey('lat'), isFalse);
      expect(roundTripped.containsKey('lng'), isFalse);
    });

    test('fromJson accepts full search-side payload with all ported fields',
        () {
      // Payload shape the pre-#560 EVChargingService emitted. Every
      // field on the entity must rehydrate correctly from it.
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
            'status': 'Currently Available',
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
      expect(station.latitude, 48.8);
      expect(station.longitude, 2.3);
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

      // Connector normalisation: free-form "CCS Type 2" -> enum + rawType
      expect(station.connectors.first.type, ConnectorType.ccs);
      expect(station.connectors.first.rawType, 'CCS Type 2');
      expect(station.connectors.first.maxPowerKw, 350);
      expect(station.connectors.first.powerKW, 350);
      expect(station.connectors.first.currentType, 'DC');
      expect(station.connectors.first.quantity, 4);
      expect(station.connectors.first.status, ConnectorStatus.available);
      expect(station.connectors.first.statusLabel, 'Currently Available');
    });
  });

  group('EvConnector.fromJson accepts both shapes', () {
    test('canonical shape: enum keys + maxPowerKw', () {
      final json = {
        'id': 'c',
        'type': 'ccs',
        'maxPowerKw': 150.0,
        'status': 'available',
      };
      final c = EvConnector.fromJson(json);
      expect(c.type, ConnectorType.ccs);
      expect(c.maxPowerKw, 150);
      expect(c.status, ConnectorStatus.available);
      expect(c.rawType, isNull);
      expect(c.statusLabel, isNull);
    });

    test('legacy search shape: powerKW + free-form type + free-form status',
        () {
      final json = {
        'type': 'CHAdeMO',
        'powerKW': 50.0,
        'quantity': 2,
        'currentType': 'DC',
        'status': 'In Use',
      };
      final c = EvConnector.fromJson(json);
      expect(c.type, ConnectorType.chademo);
      expect(c.rawType, 'CHAdeMO');
      expect(c.maxPowerKw, 50);
      expect(c.powerKW, 50, reason: 'powerKW getter aliases maxPowerKw');
      expect(c.quantity, 2);
      expect(c.currentType, 'DC');
      expect(c.status, ConnectorStatus.occupied);
      expect(c.statusLabel, 'In Use');
    });

    test('legacy status "Not Operational" maps to outOfOrder', () {
      final c = EvConnector.fromJson({
        'type': 'Type 2',
        'powerKW': 22.0,
        'status': 'Not Operational',
      });
      expect(c.status, ConnectorStatus.outOfOrder);
      expect(c.statusLabel, 'Not Operational');
    });

    test('connector without tariffId round-trips', () {
      const conn = EvConnector(
        id: 'x',
        type: ConnectorType.chademo,
        maxPowerKw: 50,
      );
      final restored = EvConnector.fromJson(conn.toJson());
      expect(restored, conn);
      expect(restored.status, ConnectorStatus.unknown);
    });

    test('ConnectorStatus.fromKey handles unknown values', () {
      expect(ConnectorStatus.fromKey(null), ConnectorStatus.unknown);
      expect(ConnectorStatus.fromKey('bogus'), ConnectorStatus.unknown);
      expect(
        ConnectorStatus.fromKey('out_of_order'),
        ConnectorStatus.outOfOrder,
      );
    });
  });

  group('connectorTypeFromLabel heuristics', () {
    test('maps known OCM labels to the right enum value', () {
      expect(connectorTypeFromLabel('CCS Type 2'), ConnectorType.ccs);
      expect(connectorTypeFromLabel('CCS Type 1'), ConnectorType.ccs);
      expect(connectorTypeFromLabel('CHAdeMO'), ConnectorType.chademo);
      expect(connectorTypeFromLabel('Tesla Supercharger'), ConnectorType.tesla);
      expect(connectorTypeFromLabel('Type 2'), ConnectorType.type2);
      expect(connectorTypeFromLabel('Type 1'), ConnectorType.type1);
      expect(connectorTypeFromLabel('Schuko'), ConnectorType.schuko);
      expect(connectorTypeFromLabel('3-pin'), ConnectorType.threePin);
    });

    test('falls back to Type 2 for unknown labels', () {
      expect(connectorTypeFromLabel('Unknown'), ConnectorType.type2);
      expect(connectorTypeFromLabel(''), ConnectorType.type2);
    });
  });
}
