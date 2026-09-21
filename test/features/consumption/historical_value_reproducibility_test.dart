// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_estimate.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/fill_ups/data/exporters/backup/backup_xml_reader.dart';
import 'package:tankstellen/features/fill_ups/data/exporters/backup/backup_xml_writer.dart';
import 'package:tankstellen/features/trips/data/trip_history_entry.dart';
import 'package:tankstellen/features/trips/domain/trip_summary.dart';
import 'package:tankstellen/features/trips/data/trip_summary_codec.dart';
import 'package:tankstellen/features/trips/domain/fuzzy_consumption/production_fuzzy_engine.dart';
import 'package:tankstellen/features/trips/domain/trip_consumption_estimate.dart';

/// #4234 acceptance box 2 — *"historical persisted values remain
/// reproducible through version metadata"*.
///
/// Retiring a production path is only safe if a figure an **older build**
/// wrote can still be read back as the number that build produced, and
/// still be told apart from one today's build would produce. Two things
/// have to hold, and this file pins both against literal persisted rows —
/// not against objects a current encoder happened to make:
///
///  1. **A stamped row keeps its own provenance.** An older
///     `ConsumptionModelVersion` survives decode exactly, orders as older
///     than the shipping engine's, and the figure the consumer contract
///     resolves is the one the row stores.
///  2. **An unstamped legacy row is unknown-version, never re-read as
///     current.** Inventing `model: 1` for a pre-#4233 trip would claim a
///     provenance the row does not have, and would make a legacy figure
///     indistinguishable from a fuzzy-era one — exactly the distinction
///     #4234's retirement decision rests on (ADR 0022 §4, ADR 0024 §6).
///
/// The third guarantee ADR 0027 records — **a pre-migration backup must
/// still restore** — is pinned at the bottom against XML with no
/// `CalibrationMode` element at all.
///
/// #4330 then closed the loss the ADR recorded as a must-fix: the backup
/// XML now carries `pg` / `pgk` / `dfs` / `cmv`. `backup_xml_trip_
/// provenance_test.dart` pins those fields; the group here pins what
/// #4234 needs on top of them — that a **restored** trip resolves to the
/// same `ConsumptionEstimate`, figure and version alike, and that a
/// pre-#4330 backup still restores as unknown-version rather than
/// acquiring one.
void main() {
  /// A trip row exactly as an older build persisted it: pre-#4233 keys
  /// only, with the fuzzy stamp added or left out per case. Written as a
  /// literal so a future encoder change cannot quietly redefine "what an
  /// old row looked like".
  Map<String, dynamic> legacyRow({Map<String, Object?>? cmv}) => {
        'distanceKm': 120.0,
        'maxRpm': 3200.0,
        'highRpmSeconds': 30.0,
        'idleSeconds': 90.0,
        'harshBrakes': 1,
        'harshAccelerations': 2,
        'avgLPer100Km': 7.0,
        'fuelLitersConsumed': 8.4,
        'startedAt': '2025-04-11T06:15:00.000Z',
        'endedAt': '2025-04-11T08:15:00.000Z',
        'dfs': 'maf',
        'pg': 1.0,
        'cmv': ?cmv,
      };

  /// The vehicle whose gain has since moved 1.0 → 1.1, so a re-expressed
  /// figure is distinguishable from the stored one.
  const movedGain = VehicleProfile(
      id: 'car', name: 'Audit', pumpGain: 1.1, pumpGainSamples: 4);

  /// The same vehicle before the fill that moved the gain.
  const originalGain = VehicleProfile(
      id: 'car', name: 'Audit', pumpGain: 1.0, pumpGainSamples: 1);

  group('#4234 · a stamped historical row stays reproducible', () {
    const old = ConsumptionModelVersion(model: 1, rules: 1, calibration: 3);

    test('the stamp survives decode exactly', () {
      final s = tripSummaryFromJson(
          legacyRow(cmv: {'model': 1, 'rules': 1, 'calibration': 3}));
      expect(s.consumptionVersion, old);
    });

    test('the stamp survives a full encode → decode round trip', () {
      final s = tripSummaryFromJson(
          legacyRow(cmv: {'model': 1, 'rules': 1, 'calibration': 3}));
      expect(tripSummaryFromJson(tripSummaryToJson(s)).consumptionVersion,
          old);
    });

    test('at the gain it was recorded with, the figure is the stored one',
        () {
      final s = tripSummaryFromJson(
          legacyRow(cmv: {'model': 1, 'rules': 1, 'calibration': 3}));
      final e = tripConsumptionEstimate(s, originalGain);
      expect(e.litresPer100Km.valueOrNull, 7.0);
      expect(e.sourceClass, ConsumptionSourceClass.estimated);
      // Not re-expressed, so the row's own generation is what is reported.
      expect(e.version, old);
    });

    test('re-expressed at today\'s gain, the MODEL and RULES stay the '
        'old ones', () {
      final s = tripSummaryFromJson(
          legacyRow(cmv: {'model': 1, 'rules': 1, 'calibration': 3}));
      final e = tripConsumptionEstimate(s, movedGain);
      expect(e.litresPer100Km.valueOrNull, closeTo(7.7, 1e-9));
      // The figure now carries today's calibration generation, but the
      // model/rules that produced it are still the old build's — which is
      // what makes the original 7.0 recomputable.
      expect(e.version!.model, 1);
      expect(e.version!.rules, 1);
      expect(e.version!.calibration, 4);
      // And the stored row is untouched: 7.0 / generation 3 are still
      // there to recompute from.
      expect(s.avgLPer100Km, 7.0);
      expect(s.consumptionVersion, old);
    });

    test('an older stamp orders as older than the shipping engine', () {
      const ancient = ConsumptionModelVersion(model: 1, rules: 1);
      const shipped = ConsumptionModelVersion(model: 1, rules: 9);
      expect(ancient.isOlderThan(shipped), isTrue);
      expect(shipped.isOlderThan(ancient), isFalse);
      // The calibration generation is per vehicle and says nothing about
      // which build made the figure, so it is not part of the ordering.
      expect(
          const ConsumptionModelVersion(model: 1, rules: 1, calibration: 99)
              .isOlderThan(
                  const ConsumptionModelVersion(model: 1, rules: 1)),
          isFalse);
      // A row stamped by the build that shipped today's engine is not
      // older than it — the comparison is live, not hard-coded.
      expect(kProductionFuzzyEngine.version
          .isOlderThan(kProductionFuzzyEngine.version), isFalse);
    });
  });

  group('#4234 · an unstamped legacy row is unknown-version', () {
    test('no cmv key decodes to null, never to model 1', () {
      final s = tripSummaryFromJson(legacyRow());
      expect(s.consumptionVersion, isNull);
      expect(s.consumptionVersion, isNot(const ConsumptionModelVersion(
          model: 1, rules: 1)));
    });

    test('the canonical estimate reports the absence rather than '
        'today\'s version', () {
      final s = tripSummaryFromJson(legacyRow());
      final e = tripConsumptionEstimate(s, movedGain);
      // The figure is still produced and still re-expressed …
      expect(e.litresPer100Km.valueOrNull, closeTo(7.7, 1e-9));
      // … but nothing claims to know which model made it.
      expect(e.version, isNull);
      expect(e.version, isNot(kProductionFuzzyEngine.version));
    });

    test('an unstamped row round-trips without acquiring a stamp', () {
      final s = tripSummaryFromJson(legacyRow());
      final encoded = tripSummaryToJson(s);
      expect(encoded.containsKey('cmv'), isFalse,
          reason: 'a re-encoded legacy row must not gain provenance it '
              'never had');
      expect(tripSummaryFromJson(encoded).consumptionVersion, isNull);
    });

    test('a malformed stamp is unknown, not silently repaired', () {
      for (final bad in <Object?>[
        'm1r1',
        42,
        <String, Object?>{'model': 1},
        <String, Object?>{'rules': 1},
        <String, Object?>{'model': 0, 'rules': 1},
        <String, Object?>{'model': 1, 'rules': 0},
        <String, Object?>{'model': '1', 'rules': '1'},
      ]) {
        final row = legacyRow()..['cmv'] = bad;
        expect(tripSummaryFromJson(row).consumptionVersion, isNull,
            reason: 'cmv $bad must decode to unknown-version');
      }
    });

    test('a non-integer calibration is dropped, the version is kept', () {
      final s = tripSummaryFromJson(legacyRow(
          cmv: {'model': 1, 'rules': 1, 'calibration': 'lots'}));
      expect(s.consumptionVersion,
          const ConsumptionModelVersion(model: 1, rules: 1));
      expect(s.consumptionVersion!.calibration, isNull);
    });
  });

  group('#4234 · a figure survives a backup round trip (#4330)', () {
    TripHistoryEntry entry(TripSummary summary) =>
        TripHistoryEntry(id: 'trip-1', vehicleId: 'car', summary: summary);

    String write(TripSummary summary) => BackupXmlWriter().build(
          vehicles: const [],
          fillUps: const [],
          trips: [entry(summary)],
          chargingLogs: const [],
          appVersion: '1.0.0',
          exportedAt: DateTime.utc(2026, 9, 20),
        );

    TripSummary restore(TripSummary summary) =>
        const BackupXmlReader().read(write(summary)).trips.single.summary;

    test('a stamped estimated trip resolves identically after restore', () {
      final before = tripSummaryFromJson(
          legacyRow(cmv: {'model': 1, 'rules': 1, 'calibration': 3}));
      final after = restore(before);

      final e0 = tripConsumptionEstimate(before, movedGain);
      final e1 = tripConsumptionEstimate(after, movedGain);
      expect(e1.litresPer100Km.valueOrNull, e0.litresPer100Km.valueOrNull);
      expect(e1.sourceClass, e0.sourceClass);
      expect(e1.pumpGain, e0.pumpGain);
      expect(e1.version, e0.version);
      // And specifically: the stamp itself made the trip, not a
      // coincidence of the remaining fields.
      expect(after.consumptionVersion,
          const ConsumptionModelVersion(model: 1, rules: 1, calibration: 3));
      expect(after.pumpGainApplied, 1.0);
      expect(after.dominantFuelSource, 'maf');
    });

    test('a pre-#4330 backup carries no provenance and restores as '
        'unknown-version', () {
      final before = tripSummaryFromJson(legacyRow());
      final xml = write(before);
      // The writer omits every provenance element when its field is
      // null, so this document is byte-shaped like a pre-#4330 backup.
      expect(xml.contains('ConsumptionVersion'), isFalse);
      final after = const BackupXmlReader().read(xml).trips.single.summary;
      expect(after.consumptionVersion, isNull);
      expect(tripConsumptionEstimate(after, movedGain).version, isNull);
    });
  });

  group('#4234 · the backup reader keeps accepting old backups', () {
    /// A vehicle element as a pre-`CalibrationMode` backup wrote it.
    String backup(String vehicleBody) => '''
<?xml version="1.0" encoding="UTF-8"?>
<TankstellenBackup version="1.0">
  <Vehicles>
    <Vehicle>
      <Id>car</Id>
      <Name>Old Car</Name>
      $vehicleBody
    </Vehicle>
  </Vehicles>
</TankstellenBackup>
''';

    List<VehicleProfile> read(String xml) =>
        const BackupXmlReader().read(xml).vehicles;

    test('a backup with no CalibrationMode element still restores', () {
      final vehicles = read(backup(''));
      expect(vehicles, hasLength(1));
      expect(vehicles.single.id, 'car');
      // Absent → the documented default, not a parse failure and not a
      // dropped vehicle. Restoring a pre-migration backup is not optional
      // (ADR 0027).
      expect(vehicles.single.calibrationMode, VehicleCalibrationMode.rule);
    });

    test('a backup that DOES carry the legacy setting keeps its value', () {
      final vehicles = read(backup('<CalibrationMode>fuzzy</CalibrationMode>'));
      expect(vehicles.single.calibrationMode, VehicleCalibrationMode.fuzzy);
    });

    test('an unrecognised mode falls back rather than throwing', () {
      final vehicles =
          read(backup('<CalibrationMode>quantum</CalibrationMode>'));
      expect(vehicles.single.calibrationMode, VehicleCalibrationMode.rule);
    });
  });
}
