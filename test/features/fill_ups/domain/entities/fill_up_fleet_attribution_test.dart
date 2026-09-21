// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// #4213 (Epic #4211) — `FillUp.fleetAttribution`: the fleet vehicle a
// fill-up was logged against, stamped at creation and never rewritten
// by a later switch. The field rides inside the `fill_ups.data` JSONB
// column, so this test also pins that a legacy row (no such key) still
// decodes, and that a personal fill-up stays attribution-free.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fleet/api.dart';

final _at = DateTime.utc(2026, 3, 11, 14, 30);

final _attribution = VehicleAttribution(
  fleetVehicleId: 'veh-van',
  localVehicleId: 'local-1',
  source: VehicleAttributionSource.explicit,
  confidence: 1,
  evidence: const ['tap'],
  at: _at,
);

FillUp _fillUp({VehicleAttribution? attribution}) => FillUp(
      id: 'fill-1',
      date: DateTime.utc(2026, 3, 11, 9),
      liters: 42,
      totalCost: 71.4,
      odometerKm: 84210,
      fuelType: FuelType.diesel,
      fleetAttribution: attribution,
    );

void main() {
  test('a personal fill-up carries no attribution — null means "not a '
      'fleet record", never "the current fleet vehicle"', () {
    expect(_fillUp().fleetAttribution, isNull);
  });

  test('the attribution round-trips through the JSONB blob', () {
    final decoded = FillUp.fromJson(_fillUp(attribution: _attribution)
        .toJson());

    expect(decoded.fleetAttribution, _attribution);
    expect(decoded.fleetAttribution!.source,
        VehicleAttributionSource.explicit);
    expect(decoded.fleetAttribution!.evidence, ['tap']);
  });

  test('the field lands INSIDE the serialised model — no new column is '
      'needed on `fill_ups` (HARD RULE #5)', () {
    final json = _fillUp(attribution: _attribution).toJson();

    expect(json.containsKey('fleetAttribution'), isTrue);
    expect(json['fleetAttribution'], isA<Map<String, dynamic>>());
    expect((json['fleetAttribution'] as Map)['fleet_vehicle_id'], 'veh-van');
  });

  test('a fill-up written before the field existed still decodes', () {
    final legacy = _fillUp(attribution: _attribution).toJson()
      ..remove('fleetAttribution');

    expect(FillUp.fromJson(legacy).fleetAttribution, isNull);
  });

  test('switching the current vehicle never rewrites an existing '
      'attribution — the record keeps the car it was logged with', () {
    final logged = _fillUp(attribution: _attribution);

    // What a later switch produces: a NEW attribution for new records.
    final afterSwitch = VehicleAttribution(
      fleetVehicleId: 'veh-estate',
      source: VehicleAttributionSource.explicit,
      confidence: 1,
      at: _at.add(const Duration(hours: 2)),
    );
    final nextFill = _fillUp(attribution: afterSwitch);

    expect(logged.fleetAttribution!.fleetVehicleId, 'veh-van',
        reason: '#4213: changing the current vehicle later must never '
            'rewrite history');
    expect(nextFill.fleetAttribution!.fleetVehicleId, 'veh-estate');
    expect(FillUp.fromJson(logged.toJson()).fleetAttribution,
        _attribution);
  });

  test('copyWith can only replace the whole attribution, so an accidental '
      'partial rewrite is not expressible', () {
    final logged = _fillUp(attribution: _attribution);

    expect(logged.copyWith(notes: 'receipt scanned').fleetAttribution,
        _attribution);
  });
}
