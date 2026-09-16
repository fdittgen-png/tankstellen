// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel/next_fill_decision.dart';
import 'package:tankstellen/core/domain/fuel/next_fill_request.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';
import 'package:tankstellen/features/fill_ups/providers/next_fill_decision_provider.dart';
import 'package:tankstellen/features/trips/api.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// Wiring tests for `nextFillDecisionProvider` (#4277). The rules are
/// pinned in `next_fill_decider_test.dart`; these pin that the provider
/// reads the live blend and profile, keys on a value-equal request, and
/// recomputes when the history changes.
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

NextFillRequest _request({VehicleFuelCapability? capability}) =>
    NextFillRequest(
      objective: FillObjective.lowestCostPerKm,
      capability: capability ??
          VehicleFuelCapability(
              approvedGrades: {FuelGrade.e10, FuelGrade.e85},
              provenance: 'test'),
      offers: [
        FuelOffer(grade: FuelGrade.e10, pricePerLitre: 1.8),
        FuelOffer(grade: FuelGrade.e85, pricePerLitre: 1.1),
      ],
      expectedFillLitres: 30,
    );

void main() {
  final history = [
    _fill('a', 0, FuelType.e10, 50, 0),
    _fill('b', 5, FuelType.e10, 30, 500),
    _fill('c', 10, FuelType.e10, 32, 1000),
  ];

  test('an unknown capability is answered, never guessed', () {
    final d = _container(history).read(nextFillDecisionProvider(
        'v1', _request(capability: const VehicleFuelCapability.unknown())));
    expect(d.outcome, NextFillOutcome.compatibilityUnknown);
  });

  test('evaluates the live tank against the learned profile', () {
    final d = _container(history).read(nextFillDecisionProvider('v1', _request()));
    final e10 = d.candidates.firstWhere((c) => c.grade == FuelGrade.e10);
    expect(e10.metrics.lPer100Km.value, closeTo(6.2, 1e-9));
    // No E85 has ever been driven: price alone recommends nothing.
    expect(d.outcome, NextFillOutcome.insufficientEvidence);
    expect(d.recommended, isNull);
  });

  test('equal requests share one provider; an edit recomputes', () {
    final container = _container(history);
    final sub =
        container.listen(nextFillDecisionProvider('v1', _request()), (_, _) {});
    expect(identical(container.read(nextFillDecisionProvider('v1', _request())),
        sub.read()), isTrue);

    (container.read(fillUpListProvider.notifier) as _StubFillUpList)
        .replaceAll(const []);

    expect(sub.read().candidates.every((c) => !c.metrics.lPer100Km.isKnown),
        isTrue);
  });
}
