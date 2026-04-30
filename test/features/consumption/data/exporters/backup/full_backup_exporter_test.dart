import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/full_backup_exporter.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

void main() {
  group('FullBackupExporter (#1317)', () {
    late Directory tempDir;
    late List<ShareParams> captured;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('backup_exporter_test_');
      captured = <ShareParams>[];
      debugBackupTempDirectoryOverride = () async => tempDir;
      debugBackupShareSinkOverride = (params) async {
        captured.add(params);
      };
      debugBackupClockOverride = () => DateTime.utc(2026, 4, 30, 22, 4, 0);
      debugBackupAppVersionOverride = '5.0.0';
    });

    tearDown(() {
      debugBackupTempDirectoryOverride = null;
      debugBackupShareSinkOverride = null;
      debugBackupClockOverride = null;
      debugBackupAppVersionOverride = null;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('writes a non-empty .zip under the temp dir and shares it',
        () async {
      final exporter = FullBackupExporter();
      final result = await exporter.export(
        vehicles: const [
          VehicleProfile(id: 'v', name: 'V', type: VehicleType.combustion),
        ],
        fillUps: [
          FillUp(
            id: 'f',
            date: DateTime.utc(2026, 4, 1),
            liters: 30,
            totalCost: 50,
            odometerKm: 1000,
            fuelType: FuelType.e10,
          ),
        ],
        trips: const <TripHistoryEntry>[],
        chargingLogs: const <ChargingLog>[],
      );

      // File on disk under the supplied temp dir + non-empty.
      expect(result.byteSize, greaterThan(0));
      final file = File(result.filePath);
      expect(file.existsSync(), isTrue);
      expect(file.parent.path, tempDir.path);
      expect(file.path.endsWith('.zip'), isTrue);
      expect(file.path,
          contains('tankstellen_backup_20260430T220400.zip'));

      // share_plus invoked exactly once with our path.
      expect(captured, hasLength(1));
      final params = captured.single;
      expect(params.files, isNotNull);
      expect(params.files!.length, 1);
      expect(params.files!.single.path, result.filePath);
      expect(params.files!.single.mimeType, 'application/zip');
    });

    test('zip contains a single XML entry that parses as XML', () async {
      final exporter = FullBackupExporter();
      final trip = TripHistoryEntry(
        id: 't1',
        vehicleId: 'v',
        summary: const TripSummary(
          distanceKm: 10,
          maxRpm: 2500,
          highRpmSeconds: 0,
          idleSeconds: 5,
          harshBrakes: 0,
          harshAccelerations: 0,
        ),
        samples: [
          TripSample(
            timestamp: DateTime.utc(2026, 4, 10, 8),
            speedKmh: 0,
            rpm: 800,
          ),
        ],
      );
      final result = await exporter.export(
        vehicles: const [],
        fillUps: const [],
        trips: [trip],
        chargingLogs: const [],
      );

      final zipBytes = File(result.filePath).readAsBytesSync();
      final decoded = ZipDecoder().decodeBytes(zipBytes);
      expect(decoded.files.length, 1);
      final entry = decoded.files.single;
      expect(entry.name.endsWith('.xml'), isTrue);
      final xml = utf8.decode(entry.content as List<int>);
      expect(xml, startsWith('<?xml'));
      expect(xml, contains('<TankstellenBackup'));
      expect(xml, contains('<AppVersion>5.0.0</AppVersion>'));
      expect(xml, contains('<Trip>'));
    });
  });
}
