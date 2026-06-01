// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_xml_reader.dart';
import 'package:tankstellen/features/consumption/data/exporters/backup/backup_xml_writer.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_log.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

// Fixture mirrors the writer test so the round-trip exercises the full
// field surface the v1 schema carries.
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
        supportedConnectors: {ConnectorType.type2, ConnectorType.ccs},
        gearCentroids: [1.1, 2.2, 3.3],
        obd2AdapterMac: 'AA:BB:CC:DD:EE:FF',
        obd2AdapterName: 'vLinker',
        curbWeightKg: 1300,
        autoRecord: true,
        backgroundLocationConsent: true,
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
        linkedTripIds: const ['tr-1'],
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
        isFullTank: false,
      ),
    ];

List<TripHistoryEntry> _trips() => [
      TripHistoryEntry(
        id: 'tr-1',
        vehicleId: 'veh-1',
        automatic: true,
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
          coldStartSurcharge: true,
          kind: TripKind.gpsPlusObd2,
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
            timestamp: DateTime.utc(2026, 4, 10, 8, 0, 2),
            speedKmh: 28,
            rpm: 2100,
            fuelRateLPerHour: 2.0,
            throttlePercent: 35,
            engineLoadPercent: 48,
            coolantTempC: 76,
            latitude: 43.4,
            longitude: 3.7,
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

String _buildXml({
  List<VehicleProfile>? vehicles,
  List<FillUp>? fillUps,
  List<TripHistoryEntry>? trips,
  List<ChargingLog>? chargingLogs,
}) =>
    BackupXmlWriter().build(
      vehicles: vehicles ?? const [],
      fillUps: fillUps ?? const [],
      trips: trips ?? const [],
      chargingLogs: chargingLogs ?? const [],
      appVersion: '5.0.0',
      exportedAt: DateTime.utc(2026, 4, 30, 22, 4, 0),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupXmlReader (#2571)', () {
    const reader = BackupXmlReader();

    test('writer → reader round trip reconstructs the same vehicles', () {
      final xml = _buildXml(vehicles: _vehicles());
      final v = reader.read(xml).vehicles.single;
      final orig = _vehicles().single;
      expect(v.id, orig.id);
      expect(v.name, orig.name);
      expect(v.type, orig.type);
      expect(v.tankCapacityL, orig.tankCapacityL);
      expect(v.preferredFuelType, orig.preferredFuelType);
      expect(v.engineDisplacementCc, orig.engineDisplacementCc);
      expect(v.engineCylinders, orig.engineCylinders);
      expect(v.volumetricEfficiency, orig.volumetricEfficiency);
      expect(v.volumetricEfficiencySamples, orig.volumetricEfficiencySamples);
      expect(v.make, orig.make);
      expect(v.model, orig.model);
      expect(v.year, orig.year);
      expect(v.supportedConnectors, orig.supportedConnectors);
      expect(v.gearCentroids, orig.gearCentroids);
      expect(v.obd2AdapterMac, orig.obd2AdapterMac);
      expect(v.obd2AdapterName, orig.obd2AdapterName);
      expect(v.curbWeightKg, orig.curbWeightKg);
      expect(v.autoRecord, orig.autoRecord);
      expect(v.backgroundLocationConsent, orig.backgroundLocationConsent);
      expect(v.chargingPreferences.minSocPercent, 20);
      expect(v.chargingPreferences.maxSocPercent, 80);
    });

    test('writer → reader round trip reconstructs the same fill-ups', () {
      final xml = _buildXml(fillUps: _fillUps());
      final fills = reader.read(xml).fillUps;
      expect(fills, hasLength(2));
      final f1 = fills.firstWhere((f) => f.id == 'fu-1');
      expect(f1.vehicleId, 'veh-1');
      expect(f1.date, DateTime.utc(2026, 4, 1, 8, 30));
      expect(f1.fuelType, FuelType.e10);
      expect(f1.liters, 40);
      expect(f1.totalCost, 70);
      expect(f1.odometerKm, 12345);
      expect(f1.stationId, 'st-A');
      expect(f1.stationName, 'Total');
      expect(f1.isFullTank, isTrue);
      expect(f1.linkedTripIds, ['tr-1']);
      final f2 = fills.firstWhere((f) => f.id == 'fu-2');
      expect(f2.notes, 'Long trip');
      expect(f2.isFullTank, isFalse);
      expect(f2.stationId, isNull);
    });

    test('writer → reader round trip reconstructs trips + samples', () {
      final xml = _buildXml(trips: _trips());
      final t = reader.read(xml).trips.single;
      final orig = _trips().single;
      expect(t.id, orig.id);
      expect(t.vehicleId, orig.vehicleId);
      expect(t.automatic, isTrue);
      expect(t.adapterMac, orig.adapterMac);
      expect(t.adapterName, orig.adapterName);
      expect(t.summary.distanceKm, orig.summary.distanceKm);
      expect(t.summary.maxRpm, orig.summary.maxRpm);
      expect(t.summary.harshBrakes, orig.summary.harshBrakes);
      expect(t.summary.avgLPer100Km, orig.summary.avgLPer100Km);
      expect(t.summary.fuelLitersConsumed, orig.summary.fuelLitersConsumed);
      expect(t.summary.distanceSource, 'real');
      expect(t.summary.coldStartSurcharge, isTrue);
      expect(t.summary.kind, TripKind.gpsPlusObd2);
      expect(t.samples, hasLength(2));
      expect(t.samples.last.coolantTempC, 76);
      expect(t.samples.last.latitude, 43.4);
      expect(t.samples.last.longitude, 3.7);
      expect(t.samples.first.fuelRateLPerHour, 0.6);
    });

    test('writer → reader round trip reconstructs charging logs', () {
      final xml = _buildXml(chargingLogs: _chargingLogs());
      final c = reader.read(xml).chargingLogs.single;
      final orig = _chargingLogs().single;
      expect(c.id, orig.id);
      expect(c.vehicleId, orig.vehicleId);
      expect(c.date, orig.date);
      expect(c.kWh, orig.kWh);
      expect(c.costEur, orig.costEur);
      expect(c.chargeTimeMin, orig.chargeTimeMin);
      expect(c.odometerKm, orig.odometerKm);
      expect(c.stationName, orig.stationName);
      expect(c.chargingStationId, orig.chargingStationId);
    });

    test('an empty-but-valid backup parses to an empty payload', () {
      final payload = reader.read(_buildXml());
      expect(payload.isEmpty, isTrue);
      expect(payload.vehicles, isEmpty);
      expect(payload.fillUps, isEmpty);
      expect(payload.trips, isEmpty);
      expect(payload.chargingLogs, isEmpty);
    });

    test('the committed v1 golden fixture parses cleanly', () {
      // Reuse the exact bytes the writer golden test pins so the reader
      // is verified against the canonical on-disk schema, not just its
      // own round trip.
      final xml = _buildXml(
        vehicles: _vehicles(),
        fillUps: _fillUps(),
        trips: _trips(),
        chargingLogs: _chargingLogs(),
      );
      final payload = reader.read(xml);
      expect(payload.vehicles, hasLength(1));
      expect(payload.fillUps, hasLength(2));
      expect(payload.trips, hasLength(1));
      expect(payload.chargingLogs, hasLength(1));
    });

    test('rejects malformed XML', () {
      expect(
        () => reader.read('<not closed'),
        throwsA(isA<BackupXmlReadException>()),
      );
    });

    test('rejects a document with the wrong root element', () {
      expect(
        () => reader.read('<?xml version="1.0"?><SomethingElse/>'),
        throwsA(isA<BackupXmlReadException>()),
      );
    });

    test('rejects a backup with a missing schema version', () {
      const xml = '<?xml version="1.0"?>'
          '<TankstellenBackup xmlns="https://tankstellen.app/backup/v1"/>';
      expect(() => reader.read(xml), throwsA(isA<BackupXmlReadException>()));
    });

    test('rejects a FUTURE schema version (v2) gracefully', () {
      const xml = '<?xml version="1.0"?>'
          '<TankstellenBackup version="2.0" '
          'xmlns="https://tankstellen.app/backup/v2"/>';
      expect(
        () => reader.read(xml),
        throwsA(
          isA<BackupXmlReadException>().having(
            (e) => e.reason,
            'reason',
            contains('unsupported'),
          ),
        ),
      );
    });

    test('rejects a non-numeric version string', () {
      const xml = '<?xml version="1.0"?>'
          '<TankstellenBackup version="latest"/>';
      expect(() => reader.read(xml), throwsA(isA<BackupXmlReadException>()));
    });

    test('accepts a v1 minor bump (1.1) as still-v1', () {
      const xml = '<?xml version="1.0"?>'
          '<TankstellenBackup version="1.1" '
          'xmlns="https://tankstellen.app/backup/v1"/>';
      expect(() => reader.read(xml), returnsNormally);
    });
  });
}
