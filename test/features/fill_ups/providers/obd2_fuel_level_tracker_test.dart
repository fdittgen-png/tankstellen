// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/data/obd2_fuel_level_snapshot_store.dart';
import 'package:tankstellen/features/fill_ups/providers/obd2_fuel_level_tracker.dart';
import 'package:tankstellen/features/obd2/providers/current_obd2_fuel_level_provider.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// [Obd2FuelLevelTracker] (#3647): persists the live OBD2 tank reading
/// per vehicle, debounced by [Obd2FuelLevelTracker.minDeltaLiters].
class _StubActiveVehicle extends ActiveVehicleProfile {
  _StubActiveVehicle(this._value);
  final VehicleProfile? _value;

  @override
  VehicleProfile? build() => _value;
}

class _RecordingStore implements Obd2FuelLevelSnapshotStore {
  final writes = <(String, Obd2FuelLevelSnapshot)>[];

  @override
  Obd2FuelLevelSnapshot? read(String vehicleId) => null;

  @override
  Future<void> write(String vehicleId, Obd2FuelLevelSnapshot snapshot) async {
    writes.add((vehicleId, snapshot));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _vehicle = VehicleProfile(
  id: 'v1',
  name: 'Car',
  type: VehicleType.combustion,
  tankCapacityL: 50,
);

void main() {
  ({ProviderContainer container, _RecordingStore store, _LiveLevel live})
      harness({VehicleProfile? active = _vehicle}) {
    final store = _RecordingStore();
    final live = _LiveLevel();
    final container = ProviderContainer(
      overrides: [
        activeVehicleProfileProvider.overrideWith(
          () => _StubActiveVehicle(active),
        ),
        currentObd2FuelLevelLitresProvider.overrideWith(
          (ref) => ref.watch(_liveLevelProvider),
        ),
        _liveLevelProvider.overrideWith(() => live),
        obd2FuelLevelSnapshotStoreProvider.overrideWith((ref) => store),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, store: store, live: live);
  }

  test('a live reading is persisted for the active vehicle with the '
      'injected clock', () async {
    final h = harness();
    final sub = h.container.listen(obd2FuelLevelTrackerProvider, (_, _) {});
    addTearDown(sub.close);
    h.container.read(obd2FuelLevelTrackerProvider.notifier).now =
        () => DateTime(2026, 8, 1, 20, 6);

    h.live.set(31.5);
    await h.container.pump();

    expect(h.store.writes, hasLength(1));
    final (vehicleId, snap) = h.store.writes.single;
    expect(vehicleId, 'v1');
    expect(snap.liters, 31.5);
    expect(snap.at, DateTime(2026, 8, 1, 20, 6));
  });

  test('sub-threshold changes are debounced; a real change writes again',
      () async {
    final h = harness();
    final sub = h.container.listen(obd2FuelLevelTrackerProvider, (_, _) {});
    addTearDown(sub.close);

    h.live.set(31.5);
    await h.container.pump();
    h.live.set(31.6); // Δ 0.1 < 0.25 — one 0x2F step of noise
    await h.container.pump();
    expect(h.store.writes, hasLength(1));

    h.live.set(30.9); // Δ 0.6 vs last WRITTEN (31.5) — persists
    await h.container.pump();
    expect(h.store.writes, hasLength(2));
    expect(h.store.writes.last.$2.liters, 30.9);
  });

  test('no live reading → nothing written', () async {
    final h = harness();
    final sub = h.container.listen(obd2FuelLevelTrackerProvider, (_, _) {});
    addTearDown(sub.close);
    await h.container.pump();
    expect(h.store.writes, isEmpty);
  });

  test('no active vehicle → nothing written', () async {
    final h = harness(active: null);
    final sub = h.container.listen(obd2FuelLevelTrackerProvider, (_, _) {});
    addTearDown(sub.close);
    h.live.set(31.5);
    await h.container.pump();
    expect(h.store.writes, isEmpty);
  });
}

/// Tiny mutable live-level source the harness drives.
class _LiveLevel extends _$LiveLevelBase {
  double? _value;
  void set(double? v) {
    _value = v;
    ref.invalidateSelf();
  }

  @override
  double? build() => _value;
}

// Hand-rolled notifier plumbing (no codegen in test files): a minimal
// NotifierProvider standing in for the live fuel-level source.
final _liveLevelProvider = NotifierProvider<_LiveLevel, double?>(_LiveLevel.new);

// ignore: unused_element — naming shim so _LiveLevel reads like a notifier.
abstract class _$LiveLevelBase extends Notifier<double?> {}
