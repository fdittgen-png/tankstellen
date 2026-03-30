import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/charging_station.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

void main() {
  group('FuelStationResult', () {
    final station = Station(
      id: 'abc-123',
      name: 'My Station',
      brand: 'Aral',
      street: 'Hauptstr. 1',
      postCode: '10115',
      place: 'Berlin',
      lat: 52.52,
      lng: 13.405,
      dist: 2.3,
      isOpen: true,
    );

    test('delegates lat, lng, dist correctly', () {
      final result = FuelStationResult(station);

      expect(result.lat, 52.52);
      expect(result.lng, 13.405);
      expect(result.dist, 2.3);
    });

    test('delegates id correctly', () {
      final result = FuelStationResult(station);

      expect(result.id, 'abc-123');
    });

    test('displayName uses brand when non-empty and not "Station"', () {
      final result = FuelStationResult(station);

      expect(result.displayName, 'Aral');
    });

    test('displayName falls back to name when brand is empty', () {
      final stationEmptyBrand = station.copyWith(brand: '');
      final result = FuelStationResult(stationEmptyBrand);

      expect(result.displayName, 'My Station');
    });

    test('displayName falls back to name when brand is "Station"', () {
      final stationGenericBrand = station.copyWith(brand: 'Station');
      final result = FuelStationResult(stationGenericBrand);

      expect(result.displayName, 'My Station');
    });

    test('displayAddress returns street', () {
      final result = FuelStationResult(station);

      expect(result.displayAddress, 'Hauptstr. 1');
    });

    test('implements SearchResultItem', () {
      final result = FuelStationResult(station);

      expect(result, isA<SearchResultItem>());
    });
  });

  group('EVStationResult', () {
    const chargingStation = ChargingStation(
      id: 'ocm-789',
      name: 'Charger Name',
      operator: 'Ionity',
      lat: 48.8566,
      lng: 2.3522,
      dist: 1.5,
      address: '10 Rue de Rivoli',
      connectors: [
        Connector(type: 'CCS Type 2', powerKW: 350, quantity: 4, currentType: 'DC'),
        Connector(type: 'Type 2', powerKW: 22, quantity: 2, currentType: 'AC'),
        Connector(type: 'CCS Type 2', powerKW: 150, quantity: 2, currentType: 'DC'),
      ],
    );

    test('delegates lat, lng, dist correctly', () {
      const result = EVStationResult(chargingStation);

      expect(result.lat, 48.8566);
      expect(result.lng, 2.3522);
      expect(result.dist, 1.5);
    });

    test('delegates id correctly', () {
      const result = EVStationResult(chargingStation);

      expect(result.id, 'ocm-789');
    });

    test('displayName uses operator when non-empty', () {
      const result = EVStationResult(chargingStation);

      expect(result.displayName, 'Ionity');
    });

    test('displayName falls back to name when operator is empty', () {
      const stationNoOp = ChargingStation(
        id: 'ocm-1',
        name: 'Fallback Name',
        operator: '',
        lat: 50.0,
        lng: 8.0,
        address: 'Addr',
        connectors: [],
      );
      const result = EVStationResult(stationNoOp);

      expect(result.displayName, 'Fallback Name');
    });

    test('displayAddress returns address', () {
      const result = EVStationResult(chargingStation);

      expect(result.displayAddress, '10 Rue de Rivoli');
    });

    test('maxPowerKW calculates max from connectors', () {
      const result = EVStationResult(chargingStation);

      expect(result.maxPowerKW, 350);
    });

    test('maxPowerKW returns 0 for empty connectors', () {
      const emptyStation = ChargingStation(
        id: 'ocm-empty',
        name: 'Empty',
        operator: 'Op',
        lat: 50.0,
        lng: 8.0,
        address: 'Addr',
        connectors: [],
      );
      const result = EVStationResult(emptyStation);

      expect(result.maxPowerKW, 0);
    });

    test('connectorTypes deduplicates types', () {
      const result = EVStationResult(chargingStation);
      final types = result.connectorTypes;

      // 3 connectors but only 2 unique types: 'CCS Type 2' and 'Type 2'
      expect(types.length, 2);
      expect(types, containsAll(['CCS Type 2', 'Type 2']));
    });

    test('implements SearchResultItem', () {
      const result = EVStationResult(chargingStation);

      expect(result, isA<SearchResultItem>());
    });
  });

  group('Pattern matching', () {
    test('switch works on SearchResultItem sealed class', () {
      final fuelStation = Station(
        id: '1',
        name: 'S',
        brand: 'B',
        street: 'St',
        postCode: '00000',
        place: 'P',
        lat: 50,
        lng: 8,
        isOpen: true,
      );
      const evStation = ChargingStation(
        id: 'ocm-1',
        name: 'E',
        operator: 'Op',
        lat: 50,
        lng: 8,
        address: 'A',
        connectors: [],
      );

      final items = <SearchResultItem>[
        FuelStationResult(fuelStation),
        const EVStationResult(evStation),
      ];

      final labels = items.map((item) => switch (item) {
        FuelStationResult() => 'fuel',
        EVStationResult() => 'ev',
      }).toList();

      expect(labels, ['fuel', 'ev']);
    });
  });
}
