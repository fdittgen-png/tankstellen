// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel/next_fill_decision.dart';
import 'package:tankstellen/core/domain/fuel/next_fill_request.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/favorites/api.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';
import 'package:tankstellen/features/fill_ups/providers/fuel_and_tank_provider.dart';
import 'package:tankstellen/features/trips/api.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../fakes/fake_storage_repository.dart';

/// #4278 — the providers behind the Fuel & Tank surface: the persisted
/// objective, the offers read from the favourites' price cache, and the
/// request/view wiring over the real blend, profile and decision.
class _Vehicles extends VehicleProfileList {
  _Vehicles(this._value);
  final List<VehicleProfile> _value;
  @override
  List<VehicleProfile> build() => _value;
}

class _FillUps extends FillUpList {
  _FillUps(this._value);
  final List<FillUp> _value;
  @override
  List<FillUp> build() => _value;
}

class _Trips extends TripHistoryList {
  @override
  List<TripHistoryEntry> build() => const [];
}

class _Favorites extends FavoriteStations {
  _Favorites(this._stations);
  final List<Station> _stations;
  @override
  AsyncValue<ServiceResult<List<Station>>> build() => AsyncValue.data(
      ServiceResult(
          data: _stations,
          source: ServiceSource.cache,
          fetchedAt: DateTime.utc(2026, 9, 16)));
}

Station _station(String id, {double? e10, double? e85, double? diesel}) =>
    Station(
      id: id,
      name: id,
      brand: 'B',
      street: 'S',
      postCode: '00000',
      place: 'P',
      lat: 0,
      lng: 0,
      isOpen: true,
      e10: e10,
      e85: e85,
      diesel: diesel,
    );

void main() {
  const flex = VehicleProfile(
    id: 'v1',
    name: 'Flex',
    tankCapacityL: 50,
    preferredFuelType: 'e85',
    multiFuelCapable: true,
  );

  ProviderContainer container({
    List<VehicleProfile> vehicles = const [flex],
    List<Station> favorites = const [],
    List<FillUp> fills = const [],
  }) {
    final c = ProviderContainer(overrides: [
      storageRepositoryProvider.overrideWithValue(FakeStorageRepository()),
      vehicleProfileListProvider.overrideWith(() => _Vehicles(vehicles)),
      fillUpListProvider.overrideWith(() => _FillUps(fills)),
      tripHistoryListProvider.overrideWith(_Trips.new),
      favoriteStationsProvider.overrideWith(() => _Favorites(favorites)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('FillObjectiveSetting', () {
    test('defaults to lowest cost per km', () {
      expect(container().read(fillObjectiveSettingProvider),
          FillObjective.lowestCostPerKm);
    });

    test('persists the selection in the settings box', () async {
      final storage = FakeStorageRepository();
      final c = ProviderContainer(overrides: [
        storageRepositoryProvider.overrideWithValue(storage),
      ]);
      addTearDown(c.dispose);
      await c
          .read(fillObjectiveSettingProvider.notifier)
          .set(FillObjective.lowestCo2ePerKm);
      expect(storage.getSetting(StorageKeys.fillObjective),
          'lowestCo2ePerKm');
      expect(c.read(fillObjectiveSettingProvider),
          FillObjective.lowestCo2ePerKm);

      final reopened = ProviderContainer(overrides: [
        storageRepositoryProvider.overrideWithValue(storage),
      ]);
      addTearDown(reopened.dispose);
      expect(reopened.read(fillObjectiveSettingProvider),
          FillObjective.lowestCo2ePerKm);
    });

    test('an unknown stored name falls back to the default', () async {
      final storage = FakeStorageRepository();
      await storage.putSetting(StorageKeys.fillObjective, 'fastest');
      final c = ProviderContainer(overrides: [
        storageRepositoryProvider.overrideWithValue(storage),
      ]);
      addTearDown(c.dispose);
      expect(c.read(fillObjectiveSettingProvider),
          FillObjective.lowestCostPerKm);
    });
  });

  group('nextFillOffers', () {
    test('the cheapest favourite price per grade the car can take', () {
      final c = container(favorites: [
        _station('a', e10: 1.899, e85: 1.099, diesel: 1.699),
        _station('b', e10: 1.849, e85: 1.149),
      ]);
      final offers = c.read(nextFillOffersProvider('v1'));
      expect(
          {for (final o in offers) o.grade: o.pricePerLitre},
          {FuelGrade.e10: 1.849, FuelGrade.e85: 1.099},
          reason: 'diesel does not fit a petrol car; stations carry no '
              'distance, so no detour is attached');
      expect(offers.every((o) => o.station == null), isTrue);
    });

    test('no favourites → no offers', () {
      expect(container().read(nextFillOffersProvider('v1')), isEmpty);
    });
  });

  group('fuelAndTankView', () {
    test('a flex-fuel car without history: unknown mix, E85 approved', () {
      final c = container(favorites: [_station('a', e10: 1.8, e85: 1.1)]);
      final view = c.read(fuelAndTankViewProvider('v1'));
      expect(view.mix.isUnknown, isTrue);
      expect(view.compatibility.approved,
          [FuelGrade.e5, FuelGrade.e10, FuelGrade.e98, FuelGrade.e85]);
      expect(view.nextFill.offerCount, 2);
      expect(view.nextFill.decision.outcome,
          NextFillOutcome.insufficientEvidence);
      expect(view.nextFill.decision.reasons,
          contains(DecisionReason.fillVolumeUnknown));
    });

    test('a car with no configured fuel: compatibility unknown', () {
      const bare = VehicleProfile(id: 'v1', name: 'Bare', tankCapacityL: 50);
      final c = container(vehicles: const [bare]);
      final view = c.read(fuelAndTankViewProvider('v1'));
      expect(view.compatibility.isUnknown, isTrue);
      expect(view.nextFill.decision.outcome,
          NextFillOutcome.compatibilityUnknown);
      expect(view.nextFill.showsDecision, isTrue);
    });

    test('a full E10 fill makes the mix known from the real fill-up log', () {
      const e10Car = VehicleProfile(
          id: 'v1', name: 'E10', tankCapacityL: 50, preferredFuelType: 'e10');
      final c = container(vehicles: const [e10Car], fills: [
        FillUp(
          id: 'f1',
          date: DateTime.utc(2026, 9, 1),
          liters: 50,
          totalCost: 90,
          odometerKm: 1000,
          fuelType: FuelType.e10,
          vehicleId: 'v1',
        ),
      ]);
      final view = c.read(fuelAndTankViewProvider('v1'));
      expect(view.mix.shares.first.grade, FuelGrade.e10);
      expect(view.compatibility.approved, [FuelGrade.e10]);
      expect(view.compatibility.unconfirmed,
          [FuelGrade.e5, FuelGrade.e98, FuelGrade.e85]);
      expect(view.nextFill.offerCount, 0);
      expect(view.nextFill.showsDecision, isFalse);
    });
  });
}
