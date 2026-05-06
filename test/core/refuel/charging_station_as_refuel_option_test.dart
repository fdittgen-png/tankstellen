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
  String? address,
  String? postCode,
  String? place,
  double dist = 0,
  DateTime? lastUpdate,
  String? updatedAt,
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
      address: address,
      postCode: postCode,
      place: place,
      dist: dist,
      lastUpdate: lastUpdate,
      updatedAt: updatedAt,
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

  group('ChargingStationAsRefuelOption — phase 4 enrichment (#1116)', () {
    test('address composes "<address>, <postCode> <place>"', () {
      final adapter = ChargingStationAsRefuelOption(
        _ev(
          address: 'Bahnhofstr. 1',
          postCode: '60311',
          place: 'Frankfurt',
        ),
      );
      expect(adapter.address, 'Bahnhofstr. 1, 60311 Frankfurt');
    });

    test('address falls back to address alone when city parts are empty',
        () {
      final adapter = ChargingStationAsRefuelOption(
        _ev(address: 'A1 Service Area'),
      );
      expect(adapter.address, 'A1 Service Area');
    });

    test('address falls back to "<postCode> <place>" when address is null',
        () {
      final adapter = ChargingStationAsRefuelOption(
        _ev(postCode: '34540', place: 'Castelnau'),
      );
      expect(adapter.address, '34540 Castelnau');
    });

    test('address is empty when all address fields are null', () {
      final adapter = ChargingStationAsRefuelOption(_ev());
      expect(adapter.address, '');
    });

    test('distanceMeters converts station.dist (km) to metres', () {
      final adapter = ChargingStationAsRefuelOption(_ev(dist: 2.5));
      expect(adapter.distanceMeters, 2500.0);
    });

    test('distanceMeters is null when station.dist is the freezed '
        'default 0', () {
      final adapter = ChargingStationAsRefuelOption(_ev(dist: 0));
      expect(adapter.distanceMeters, isNull);
    });

    test('is24h is always false until openingHours parsing lands', () {
      final adapter = ChargingStationAsRefuelOption(_ev());
      expect(adapter.is24h, isFalse);
    });

    test('lastUpdated prefers structured lastUpdate over legacy updatedAt',
        () {
      final structured = DateTime.utc(2026, 5, 4, 10, 0);
      final adapter = ChargingStationAsRefuelOption(_ev(
        lastUpdate: structured,
        updatedAt: '2024-01-01T00:00:00Z',
      ));
      expect(adapter.lastUpdated, structured);
    });

    test('lastUpdated falls back to updatedAt parse when lastUpdate is null',
        () {
      final adapter = ChargingStationAsRefuelOption(_ev(
        lastUpdate: null,
        updatedAt: '2026-05-04T08:00:00Z',
      ));
      expect(adapter.lastUpdated, DateTime.parse('2026-05-04T08:00:00Z'));
    });

    test('lastUpdated is null when both timestamps are absent / unparseable',
        () {
      expect(
        ChargingStationAsRefuelOption(_ev()).lastUpdated,
        isNull,
      );
      expect(
        ChargingStationAsRefuelOption(_ev(updatedAt: 'garbage')).lastUpdated,
        isNull,
      );
    });

    test('source returns the wrapped ChargingStation', () {
      final s = _ev(id: 'cs-1');
      final adapter = ChargingStationAsRefuelOption(s);
      expect(adapter.source, same(s));
    });
  });
}
