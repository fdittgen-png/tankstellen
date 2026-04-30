import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_xml_writer.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:xml/xml.dart';

/// Deterministic fixture used by the writer + golden + round-trip
/// tests. Hoisted to top-level so the golden generation script (if we
/// ever write one) can import the same shape.
List<VehicleProfile> _vehicles() => [
      const VehicleProfile(
        id: 'veh-1',
        name: 'Daily',
        type: VehicleType.combustion,
        tankCapacityL: 45,
        preferredFuelType: 'e10',
        engineDisplacementCc: 1200,
        engineCylinders: 4,
        volumetricEfficiency: 0.85,
        volumetricEfficiencySamples: 3,
        make: 'Peugeot',
        model: '208',
        year: 2019,
      ),
    ];

List<FillUp> _fillUps() => [
      FillUp(
        id: 'fu-1',
        date: DateTime.utc(2026, 4, 1, 8, 30),
        liters: 40,
        totalCost: 70,
        odometerKm: 12345,
        fuelType: FuelType.e10,
        stationId: 'st-A',
        stationName: 'Total',
        vehicleId: 'veh-1',
      ),
      FillUp(
        id: 'fu-2',
        date: DateTime.utc(2026, 4, 15, 17, 0),
        liters: 38.5,
        totalCost: 67.4,
        odometerKm: 12950,
        fuelType: FuelType.e10,
        stationName: 'Esso',
        vehicleId: 'veh-1',
        notes: 'Long trip',
      ),
    ];

List<TripHistoryEntry> _trips() => [
      TripHistoryEntry(
        id: 'tr-1',
        vehicleId: 'veh-1',
        summary: const TripSummary(
          distanceKm: 25.5,
          maxRpm: 3200,
          highRpmSeconds: 12,
          idleSeconds: 60,
          harshBrakes: 1,
          harshAccelerations: 0,
          avgLPer100Km: 6.2,
          fuelLitersConsumed: 1.58,
          distanceSource: 'real',
        ),
        adapterMac: 'AA:BB:CC:DD:EE:FF',
        adapterName: 'vLinker',
        samples: [
          TripSample(
            timestamp: DateTime.utc(2026, 4, 10, 8, 0, 0),
            speedKmh: 0,
            rpm: 800,
            fuelRateLPerHour: 0.6,
          ),
          TripSample(
            timestamp: DateTime.utc(2026, 4, 10, 8, 0, 1),
            speedKmh: 12,
            rpm: 1500,
            fuelRateLPerHour: 1.4,
            throttlePercent: 22,
          ),
          TripSample(
            timestamp: DateTime.utc(2026, 4, 10, 8, 0, 2),
            speedKmh: 28,
            rpm: 2100,
            fuelRateLPerHour: 2.0,
            throttlePercent: 35,
            engineLoadPercent: 48,
            coolantTempC: 76,
          ),
        ],
      ),
    ];

