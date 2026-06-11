// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_xml_reader.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_xml_writer.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_zip_reader.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_zipper.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/full_backup_exporter.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/full_backup_importer.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/correction_fill_up.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import '../../../../../helpers/silence_error_logger.dart';

/// Reproduces the real friend's backup correction-leak (#2834): the
/// OBD2 reconciliation record `Id correction_<realId>` (unrounded
/// litres, TotalCost 0, IsFullTank false) leaking in as a real fill-up
/// in the FillUps list AND the backup export. Drives the REAL exporter +
/// REAL importer — RED on master, GREEN after the fix.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  // The real backup's real plein.
  final realFillUp = FillUp(
    id: '1779371655207902',
    vehicleId: 'skoda',
    // Microsecond precision (.389565) — the real twin truncated this to
    // millisecond (.389) in its correction date.
    date: DateTime.utc(2026, 5, 22, 9, 14, 15, 389, 565),
    liters: 49.64,
    totalCost: 97,
    odometerKm: 84210,
    fuelType: FuelType.diesel,
    isFullTank: true,
  );

  // The leaked correction twin. Its `isCorrection` flag is LOST across a
  // v1 backup round-trip, so the only durable signal is the id prefix —
  // exactly the friend's record shape.
  final correctionTwin = FillUp(
    id: 'correction_1779371655207902',
    vehicleId: 'skoda',
    date: DateTime.utc(2026, 5, 22, 9, 14, 15, 389),
    liters: 40.68327221464706,
    totalCost: 0,
    odometerKm: 84000,
    fuelType: FuelType.diesel,
    isFullTank: false,
    isCorrection: true,
  );

  group('correction-record predicate (#2834)', () {
    test('matches by id prefix even when the flag was dropped', () {
      // Simulate the post-backup-round-trip shape: flag gone, prefix kept.
      final restored = correctionTwin.copyWith(isCorrection: false);
      expect(restored.isCorrection, isFalse);
      expect(isReconciliationCorrection(restored), isTrue,
          reason: 'the durable correction_ id prefix must still match');
      expect(isReconciliationCorrection(realFillUp), isFalse);
    });
  });

  group('backup EXPORT excludes corrections (#2834)', () {
    test('a correction record never reaches the exported XML', () async {
      final exporter = FullBackupExporter();
      final tmp = Directory.systemTemp.createTempSync('corr_export_');
      debugBackupTempDirectoryOverride = () async => tmp;
      debugBackupClockOverride = () => DateTime.utc(2026, 6, 1);
      addTearDown(() {
        debugBackupTempDirectoryOverride = null;
        debugBackupClockOverride = null;
        tmp.deleteSync(recursive: true);
      });

      final result = await exporter.export(
        vehicles: const [],
        fillUps: [realFillUp, correctionTwin],
        trips: const [],
        chargingLogs: const [],
      );

      final bytes = File(result.filePath).readAsBytesSync();
      final xml = const BackupZipReader().readXml(Uint8List.fromList(bytes));
      final payload = const BackupXmlReader().read(xml);

      expect(payload.fillUps.map((f) => f.id), ['1779371655207902'],
          reason: 'the correction_ record must be excluded from the export');
    });
  });

  group('backup IMPORT excludes corrections (#2834)', () {
    final importer = FullBackupImporter();

    test('a backup carrying a correction restores only the real fill-up',
        () async {
      // Build the backup with BOTH records present (the friend's file).
      final bytes = _backupBytes(fillUps: [realFillUp, correctionTwin]);
      final store = _FakeStore();
      final result = await importer.import(
        bytes: bytes,
        sinks: store.sinks,
        mode: BackupImportMode.merge,
      );

      expect(result.fillUps, 1,
          reason: 'the imported count must reflect the real fill-up only');
      expect(store.fillUps.keys, ['1779371655207902']);
      expect(store.fillUps.containsKey('correction_1779371655207902'), isFalse);
    });
  });
}

/// Build a real backup zip from the supplied fill-ups (writer → zipper),
/// matching the production export path.
Uint8List _backupBytes({List<FillUp> fillUps = const []}) {
  final xml = BackupXmlWriter().build(
    vehicles: const <VehicleProfile>[],
    fillUps: fillUps,
    trips: const <TripHistoryEntry>[],
    chargingLogs: const <ChargingLog>[],
    appVersion: '5.0.0',
    exportedAt: DateTime.utc(2026, 4, 30),
  );
  return const BackupZipper().zip(xml, now: DateTime.utc(2026, 4, 30));
}

/// In-memory stand-in for the four import sinks (upsert-by-id).
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
