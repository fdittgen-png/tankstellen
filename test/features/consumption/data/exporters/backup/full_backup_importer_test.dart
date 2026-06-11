// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_xml_reader.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_xml_writer.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_zip_reader.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_zipper.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/full_backup_importer.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';

/// In-memory stand-in for the four repositories, with upsert-by-id and
/// wipe semantics matching the production stores.
class _FakeStore {
  final Map<String, VehicleProfile> vehicles = {};
  final Map<String, FillUp> fillUps = {};
  final Map<String, TripHistoryEntry> trips = {};
  final Map<String, ChargingLog> logs = {};

  BackupImportSinks get sinks => BackupImportSinks(
        saveVehicle: (v) async => vehicles[v.id] = v,
        clearVehicles: () async => vehicles.clear(),
        saveFillUp: (f) async => fillUps[f.id] = f,
        clearFillUps: () async => fillUps.clear(),
        saveTrip: (t) async => trips[t.id] = t,
        clearTrips: () async => trips.clear(),
        saveChargingLog: (c) async => logs[c.id] = c,
        clearChargingLogs: () async => logs.clear(),
      );
}

VehicleProfile _vehicle(String id) =>
    VehicleProfile(id: id, name: 'V-$id', type: VehicleType.combustion);

FillUp _fillUp(String id) => FillUp(
      id: id,
      date: DateTime.utc(2026, 4, 1),
      liters: 30,
      totalCost: 50,
      odometerKm: 1000,
      fuelType: FuelType.e10,
    );

TripHistoryEntry _trip(String id) => TripHistoryEntry(
      id: id,
      vehicleId: 'v1',
      summary: const TripSummary(
        distanceKm: 10,
        maxRpm: 2500,
        highRpmSeconds: 0,
        idleSeconds: 5,
        harshBrakes: 0,
        harshAccelerations: 0,
      ),
      samples: const [],
    );

ChargingLog _log(String id) => ChargingLog(
      id: id,
      vehicleId: 'v1',
      date: DateTime.utc(2026, 4, 5),
      kWh: 20,
      costEur: 8,
      chargeTimeMin: 30,
      odometerKm: 12000,
    );

