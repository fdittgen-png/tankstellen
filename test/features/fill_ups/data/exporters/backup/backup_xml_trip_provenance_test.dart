// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4330 — a trip figure's provenance (`pg`, `pgk`, `dfs`, `cmv`) survives
// a backup/restore round-trip. Before this the backup XML wrote none of
// them, so restoring a backup silently downgraded every trip: the gain
// its litres carry, the branch that produced them and the model version
// were dropped, and the trip re-classified from what was left.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_estimate.dart';
import 'package:tankstellen/features/fill_ups/data/exporters/backup/backup_xml_reader.dart';
import 'package:tankstellen/features/fill_ups/data/exporters/backup/backup_xml_writer.dart';
import 'package:tankstellen/features/trips/data/trip_history_entry.dart';
import 'package:tankstellen/features/trips/domain/trip_fuel_source.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';

final _at = DateTime.utc(2026, 9, 1, 10);

TripHistoryEntry _trip(TripSummary summary) => TripHistoryEntry(
      id: 'trip-1',
      vehicleId: 'v',
      summary: summary,
    );

TripSummary _summary({
  double? pumpGainApplied,
  String? pumpGainFuelKey,
  String? dominantFuelSource,
  ConsumptionModelVersion? consumptionVersion,
}) =>
    TripSummary(
      distanceKm: 18.2,
      maxRpm: 2800,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      avgLPer100Km: 6.4,
      fuelLitersConsumed: 1.16,
      startedAt: _at,
      endedAt: _at.add(const Duration(minutes: 43)),
      pumpGainApplied: pumpGainApplied,
      pumpGainFuelKey: pumpGainFuelKey,
      dominantFuelSource: dominantFuelSource,
      consumptionVersion: consumptionVersion,
    );

String _write(TripHistoryEntry trip) => BackupXmlWriter().build(
      vehicles: const [],
      fillUps: const [],
      trips: [trip],
      chargingLogs: const [],
      appVersion: '1.0.0',
      exportedAt: _at,
    );

TripSummary _roundTrip(TripSummary summary) =>
    const BackupXmlReader().read(_write(_trip(summary))).trips.single.summary;

void main() {
  test('every provenance field round-trips', () {
    final restored = _roundTrip(_summary(
      pumpGainApplied: 1.08,
      pumpGainFuelKey: 'e85',
      dominantFuelSource: 'maf',
      consumptionVersion:
          const ConsumptionModelVersion(model: 2, rules: 3, calibration: 4),
    ));

    expect(restored.pumpGainApplied, 1.08);
    expect(restored.pumpGainFuelKey, 'e85');
    expect(restored.dominantFuelSource, 'maf');
    expect(restored.consumptionVersion?.model, 2);
    expect(restored.consumptionVersion?.rules, 3);
    expect(restored.consumptionVersion?.calibration, 4);
    // The point of carrying `dfs`: the restored trip classifies the same.
    expect(tripFuelSourceKind(restored), TripFuelSourceKind.estimated);
  });

  test('a null calibration stays null — "not attributable" is not zero', () {
    final restored = _roundTrip(_summary(
      dominantFuelSource: kGpsPhysicsFuelSourceTag,
      consumptionVersion: const ConsumptionModelVersion(model: 1, rules: 1),
    ));
    expect(restored.consumptionVersion?.calibration, isNull);
    expect(tripFuelSourceKind(restored), TripFuelSourceKind.gps,
        reason: '#4330 F4 — the no-fuel-PID OBD2 trip keeps its class');
  });

  test('a trip without provenance writes nothing new (legacy shape)', () {
    final xml = _write(_trip(_summary()));
    expect(xml, isNot(contains('<PumpGainApplied>')));
    expect(xml, isNot(contains('<PumpGainFuelKey>')));
    expect(xml, isNot(contains('<DominantFuelSource>')));
    expect(xml, isNot(contains('<ConsumptionVersion')));
  });

  test('an old backup (no provenance elements) still restores', () {
    final xml = _write(_trip(_summary()));
    final restored = const BackupXmlReader().read(xml).trips.single.summary;
    expect(restored.avgLPer100Km, 6.4);
    expect(restored.pumpGainApplied, isNull);
    expect(restored.dominantFuelSource, isNull);
    expect(restored.consumptionVersion, isNull);
  });

  test('a malformed version element degrades to null, never throws', () {
    final xml = _write(_trip(_summary(
      consumptionVersion: const ConsumptionModelVersion(model: 1, rules: 1),
    ))).replaceFirst('model="1"', 'model="not-a-number"');
    final restored = const BackupXmlReader().read(xml).trips.single.summary;
    expect(restored.consumptionVersion, isNull,
        reason: 'a restore must not fail on metadata about the figure');
    expect(restored.avgLPer100Km, 6.4, reason: 'the figure itself survives');
  });
}
