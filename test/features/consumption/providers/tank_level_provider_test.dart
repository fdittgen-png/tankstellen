// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/consumption/data/obd2_fuel_level_snapshot_store.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/services/tank_level_estimator.dart';
import 'package:tankstellen/features/consumption/providers/consumption_providers.dart';
import 'package:tankstellen/features/consumption/providers/tank_level_provider.dart';
import 'package:tankstellen/features/obd2/providers/current_obd2_fuel_level_provider.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// Wiring tests for `tankLevelProvider` — v2 (#3647).
///
/// The pure math lives in [estimateTankLevel] and is covered by
/// `tank_level_estimator_test.dart`. These pin only what the provider
/// adds on top:
///   * unknown sentinel for unknown vehicles / no fill-ups
///   * fill-up vehicle filtering + defensive newest-first sort
///   * sensor preference: LIVE reading (active vehicle only) over the
///     persisted snapshot, persisted snapshot over nothing
///   * shell safety: an unwired live chain degrades to "no reading"
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
}

class _StubActiveVehicle extends ActiveVehicleProfile {
  _StubActiveVehicle(this._value);
  final VehicleProfile? _value;

  @override
  VehicleProfile? build() => _value;
}

/// In-memory snapshot store — no Hive, no settings box.
class _FakeSnapshotStore implements Obd2FuelLevelSnapshotStore {
  _FakeSnapshotStore([this.snapshots = const {}]);
  final Map<String, Obd2FuelLevelSnapshot> snapshots;

  @override
  Obd2FuelLevelSnapshot? read(String vehicleId) => snapshots[vehicleId];

  @override
  Future<void> write(String vehicleId, Obd2FuelLevelSnapshot snapshot) async {
    snapshots[vehicleId] = snapshot;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _vehicle = VehicleProfile(
  id: 'v1',
  name: 'Test Car',
  type: VehicleType.combustion,
  tankCapacityL: 50,
);

FillUp _fill({
  required String id,
  required DateTime date,
  double liters = 45,
  String? vehicleId = 'v1',
}) {
  return FillUp(
    id: id,
    date: date,
    liters: liters,
    totalCost: liters * 1.8,
    odometerKm: 0,
    fuelType: FuelType.diesel,
    vehicleId: vehicleId,
  );
}

ProviderContainer _container({
  List<VehicleProfile> vehicles = const [_vehicle],
  List<FillUp> fillUps = const [],
  VehicleProfile? activeVehicle,
  double? liveLitres,
  Map<String, Obd2FuelLevelSnapshot> snapshots = const {},
}) {
  final container = ProviderContainer(
    overrides: [
      vehicleProfileListProvider.overrideWith(
        () => _StubVehicleProfileList(vehicles),
      ),
      fillUpListProvider.overrideWith(() => _StubFillUpList(fillUps)),
      activeVehicleProfileProvider.overrideWith(
        () => _StubActiveVehicle(activeVehicle),
      ),
      currentObd2FuelLevelLitresProvider.overrideWith((ref) => liveLitres),
      obd2FuelLevelSnapshotStoreProvider.overrideWith(
        (ref) => _FakeSnapshotStore(Map.of(snapshots)),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('sentinels', () {
    test('unknown vehicle id → unknown', () {
      final c = _container(fillUps: [
        _fill(id: 'f1', date: DateTime(2026, 4, 1)),
      ]);
      final e = c.read(tankLevelProvider('nope'));
      expect(e.hasFillUp, isFalse);
    });

    test('vehicle without fill-ups → unknown', () {
      final c = _container();
      expect(c.read(tankLevelProvider('v1')).hasFillUp, isFalse);
    });

    test('fill-ups of OTHER vehicles are filtered out', () {
      final c = _container(fillUps: [
        _fill(id: 'f-other', date: DateTime(2026, 4, 1), vehicleId: 'v2'),
      ]);
      expect(c.read(tankLevelProvider('v1')).hasFillUp, isFalse);
    });
  });

  group('fill wiring', () {
    test('a malformed (oldest-first) list is defensively re-sorted — the '
        'NEWEST fill anchors', () {
      final c = _container(fillUps: [
        _fill(id: 'f-old', date: DateTime(2026, 3, 1)),
        _fill(id: 'f-new', date: DateTime(2026, 4, 1)),
      ]);
      final e = c.read(tankLevelProvider('v1'));
      expect(e.lastFillUpDate, DateTime(2026, 4, 1));
      expect(e.levelL, 50.0);
    });
  });

  group('sensor wiring — live > persisted > none (#3647)', () {
    final fills = [_fill(id: 'f1', date: DateTime(2026, 4, 1))];

    test('no live reading, no snapshot → fill anchor', () {
      final c = _container(fillUps: fills);
      final e = c.read(tankLevelProvider('v1'));
      expect(e.source, TankLevelSource.fillUp);
      expect(e.levelL, 50.0);
    });

    test('persisted snapshot newer than the fill grounds the level', () {
      final c = _container(
        fillUps: fills,
        snapshots: {
          'v1': Obd2FuelLevelSnapshot(
            liters: 31.5,
            at: DateTime(2026, 4, 3),
          ),
        },
      );
      final e = c.read(tankLevelProvider('v1'));
      expect(e.source, TankLevelSource.obd2Sensor);
      expect(e.levelL, 31.5);
    });

    test('LIVE reading for the ACTIVE vehicle wins over the persisted '
        'snapshot', () {
      final c = _container(
        fillUps: fills,
        activeVehicle: _vehicle,
        liveLitres: 28.0,
        snapshots: {
          'v1': Obd2FuelLevelSnapshot(
            liters: 31.5,
            at: DateTime(2026, 4, 3),
          ),
        },
      );
      final e = c.read(tankLevelProvider('v1'));
      expect(e.source, TankLevelSource.obd2Sensor);
      expect(e.levelL, 28.0);
    });

    test('a live reading is IGNORED when the queried vehicle is not the '
        'active one — the gauge belongs to the car that is driving', () {
      const otherActive = VehicleProfile(
        id: 'v2',
        name: 'Other',
        type: VehicleType.combustion,
      );
      final c = _container(
        fillUps: fills,
        activeVehicle: otherActive,
        liveLitres: 28.0,
        snapshots: {
          'v1': Obd2FuelLevelSnapshot(
            liters: 31.5,
            at: DateTime(2026, 4, 3),
          ),
        },
      );
      final e = c.read(tankLevelProvider('v1'));
      expect(e.levelL, 31.5);
    });
  });
}
