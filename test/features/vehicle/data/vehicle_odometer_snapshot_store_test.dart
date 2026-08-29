// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3877 — the per-vehicle OBD2 odometer snapshot: round-trip, source
// tag, and the honest degradation on garbage.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/vehicle/data/vehicle_odometer_snapshot_store.dart';

class _Mem implements SettingsStorage {
  final Map<String, dynamic> m = {};
  @override
  dynamic getSetting(String key) => m[key];
  @override
  Future<void> putSetting(String key, dynamic value) async => m[key] = value;
  @override
  bool get isSetupComplete => true;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}

void main() {
  test('write then read round-trips km, instant and source', () async {
    final mem = _Mem();
    final store = VehicleOdometerSnapshotStore(mem);
    final at = DateTime(2026, 8, 29, 18, 30);
    await store.write(
        'veh-1',
        VehicleOdometerSnapshot(
            km: 123456.4, at: at, source: VehicleOdometerSource.obd2Estimate));
    final snap = store.read('veh-1');
    expect(snap, isNotNull);
    expect(snap!.km, 123456.4);
    expect(snap.at, at);
    expect(snap.source, VehicleOdometerSource.obd2Estimate);
    expect(mem.m.keys.single,
        '${StorageKeys.obd2OdometerSnapshotPrefix}veh-1');
  });

  test('per vehicle — another id reads null', () async {
    final store = VehicleOdometerSnapshotStore(_Mem());
    await store.write('a',
        VehicleOdometerSnapshot(km: 1, at: DateTime(2026), source: VehicleOdometerSource.obd2));
    expect(store.read('b'), isNull);
  });

  test('garbage or negative values read as null, never throw', () {
    final mem = _Mem()
      ..m['${StorageKeys.obd2OdometerSnapshotPrefix}x'] = 'not json'
      ..m['${StorageKeys.obd2OdometerSnapshotPrefix}y'] = '{"km":-5,"at":1}'
      ..m['${StorageKeys.obd2OdometerSnapshotPrefix}z'] = '{"km":"12","at":1}';
    final store = VehicleOdometerSnapshotStore(mem);
    expect(store.read('x'), isNull);
    expect(store.read('y'), isNull);
    expect(store.read('z'), isNull);
    expect(store.read('missing'), isNull);
  });

  test('an unknown source tag reads as a reading (forward compatible)', () {
    final mem = _Mem()
      ..m['${StorageKeys.obd2OdometerSnapshotPrefix}v'] =
          '{"km":10,"at":1000,"src":"future"}';
    expect(VehicleOdometerSnapshotStore(mem).read('v')!.source,
        VehicleOdometerSource.obd2);
  });

  test('never throws — a storage that throws on read/write is a null read '
      'and a completed write (fault injection)', () async {
    final store = VehicleOdometerSnapshotStore(_Throwing());
    expect(store.read('v'), isNull);
    await expectLater(
        store.write('v', VehicleOdometerSnapshot(
            km: 1, at: DateTime(2026), source: VehicleOdometerSource.obd2)),
        completes);
  });
}

class _Throwing implements SettingsStorage {
  @override
  dynamic getSetting(String key) => throw StateError('box closed');
  @override
  Future<void> putSetting(String key, dynamic value) async =>
      throw StateError('box closed');
  @override
  bool get isSetupComplete => true;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}