/// Build a real backup zip from the supplied snapshots (mirrors the
/// production export path: writer → zipper).
Uint8List _backupBytes({
  List<VehicleProfile> vehicles = const [],
  List<FillUp> fillUps = const [],
  List<TripHistoryEntry> trips = const [],
  List<ChargingLog> logs = const [],
}) {
  final xml = BackupXmlWriter().build(
    vehicles: vehicles,
    fillUps: fillUps,
    trips: trips,
    chargingLogs: logs,
    appVersion: '5.0.0',
    exportedAt: DateTime.utc(2026, 4, 30),
  );
  return const BackupZipper().zip(xml, now: DateTime.utc(2026, 4, 30));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FullBackupImporter (#2571)', () {
    final importer = FullBackupImporter();

    test('full export → import round trip restores every entity', () async {
      final bytes = _backupBytes(
        vehicles: [_vehicle('v1')],
        fillUps: [_fillUp('f1'), _fillUp('f2')],
        trips: [_trip('t1')],
        logs: [_log('c1')],
      );
      final store = _FakeStore();
      final result = await importer.import(
        bytes: bytes,
        sinks: store.sinks,
        mode: BackupImportMode.merge,
      );

      expect(result.total, 5);
      expect(result.vehicles, 1);
      expect(result.fillUps, 2);
      expect(result.trips, 1);
      expect(result.chargingLogs, 1);
      expect(store.vehicles.keys, ['v1']);
      expect(store.fillUps.keys, containsAll(['f1', 'f2']));
      expect(store.trips.keys, ['t1']);
      expect(store.logs.keys, ['c1']);
    });

    test('merge keeps existing records the backup does not mention',
        () async {
      final store = _FakeStore()
        ..vehicles['existing'] = _vehicle('existing')
        ..fillUps['keep'] = _fillUp('keep');
      final bytes = _backupBytes(
        vehicles: [_vehicle('v1')],
        fillUps: [_fillUp('f1')],
      );

      await importer.import(
        bytes: bytes,
        sinks: store.sinks,
        mode: BackupImportMode.merge,
      );

      // Local-only ids survive; backup ids are added.
      expect(store.vehicles.keys, containsAll(['existing', 'v1']));
      expect(store.fillUps.keys, containsAll(['keep', 'f1']));
    });

    test('merge updates a record that shares an id with the backup',
        () async {
      final store = _FakeStore()
        ..vehicles['v1'] = _vehicle('v1'); // name "V-v1"
      const renamed =
          VehicleProfile(id: 'v1', name: 'Restored', type: VehicleType.ev);
      final bytes = _backupBytes(vehicles: [renamed]);

      await importer.import(
        bytes: bytes,
        sinks: store.sinks,
        mode: BackupImportMode.merge,
      );

      expect(store.vehicles, hasLength(1));
      expect(store.vehicles['v1']!.name, 'Restored');
      expect(store.vehicles['v1']!.type, VehicleType.ev);
    });

    test('replace wipes local-only records before restoring', () async {
      final store = _FakeStore()
        ..vehicles['existing'] = _vehicle('existing')
        ..fillUps['gone'] = _fillUp('gone')
        ..trips['gone-t'] = _trip('gone-t')
        ..logs['gone-c'] = _log('gone-c');
      final bytes = _backupBytes(
        vehicles: [_vehicle('v1')],
        fillUps: [_fillUp('f1')],
      );

      final result = await importer.import(
        bytes: bytes,
        sinks: store.sinks,
        mode: BackupImportMode.replace,
      );

      expect(result.mode, BackupImportMode.replace);
      // Only the backup's records remain.
      expect(store.vehicles.keys, ['v1']);
      expect(store.fillUps.keys, ['f1']);
      expect(store.trips, isEmpty);
      expect(store.logs, isEmpty);
    });

    test('an empty-but-valid backup imports as a zero-count success',
        () async {
      final bytes = _backupBytes();
      final store = _FakeStore()..vehicles['keep'] = _vehicle('keep');

      final result = await importer.import(
        bytes: bytes,
        sinks: store.sinks,
        mode: BackupImportMode.merge,
      );

      expect(result.total, 0);
      // Merge of an empty backup must NOT touch existing data.
      expect(store.vehicles.keys, ['keep']);
    });

    test('replace of an empty backup wipes everything (explicit choice)',
        () async {
      final bytes = _backupBytes();
      final store = _FakeStore()..vehicles['keep'] = _vehicle('keep');

      await importer.import(
        bytes: bytes,
        sinks: store.sinks,
        mode: BackupImportMode.replace,
      );

      expect(store.vehicles, isEmpty);
    });

    test('propagates BackupZipReadException on a corrupt file', () async {
      final store = _FakeStore();
      expect(
        () => importer.import(
          bytes: Uint8List.fromList([1, 2, 3, 4]),
          sinks: store.sinks,
          mode: BackupImportMode.merge,
        ),
        throwsA(isA<BackupZipReadException>()),
      );
    });

    test('propagates BackupXmlReadException on an unsupported version',
        () async {
      const futureXml = '<?xml version="1.0"?>'
          '<TankstellenBackup version="2.0"/>';
      final bytes =
          const BackupZipper().zip(futureXml, now: DateTime.utc(2026, 4, 30));
      final store = _FakeStore();
      expect(
        () => importer.import(
          bytes: bytes,
          sinks: store.sinks,
          mode: BackupImportMode.merge,
        ),
        throwsA(isA<BackupXmlReadException>()),
      );
    });

    test('a corrupt replace import never wipes before parse fails',
        () async {
      // Replace clears the stores up front — but only AFTER the parse
      // succeeds. A corrupt file must throw during parse, leaving live
      // data untouched.
      final store = _FakeStore()..vehicles['keep'] = _vehicle('keep');
      await expectLater(
        importer.import(
          bytes: Uint8List.fromList([9, 9, 9]),
          sinks: store.sinks,
          mode: BackupImportMode.replace,
        ),
        throwsA(isA<BackupZipReadException>()),
      );
      expect(store.vehicles.keys, ['keep']);
    });
  });
}
