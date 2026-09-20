// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_comparison_key.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';
import 'package:tankstellen/features/fill_ups/providers/vehicle_comparison_provider.dart';
import 'package:tankstellen/features/trips/api.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// #4365 — the provider layer: the selection is independent of the
/// active vehicle in BOTH directions, and an edit to the records
/// refreshes the comparison without touching either.
class _StubVehicles extends VehicleProfileList {
  _StubVehicles(this._value);
  final List<VehicleProfile> _value;

  @override
  List<VehicleProfile> build() => _value;

  void replaceAll(List<VehicleProfile> next) => state = next;
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

  void replaceAll(List<FillUp> next) => state = next;
}

class _StubTrips extends TripHistoryList {
  _StubTrips(this._value);
  final List<TripHistoryEntry> _value;

  @override
  List<TripHistoryEntry> build() => _value;
}

const _a = VehicleProfile(id: 'a', name: 'A', tankCapacityL: 50);
const _b = VehicleProfile(id: 'b', name: 'B', tankCapacityL: 50);

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
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('two selected vehicles render in one comparison over one period', () {
    final container = _container();
    container.read(vehicleComparisonSelectorProvider.notifier)
        .select(const ['a', 'b']);

    final comparison = container.read(selectedVehicleComparisonProvider);

    expect(comparison.columns.map((c) => c.vehicleId), ['a', 'b']);
    expect(comparison.key.period, ComparisonPeriod.allHistory);
    expect(comparison.columnFor('a')!.consumptionPer100Km.valueOrNull,
        closeTo(6.4, 1e-9));
  });

  test('selecting columns never changes the active vehicle (box 1)', () {
    final container = _container();
    final before = container.read(activeVehicleProfileProvider);

    container.read(vehicleComparisonSelectorProvider.notifier).toggle('b');
    container.read(vehicleComparisonSelectorProvider.notifier).toggle('a');
    container.read(vehicleComparisonSelectorProvider.notifier)
        .setReference('b');
    container.read(vehicleComparisonSelectorProvider.notifier)
        .setPeriod(ComparisonPeriod(start: DateTime.utc(2026, 1, 5)));

    expect(container.read(activeVehicleProfileProvider), before);
    expect(container.read(activeVehicleProfileProvider)?.id, 'a');
  });

  test('the report instant comes from the clock seam, not the wall clock',
      () {
    final container = _container();
    container.read(vehicleComparisonSelectorProvider.notifier)
        .select(const ['a', 'b']);

    expect(container.read(selectedVehicleComparisonProvider).asOf,
        DateTime.utc(2026, 3, 11, 14, 30));
  });

  test('two keys for the same question share one result', () {
    final container = _container();
    final one = container.read(vehicleHistoryComparisonProvider(
        VehicleComparisonKey(vehicleIds: const ['a', 'b'])));
    final two = container.read(vehicleHistoryComparisonProvider(
        VehicleComparisonKey(vehicleIds: const ['b', 'a'])));

    expect(identical(one, two), isTrue);
  });

  test('a different period is a different key, not a stale answer', () {
    final container = _container();
    final all = container.read(vehicleHistoryComparisonProvider(
        VehicleComparisonKey(vehicleIds: const ['a', 'b'])));
    final windowed = container.read(vehicleHistoryComparisonProvider(
        VehicleComparisonKey(
            vehicleIds: const ['a', 'b'],
            period: ComparisonPeriod(
                start: DateTime.utc(2026, 1, 15),
                boundaryPolicy: BoundaryWindowPolicy.whollyContained))));

    expect(identical(all, windowed), isFalse);
    expect(all.columnFor('a')!.matchedWindowCount, 2);
    expect(windowed.columnFor('a')!.matchedWindowCount, 0);
  });

  test('editing a fill refreshes the result, not the selection or the '
      'active vehicle (box 8)', () {
    final container = _container();
    final selector = container.read(vehicleComparisonSelectorProvider.notifier)
      ..select(const ['a', 'b']);
    final sub =
        container.listen(selectedVehicleComparisonProvider, (_, _) {});
    expect(sub.read().columnFor('a')!.matchedWindowCount, 2);

    (container.read(fillUpListProvider.notifier) as _StubFills)
        .replaceAll(_history().where((f) => f.id != 'a2').toList());

    expect(sub.read().columnFor('a')!.matchedWindowCount, 1);
    expect(sub.read().columnFor('b')!.matchedWindowCount, 2,
        reason: 'the other vehicle is untouched');
    expect(container.read(vehicleComparisonSelectorProvider).vehicleIds,
        ['a', 'b']);
    expect(container.read(activeVehicleProfileProvider)?.id, 'a');
    expect(selector.state.vehicleIds, ['a', 'b']);
  });

  test('deleting a compared vehicle leaves a recoverable selection (box 8)',
      () {
    final container = _container();
    container.read(vehicleComparisonSelectorProvider.notifier)
        .select(const ['a', 'b']);
    final sub =
        container.listen(selectedVehicleComparisonProvider, (_, _) {});

    (container.read(vehicleProfileListProvider.notifier) as _StubVehicles)
        .replaceAll(const [_a]);

    expect(sub.read().missingVehicleIds, ['b']);
    expect(container.read(vehicleComparisonSelectorProvider).vehicleIds,
        ['a', 'b'],
        reason: 'the selection survives so the user can restore it');

    container.read(vehicleComparisonSelectorProvider.notifier).drop('b');
    expect(
        container.read(vehicleComparisonSelectorProvider).vehicleIds, ['a']);
  });

  test('the reference falls back to the first selection when dropped', () {
    final container = _container();
    final selector = container.read(vehicleComparisonSelectorProvider.notifier)
      ..select(const ['a', 'b'])
      ..setReference('b');
    expect(container.read(vehicleComparisonSelectorProvider)
        .effectiveReferenceId, 'b');

    selector.drop('b');

    expect(container.read(vehicleComparisonSelectorProvider)
        .effectiveReferenceId, 'a');
  });
}
