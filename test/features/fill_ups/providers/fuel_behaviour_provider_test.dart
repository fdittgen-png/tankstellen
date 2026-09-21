// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel/fuel_context.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';
import 'package:tankstellen/features/fill_ups/providers/fuel_behaviour_provider.dart';
import 'package:tankstellen/features/trips/api.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// Wiring tests for `fuelBehaviourProfileProvider` (#4276). The analysis
/// is pinned in the domain and adapter tests; these pin only that the
/// provider reads the three sources, recomputes on an edit, and derives the
/// identical profile after a restart.
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

FillUp _fill(String id, int day, FuelType fuel, double litres, double odo) =>
    FillUp(
      id: id,
      date: DateTime.utc(2026, 9, 1 + day),
      liters: litres,
      totalCost: litres * 1.5,
      odometerKm: odo,
      fuelType: fuel,
      vehicleId: 'v1',
    );

final _e10History = [
  _fill('a', 0, FuelType.e10, 50, 0),
  _fill('b', 5, FuelType.e10, 30, 500),
  _fill('c', 10, FuelType.e10, 32, 1000),
];

ProviderContainer _container(List<FillUp> fills) {
  final container = ProviderContainer(overrides: [
    vehicleProfileListProvider
        .overrideWith(() => _StubVehicleProfileList(const [_vehicle])),
    fillUpListProvider.overrideWith(() => _StubFillUpList(fills)),
    tripHistoryListProvider
        .overrideWith(() => _StubTripHistoryList(const [])),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  final e10 = FuelContext.pure(FuelGrade.e10);
  final e85 = FuelContext.pure(FuelGrade.e85);

  test('derives the profile from the vehicle history', () {
    final p = _container(_e10History).read(fuelBehaviourProfileProvider('v1'));
    expect(p.behaviourOf(e10)!.lPer100Km.value, closeTo(6.2, 1e-9));
    expect(p.tankCapacityLitres, 50);
  });

  test('an edited history is recomputed', () {
    final container = _container(_e10History);
    final sub = container.listen(fuelBehaviourProfileProvider('v1'), (_, _) {});
    expect(sub.read().contexts.keys, [e10]);

    (container.read(fillUpListProvider.notifier) as _StubFillUpList)
        .replaceAll([
      _fill('a', 0, FuelType.e85, 50, 0),
      _fill('b', 5, FuelType.e85, 40, 500),
      _fill('c', 10, FuelType.e85, 41, 1000),
    ]);

    expect(sub.read().contexts.keys, [e85]);
  });

  test('a restart derives the identical profile', () {
    final first = _container(_e10History).read(fuelBehaviourProfileProvider('v1'));
    final second =
        _container(_e10History).read(fuelBehaviourProfileProvider('v1'));
    expect(jsonEncode(second.toJson()), jsonEncode(first.toJson()));
  });
}
