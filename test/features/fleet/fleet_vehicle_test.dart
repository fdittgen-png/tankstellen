// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// #4213 — the company-asset identity and the search it must support:
// "fleet code, model or allowed registration fragment".
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/fleet/fleet_directory.dart';
import 'package:tankstellen/features/fleet/api.dart';

const _vehicle = FleetVehicle(
  fleetVehicleId: 'veh-1',
  orgId: 'org-acme',
  fleetCode: 'VAN-12',
  displayName: 'VW Caddy 2.0 TDI',
  plateMasked: 'B-XY 1234',
);

void main() {
  group('search matches code, model and plate fragment', () {
    test('an empty query matches everything — the sheet opens on the full '
        'assigned list', () {
      expect(_vehicle.matches(''), isTrue);
      expect(_vehicle.matches('   '), isTrue);
    });

    test('a fleet-code fragment matches regardless of case, spaces and '
        'the hyphen the driver does not type', () {
      expect(_vehicle.matches('van'), isTrue);
      expect(_vehicle.matches('VAN12'), isTrue);
      expect(_vehicle.matches('van 12'), isTrue);
      expect(_vehicle.matches('12'), isTrue);
    });

    test('a model fragment matches', () {
      expect(_vehicle.matches('caddy'), isTrue);
      expect(_vehicle.matches('2.0 tdi'), isTrue);
    });

    test('a registration FRAGMENT matches — a driver reads the last group '
        'off the plate, not the whole thing', () {
      expect(_vehicle.matches('1234'), isTrue);
      expect(_vehicle.matches('bxy'), isTrue);
    });

    test('an unrelated query matches nothing', () {
      expect(_vehicle.matches('sprinter'), isFalse);
    });

    test('a vehicle whose policy shows no plate is still searchable by '
        'code and model', () {
      const unplated = FleetVehicle(
        fleetVehicleId: 'veh-2',
        orgId: 'org-acme',
        fleetCode: 'CAR-07',
        displayName: 'Skoda Octavia',
      );

      expect(unplated.matches('car-07'), isTrue);
      expect(unplated.matches('1234'), isFalse);
    });
  });

  group('a directory row becomes a domain vehicle', () {
    test('every identity field carries over, and the local profile is the '
        'device\'s own mapping — never something the row invents', () {
      const row = FleetVehicleRow(
        id: 'veh-1',
        orgId: 'org-acme',
        fleetCode: 'VAN-12',
        displayName: 'VW Caddy 2.0 TDI',
        plateMasked: 'B-XY 1234',
        data: {'local_vehicle_profile_id': 'smuggled'},
      );

      expect(FleetVehicle.fromRow(row), _vehicle);
      expect(FleetVehicle.fromRow(row).localVehicleProfileId, isNull,
          reason: 'the org directory does not know the driver\'s local '
              'vehicle profile and must not be able to claim one');
      expect(
        FleetVehicle.fromRow(row, localVehicleProfileId: 'local-1')
            .localVehicleProfileId,
        'local-1',
      );
    });
  });

  group('persistence', () {
    test('round-trips through JSON', () {
      expect(FleetVehicle.fromJson(_vehicle.toJson()), _vehicle);
    });

    test('a blob missing an identity field decodes as nothing', () {
      expect(
        FleetVehicle.fromJson(const {
          'fleet_vehicle_id': 'veh-1',
          'org_id': 'org-acme',
        }),
        isNull,
      );
    });

    test('withLocalProfile changes only the mapping', () {
      final linked = _vehicle.withLocalProfile('local-9');

      expect(linked.localVehicleProfileId, 'local-9');
      expect(linked.fleetVehicleId, _vehicle.fleetVehicleId);
      expect(linked.plateMasked, _vehicle.plateMasked);
      expect(linked, isNot(_vehicle));
    });
  });
}
