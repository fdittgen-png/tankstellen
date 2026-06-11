// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_xml_writer.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_zipper.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/full_backup_importer.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import '../../../helpers/silence_error_logger.dart';

/// Reproduces the real friend's backup ghost-trip pair (#2833): a
/// 0-sample summary-only record persisted ~1 s before its full-sample
/// twin, with a byte-identical summary (idle seconds match to 15
/// decimals). Drives the REAL repository + REAL backup import path —
/// not a fake — and asserts the ghost is de-duped (RED on master,
/// GREEN after the fix).
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  // The exact idle-seconds value from the real backup pair — full
  // double precision so the "match to 15 decimals" twin detection is
  // genuinely exercised, not a rounded stand-in.
  const realIdleSeconds = 73.39999999999961;

  TripSummary realSummary(DateTime startedAt) => TripSummary(
        distanceKm: 18.42731,
        maxRpm: 3120,
        highRpmSeconds: 41.5,
        idleSeconds: realIdleSeconds,
        harshBrakes: 2,
        harshAccelerations: 1,
        avgLPer100Km: 5.8,
        fuelLitersConsumed: 1.0688,
        startedAt: startedAt,
        endedAt: startedAt.add(const Duration(minutes: 24)),
      );

  /// The real backup's pair: ghost at 18:16:32.4, full twin at 18:16:33.4.
  final ghostStart = DateTime.utc(2026, 3, 11, 18, 16, 32, 400);
  final fullStart = DateTime.utc(2026, 3, 11, 18, 16, 33, 400);

  TripHistoryEntry ghostTwin() => TripHistoryEntry(
        id: ghostStart.toIso8601String(),
        vehicleId: 'skoda',
        summary: realSummary(ghostStart),
        samples: const [], // 0-sample ghost
      );

  TripHistoryEntry fullTwin() => TripHistoryEntry(
        id: fullStart.toIso8601String(),
        vehicleId: 'skoda',
        summary: realSummary(fullStart),
        samples: [
          TripSample(timestamp: fullStart, speedKmh: 0, rpm: 800),
          TripSample(
            timestamp: fullStart.add(const Duration(seconds: 5)),
            speedKmh: 42,
            rpm: 1900,
          ),
        ],
      );

  group('ghost-trip de-dupe — real repository (#2833)', () {
    late Directory tmpDir;
    late Box<String> box;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('ghost_trip_test_');
      Hive.init(tmpDir.path);
      box = await Hive.openBox<String>(
        'gt_${DateTime.now().microsecondsSinceEpoch}',
      );
    });

    tearDown(() async {
      await box.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    test('loadAll drops the 0-sample ghost, keeps the sampled twin',
        () async {
      final repo = TripHistoryRepository(box: box);
      // Persist BOTH twins directly to the box (simulating the legacy
      // double-save that already happened on the friend's device).
      await box.put(ghostTwin().id, _encode(ghostTwin()));
      await box.put(fullTwin().id, _encode(fullTwin()));

      final loaded = repo.loadAll();
      expect(loaded, hasLength(1),
          reason: 'the 0-sample ghost must be de-duped out');
      expect(loaded.single.samples, isNotEmpty,
          reason: 'the surviving record is the sampled twin');
      expect(loaded.single.summary.idleSeconds, realIdleSeconds);
    });

    test('finalize double-save guard: a 0-sample twin is not persisted '
        'after the sampled one', () async {
      final repo = TripHistoryRepository(box: box);
      await repo.save(fullTwin());
      await repo.save(ghostTwin()); // the ghost save must be a no-op
      expect(repo.loadAll(), hasLength(1));
      expect(repo.loadAll().single.samples, isNotEmpty);
    });

    test('finalize double-save guard: a sampled twin REPLACES a '
        'pre-existing 0-sample ghost', () async {
      final repo = TripHistoryRepository(box: box);
      await repo.save(ghostTwin()); // ghost lands first (the real bug order)
      await repo.save(fullTwin());
      final loaded = repo.loadAll();
      expect(loaded, hasLength(1));
      expect(loaded.single.samples, isNotEmpty);
    });
  });

  group('ghost-trip de-dupe — real backup import (#2833)', () {
    final importer = FullBackupImporter();

    test('import of a backup carrying the ghost pair restores one trip',
        () async {
      final bytes = _backupBytes(trips: [ghostTwin(), fullTwin()]);
      final store = _FakeStore();
      final result = await importer.import(
        bytes: bytes,
        sinks: store.sinks,
        mode: BackupImportMode.merge,
      );

      expect(result.trips, 1,
          reason: 'the imported trip count must reflect the de-duped set');
      expect(store.trips, hasLength(1));
      expect(store.trips.values.single.samples, isNotEmpty);
    });
  });
}

/// Mirror the repository's own JSON encoding so the box holds exactly
/// what production writes (`save` does `jsonEncode(entry.toJson())`).
String _encode(TripHistoryEntry e) => jsonEncode(e.toJson());

/// Build a real backup zip from the supplied trips (writer → zipper),
/// matching the production export path.
Uint8List _backupBytes({List<TripHistoryEntry> trips = const []}) {
  final xml = BackupXmlWriter().build(
    vehicles: const <VehicleProfile>[],
    fillUps: const <FillUp>[],
    trips: trips,
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
