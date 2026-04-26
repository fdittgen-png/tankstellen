import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/refuel/charging_station_as_refuel_option.dart';
import 'package:tankstellen/core/refuel/refuel_availability.dart';
import 'package:tankstellen/core/refuel/refuel_provider.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart'
    show ConnectorType;

EvConnector _connector(ConnectorStatus status) => EvConnector(
      id: 'c-${status.key}',
      type: ConnectorType.ccs,
      maxPowerKw: 150,
      status: status,
    );

ChargingStation _ev({
  String id = 'ev-1',
  String? operator = 'Ionity',
  double latitude = 50.1109,
  double longitude = 8.6821,
  bool? isOperational,
  List<EvConnector> connectors = const <EvConnector>[],
  String? usageCost,
}) =>
    ChargingStation(
      id: id,
      name: 'Charger $id',
      operator: operator,
      latitude: latitude,
      longitude: longitude,
      isOperational: isOperational,
      connectors: connectors,
      usageCost: usageCost,
    );

void main() {
  group('ChargingStationAsRefuelOption — identity & provider', () {
    test('coordinates pass through latitude/longitude', () {
      final adapter = ChargingStationAsRefuelOption(
        _ev(latitude: 48.8566, longitude: 2.3522),
      );
      expect(adapter.coordinates.lat, 48.8566);
      expect(adapter.coordinates.lng, 2.3522);
    });

    test('id uses the "ev:" type prefix', () {
      final adapter = ChargingStationAsRefuelOption(_ev(id: 'abc-123'));
      expect(adapter.id, 'ev:abc-123');
    });

    test('provider wraps the operator with kind=ev', () {
      final adapter = ChargingStationAsRefuelOption(
        _ev(operator: 'Tesla Supercharger'),
      );
      expect(
        adapter.provider,
        const RefuelProvider(
          name: 'Tesla Supercharger',
          kind: RefuelProviderKind.ev,
        ),
      );
    });

    test('null operator collapses to RefuelProvider.unknown', () {
      final adapter = ChargingStationAsRefuelOption(_ev(operator: null));
      expect(adapter.provider, RefuelProvider.unknown);
    });

    test('empty operator collapses to RefuelProvider.unknown', () {
      final adapter = ChargingStationAsRefuelOption(_ev(operator: ''));
      expect(adapter.provider, RefuelProvider.unknown);
    });
  });

  group('ChargingStationAsRefuelOption — availability', () {
    test('isOperational=false short-circuits to closed', () {
      final adapter = ChargingStationAsRefuelOption(
        _ev(
          isOperational: false,
          // Even an "available" connector is overridden by site-level
          // outage flag.
          connectors: [_connector(ConnectorStatus.available)],
        ),
      );
      expect(adapter.availability, RefuelAvailability.closed());
      expect(adapter.availability.isOperational, isFalse);
    });

    test('any available connector → open', () {
      final adapter = ChargingStationAsRefuelOption(
        _ev(connectors: [
          _connector(ConnectorStatus.occupied),
          _connector(ConnectorStatus.available),
        ]),
      );
      expect(adapter.availability, RefuelAvailability.open);
      expect(adapter.availability.isOperational, isTrue);
    });

    test('only-occupied connectors → limited with reason', () {
      final adapter = ChargingStationAsRefuelOption(
        _ev(connectors: [
          _connector(ConnectorStatus.occupied),
          _connector(ConnectorStatus.occupied),
        ]),
      );
      expect(
        adapter.availability,
        RefuelAvailability.limited(reason: 'All connectors occupied'),
      );
      expect(adapter.availability.isOperational, isFalse);
    });

    test('only-out-of-order connectors → closed with reason', () {
      final adapter = ChargingStationAsRefuelOption(
        _ev(connectors: [
          _connector(ConnectorStatus.outOfOrder),
        ]),
      );
      expect(
        adapter.availability,
        RefuelAvailability.closed(reason: 'All connectors out of order'),
      );
    });

    test('empty connector list → unknown', () {
      final adapter = ChargingStationAsRefuelOption(
        _ev(connectors: const []),
      );
      expect(adapter.availability, RefuelAvailability.unknown);
    });

    test('only-unknown-status connectors → unknown', () {
      final adapter = ChargingStationAsRefuelOption(
        _ev(connectors: [
          _connector(ConnectorStatus.unknown),
          _connector(ConnectorStatus.unknown),
        ]),
      );
      expect(adapter.availability, RefuelAvailability.unknown);
    });

    test('isOperational=null does NOT trigger closed (only false does)', () {
      final adapter = ChargingStationAsRefuelOption(
        _ev(
          // Default: isOperational is null
          connectors: [_connector(ConnectorStatus.available)],
        ),
      );
      expect(adapter.availability, RefuelAvailability.open);
    });
  });

  group('ChargingStationAsRefuelOption — price (phase-2 limitation)', () {
    test('price is always null in phase 2 even when usageCost is set', () {
      final adapter = ChargingStationAsRefuelOption(
        _ev(usageCost: '0.49 EUR/kWh'),
      );
      expect(adapter.price, isNull);
    });

    test('price is null when usageCost is null', () {
      final adapter = ChargingStationAsRefuelOption(_ev(usageCost: null));
      expect(adapter.price, isNull);
    });
  });
}
