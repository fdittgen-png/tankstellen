import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/ev/domain/entities/opening_hours.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

void main() {
  group('ChargingStation', () {
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

    test('ConnectorStatus.fromKey handles unknown values', () {
      expect(ConnectorStatus.fromKey(null), ConnectorStatus.unknown);
      expect(ConnectorStatus.fromKey('bogus'), ConnectorStatus.unknown);
      expect(
        ConnectorStatus.fromKey('out_of_order'),
        ConnectorStatus.outOfOrder,
      );
    });
  });
}
