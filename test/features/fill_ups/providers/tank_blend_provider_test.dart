// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';
import 'package:tankstellen/features/fill_ups/providers/tank_blend_provider.dart';
import 'package:tankstellen/features/trips/api.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// Wiring tests for `tankBlendProvider` (#4279).
///
/// The lifecycle semantics are pinned in `tank_blend_event_log_test.dart`
/// over the real adapter and engine. These pin only what the provider adds:
/// it reads the three sources, recomputes when the fill-up history changes
/// (an edit, a correction, a delete), and a fresh container — a restart —
/// derives the identical snapshot from the same records.
class _StubVehicleProfileList extends VehicleProfileList {
  _StubVehicleProfileList(this._value);
  final List<VehicleProfile> _value;

  @override
  List<VehicleProfile> build() => _value;
}

class _StubFillUpList extends FillUpList {
  _StubFillUpList(this._value);
  final List<FillUp> _value;

  @override
  List<FillUp> build() => _value;

  void replaceAll(List<FillUp> fills) => state = fills;
}

class _StubTripHistoryList extends TripHistoryList {
  _StubTripHistoryList(this._value);
  final List<TripHistoryEntry> _value;

  @override
  List<TripHistoryEntry> build() => _value;
}

const _vehicle = VehicleProfile(
  id: 'v1',
  name: 'Flex',
  type: VehicleType.combustion,
  tankCapacityL: 50,
);

FillUp _fill(String id, int day, FuelType fuel, double litres) => FillUp(
      id: id,
      date: DateTime.utc(2026, 9, 1 + day),
      liters: litres,
      totalCost: litres * 1.5,
      odometerKm: 0,
      fuelType: fuel,
      vehicleId: 'v1',
    );

ProviderContainer _container({
  List<VehicleProfile> vehicles = const [_vehicle],
  List<FillUp> fills = const [],
}) {
  final container = ProviderContainer(overrides: [
    vehicleProfileListProvider.overrideWith(() => _StubVehicleProfileList(vehicles)),
    fillUpListProvider.overrideWith(() => _StubFillUpList(fills)),
    tripHistoryListProvider.overrideWith(() => _StubTripHistoryList(const [])),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('a vehicle with no history is explicitly unknown', () {
    final s = _container().read(tankBlendProvider('v1'));

    expect(s.unknownShare, 1);
    expect(s.confidence, 0);
    expect(s.tankCapacityLitres, 50);
  });

  test('an unknown vehicle id still answers — unknown, capacity-less', () {
    final s = _container(vehicles: const []).read(tankBlendProvider('ghost'));

    expect(s.unknownShare, 1);
    expect(s.tankCapacityLitres, isNull);
  });

  test('derives the blend from the vehicle fill-ups', () {
    final s = _container(fills: [
      _fill('a', 0, FuelType.e85, 50),
      _fill('b', 5, FuelType.e10, 20),
    ]).read(tankBlendProvider('v1'));

    expect(s.exactShare(FuelGrade.e85), closeTo(0.6, 1e-12));
    expect(s.exactShare(FuelGrade.e10), closeTo(0.4, 1e-12));
  });

  test('an edited fill-up history is recomputed, not patched', () {
    final container = _container(fills: [
      _fill('a', 0, FuelType.e85, 50),
      _fill('b', 5, FuelType.e10, 20),
    ]);
    final sub = container.listen(tankBlendProvider('v1'), (_, _) {});
    expect(sub.read().exactShare(FuelGrade.e85), closeTo(0.6, 1e-12));

    (container.read(fillUpListProvider.notifier) as _StubFillUpList)
        .replaceAll([
      _fill('a', 0, FuelType.e85, 50),
      _fill('b', 5, FuelType.e85, 20),
    ]);

    expect(sub.read().exactShare(FuelGrade.e85), 1);
  });

  test('a restart derives the identical snapshot from the same records', () {
    final fills = [
      _fill('a', 0, FuelType.e10, 50),
      _fill('b', 3, FuelType.e85, 25),
    ];

    final first = _container(fills: fills).read(tankBlendProvider('v1'));
    final second = _container(fills: fills).read(tankBlendProvider('v1'));

    expect(second.toJson(), first.toJson());
  });
}