List<ChargingLog> _chargingLogs() => [
      ChargingLog(
        id: 'cl-1',
        vehicleId: 'veh-1',
        date: DateTime.utc(2026, 4, 5, 19, 30),
        kWh: 22.5,
        costEur: 9.0,
        chargeTimeMin: 30,
        odometerKm: 12000,
        stationName: 'Ionity Sète',
        chargingStationId: 'ocm-12345',
      ),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupXmlWriter (#1317)', () {
    test('emits the expected top-level structure', () {
      final writer = BackupXmlWriter();
      final xml = writer.build(
        vehicles: _vehicles(),
        fillUps: _fillUps(),
        trips: _trips(),
        chargingLogs: _chargingLogs(),
        appVersion: '5.0.0',
        exportedAt: DateTime.utc(2026, 4, 30, 22, 4, 0),
      );
      final doc = XmlDocument.parse(xml);
      final root = doc.rootElement;

      expect(root.name.local, 'TankstellenBackup');
      expect(root.getAttribute('version'), '1.0');
      expect(root.getAttribute('xmlns'), BackupXmlWriter.namespace);

      expect(root.findElements('ExportedAt').single.innerText,
          '2026-04-30T22:04:00.000Z');
      expect(root.findElements('AppVersion').single.innerText, '5.0.0');

      final vehicles = root.findElements('Vehicles').single;
      expect(vehicles.findElements('Vehicle').length, 1);
      expect(vehicles.findElements('Vehicle').single
          .findElements('Id').single.innerText, 'veh-1');

      final fillUps = root.findElements('FillUps').single;
      expect(fillUps.findElements('FillUp').length, 2);

      final trips = root.findElements('Trips').single;
      final trip = trips.findElements('Trip').single;
      expect(trip.findElements('Samples').single
          .findElements('Sample').length, 3);
      expect(trip.findElements('AdapterMac').single.innerText,
          'AA:BB:CC:DD:EE:FF');

      final chargingLogs = root.findElements('ChargingLogs').single;
      expect(chargingLogs.findElements('ChargingLog').length, 1);
    });

    test('omits null optional fields rather than emitting empty elements',
        () {
      final writer = BackupXmlWriter();
      // Strip every optional field so the writer must skip the
      // matching element entirely (per the schema doc).
      const stripped = VehicleProfile(
        id: 'veh-bare',
        name: 'Bare',
        type: VehicleType.ev,
      );
      final xml = writer.build(
        vehicles: [stripped],
        fillUps: const [],
        trips: const [],
        chargingLogs: const [],
        appVersion: '5.0.0',
        exportedAt: DateTime.utc(2026, 4, 30),
      );
      final doc = XmlDocument.parse(xml);
      final vehicle =
          doc.rootElement.findElements('Vehicles').single
              .findElements('Vehicle').single;

      // Required fields present.
      expect(vehicle.findElements('Id').single.innerText, 'veh-bare');
      expect(vehicle.findElements('EngineType').single.innerText, 'ev');

      // Optional fields skipped.
      expect(vehicle.findElements('TankCapacityL'), isEmpty);
      expect(vehicle.findElements('Make'), isEmpty);
      expect(vehicle.findElements('Vin'), isEmpty);
      expect(vehicle.findElements('GearCentroids'), isEmpty);
    });

    test('round-trip — parse then re-emit produces an identical document',
        () {
      final writer = BackupXmlWriter();
      final first = writer.build(
        vehicles: _vehicles(),
        fillUps: _fillUps(),
        trips: _trips(),
        chargingLogs: _chargingLogs(),
        appVersion: '5.0.0',
        exportedAt: DateTime.utc(2026, 4, 30, 22, 4, 0),
      );

      // Parse + re-serialise via the xml lib's own pretty printer:
      // a stable second pass proves the writer's output is already
      // canonicalised (no whitespace drift, no element reorder).
      final parsed = XmlDocument.parse(first);
      final second = parsed.toXmlString(pretty: true);

      expect(second, first);
    });

    test('matches the committed golden fixture byte-for-byte', () async {
      final writer = BackupXmlWriter();
      final xml = writer.build(
        vehicles: _vehicles(),
        fillUps: _fillUps(),
        trips: _trips(),
        chargingLogs: _chargingLogs(),
        appVersion: '5.0.0',
        exportedAt: DateTime.utc(2026, 4, 30, 22, 4, 0),
      );

      final goldenFile = File(
        'test/features/consumption/data/exporters/backup/'
        'fixtures/sample_backup_v1.xml',
      );
      // Allow regenerating the golden by running the test with
      // `UPDATE_GOLDENS=1` in the environment — mirrors the pattern used
      // by other golden tests in this repo and keeps schema changes
      // a single env var away.
      if (Platform.environment['UPDATE_GOLDENS'] == '1') {
        goldenFile.parent.createSync(recursive: true);
        goldenFile.writeAsStringSync(xml);
      }
      expect(goldenFile.existsSync(), isTrue,
          reason: 'Run with UPDATE_GOLDENS=1 to regenerate the fixture.');
      final golden = goldenFile.readAsStringSync();
      expect(xml, golden);
    });
  });
}
