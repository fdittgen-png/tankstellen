// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4367 — the seam that supplies one planning basis PER COMPARED
/// VEHICLE.
///
/// Two properties only this layer can get wrong: that each column is
/// read by its own vehicle id rather than inherited from the car the
/// driver happens to be driving, and that a vehicle with no evidence
/// stays without a number instead of borrowing one.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/domain/vehicle_trip_providers.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_level_estimator.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';
import 'package:tankstellen/features/fill_ups/providers/tank_level_provider.dart';
import 'package:tankstellen/features/fill_ups/providers/vehicle_comparison_provider.dart';
import 'package:tankstellen/features/fill_ups/providers/vehicle_trip_basis_override.dart';
import 'package:tankstellen/features/trips/api.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

const _a = VehicleProfile(
    id: 'a', name: 'A', tankCapacityL: 50, preferredFuelType: 'e10');
const _b = VehicleProfile(
    id: 'b', name: 'B', tankCapacityL: 70, preferredFuelType: 'diesel');
const _c = VehicleProfile(
    id: 'c', name: 'C', tankCapacityL: 40, preferredFuelType: 'e10');

FillUp _fill(String id, String vehicleId, int day, double odo,
        {double litres = 40, double cost = 60}) =>
    FillUp(
      id: id,
      date: DateTime.utc(2026, 1, day),
      liters: litres,
      totalCost: cost,
      odometerKm: odo,
      fuelType: FuelType.e10,
      vehicleId: vehicleId,
      currency: 'EUR',
    );

List<FillUp> _history() => [
      _fill('a0', 'a', 1, 0),
      _fill('a1', 'a', 10, 600, litres: 36, cost: 60),
      _fill('a2', 'a', 20, 1000, litres: 28, cost: 48),
      _fill('b0', 'b', 1, 5000, litres: 45, cost: 70),
      _fill('b1', 'b', 10, 5500, litres: 40, cost: 70),
      _fill('b2', 'b', 20, 6000, litres: 40, cost: 70),
    ];

TankLevelEstimate _tank(double level, double capacity) => TankLevelEstimate(
      levelL: level,
      capacityL: capacity,
      lastFillUpDate: DateTime.utc(2026, 1, 20),
      source: TankLevelSource.fillUp,
      sensorReadAt: null,
      rangeKm: null,
      rangeKmLastInterval: null,
    );

ProviderContainer _container({
  List<VehicleProfile> vehicles = const [_a, _b],
  List<FillUp>? fills,
}) {
  final container = ProviderContainer(overrides: [
    vehicleProfileListProvider.overrideWith(() => _StubVehicles(vehicles)),
    activeVehicleProfileProvider.overrideWith(() => _StubActiveVehicle(_a)),
    fillUpListProvider.overrideWith(() => _StubFills(fills ?? _history())),
    tripHistoryListProvider.overrideWith(() => _StubTrips(const [])),
    appClockProvider
        .overrideWithValue(FixedClock(DateTime.utc(2026, 3, 11, 14, 30))),
    // Each vehicle's own tank, by id. The whole point of the seam.
    tankLevelProvider('a').overrideWithValue(_tank(12, 50)),
    tankLevelProvider('b').overrideWithValue(_tank(65, 70)),
    tankLevelProvider('c').overrideWithValue(const TankLevelEstimate.unknown()),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('each column carries its OWN capacity, level and consumption', () {
    final container = _container();
    container
        .read(vehicleComparisonSelectorProvider.notifier)
        .select(const ['a', 'b']);

    final bases = container.read(realComparedVehicleBasesProvider);
    expect(bases.bases.map((b) => b.vehicleId), ['a', 'b']);

    final a = bases.bases.first;
    final b = bases.bases.last;
    expect(a.capacityL, 50);
    expect(b.capacityL, 70);
    expect(a.startLitres, 12);
    expect(b.startLitres, 65,
        reason: 'the active vehicle A has 12 L; B keeps its own 65');
    expect(a.fuel, FuelType.e10);
    expect(b.fuel, FuelType.diesel);
    expect(a.consumptionLPer100km, isNot(b.consumptionLPer100km));
  });

  test('the selection identity is #4365\'s normalised key', () {
    final container = _container();
    container
        .read(vehicleComparisonSelectorProvider.notifier)
        .select(const ['b', 'a']);
    expect(container.read(realComparedVehicleBasesProvider).key.vehicleIds,
        ['a', 'b'], reason: 'deduped and sorted by the shared key');
    expect(container.read(realComparedVehicleBasesProvider).bases
        .map((x) => x.vehicleId), ['b', 'a'],
        reason: 'the DISPLAY order is the order they were picked');
  });

  test('building the bases never changes the active vehicle', () {
    final container = _container();
    final before = container.read(activeVehicleProfileProvider);
    container
        .read(vehicleComparisonSelectorProvider.notifier)
        .select(const ['a', 'b']);
    container.read(realComparedVehicleBasesProvider);
    container.read(vehicleComparisonSelectorProvider.notifier).toggle('b');
    container.read(realComparedVehicleBasesProvider);

    expect(container.read(activeVehicleProfileProvider), same(before));
    expect(container.read(activeVehicleProfileProvider)!.id, 'a');
  });

  test('a measured consumption is labelled measured', () {
    final container = _container();
    container
        .read(vehicleComparisonSelectorProvider.notifier)
        .select(const ['a', 'b']);
    final a = container.read(realComparedVehicleBasesProvider).bases.first;
    expect(a.consumptionSource, TripInputSource.measured);
    expect(a.levelSource, TripInputSource.measured);
    expect(a.isManual, isFalse);
  });

  test('a vehicle with no history gets NO consumption — never a fleet '
      'average standing in', () {
    final container = _container(vehicles: const [_a, _c]);
    container
        .read(vehicleComparisonSelectorProvider.notifier)
        .select(const ['a', 'c']);
    final c = container.read(realComparedVehicleBasesProvider).bases.last;
    expect(c.vehicleId, 'c');
    expect(c.consumptionLPer100km, isNull);
    expect(c.consumptionSource, TripInputSource.unknown);
    expect(c.startLitres, isNull, reason: 'no fill has anchored the tank');
    expect(c.isPlannable, isFalse);
  });

  test('a deleted vehicle stays in the selection and is reported missing',
      () {
    final container = _container(vehicles: const [_a]);
    container
        .read(vehicleComparisonSelectorProvider.notifier)
        .select(const ['a', 'b']);
    final bases = container.read(realComparedVehicleBasesProvider);
    expect(bases.bases.map((x) => x.vehicleId), ['a']);
    expect(bases.missingVehicleIds, ['b']);
  });
}

class _StubVehicles extends VehicleProfileList {
  _StubVehicles(this._value);
  final List<VehicleProfile> _value;

  @override
  List<VehicleProfile> build() => _value;
}

class _StubActiveVehicle extends ActiveVehicleProfile {
  _StubActiveVehicle(this._value);
  final VehicleProfile? _value;

  @override
  VehicleProfile? build() => _value;
}

class _StubFills extends FillUpList {
  _StubFills(this._value);
  final List<FillUp> _value;

  @override
  List<FillUp> build() => _value;
}

class _StubTrips extends TripHistoryList {
  _StubTrips(this._value);
  final List<TripHistoryEntry> _value;

  @override
  List<TripHistoryEntry> build() => _value;
}
